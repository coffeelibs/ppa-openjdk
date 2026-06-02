#!/bin/bash
set -euo pipefail

JDK_FULL_VERSION=""
NON_INTERACTIVE=false
CACHE_DIR="cache"
REQUIRED_PACKAGES=(
    build-essential
    pandoc
    devscripts
    debhelper
    dput
    make
    gcc
    g++
    libc6-dev
    file
    unzip
    zip
    autoconf
    libx11-dev
    libxext-dev
    libxrender-dev
    libxrandr-dev
    libxtst-dev
    libxt-dev
    libcups2-dev
    libfontconfig1-dev
    libasound2-dev
)

usage() {
    cat << EOF
Usage: $0 [--jdk-version <version>] [--non-interactive]

Options:
  --jdk-version <version>  Full qualified JDK version, e.g. 26.0.1+8
  --non-interactive       Skip all prompts and derive the tarball URL from the JDK version
  -h, --help              Show this help message
EOF
}

derive_jdk_tarball_url() {
    local jdk_full_version="$1"
    local jdk_major_version="${jdk_full_version%%.*}"

    if [[ "${jdk_full_version}" =~ ^${jdk_major_version}\.0\.0\+(.+)$ ]]; then
        echo "https://github.com/openjdk/jdk/archive/refs/tags/jdk-${jdk_major_version}+${BASH_REMATCH[1]}.tar.gz"
    else
        echo "https://github.com/openjdk/jdk${jdk_major_version}u/archive/refs/tags/jdk-${jdk_full_version}.tar.gz"
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --jdk-version)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                echo "Missing value for --jdk-version"
                usage
                exit 1
            fi
            JDK_FULL_VERSION="$2"
            shift 2
            ;;
        --jdk-version=*)
            JDK_FULL_VERSION="${1#--jdk-version=}"
            if [ -z "${JDK_FULL_VERSION}" ]; then
                echo "Missing value for --jdk-version"
                usage
                exit 1
            fi
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

if [ "${NON_INTERACTIVE}" = true ] && [ -z "${JDK_FULL_VERSION}" ]; then
    echo "--jdk-version is required in non-interactive mode."
    usage
    exit 1
fi

if [ "${NON_INTERACTIVE}" = false ] && [ -z "${JDK_FULL_VERSION}" ]; then
    read -r -p $'Enter the full qualified JDK version (e.g. 22.0.2+9)\n' JDK_FULL_VERSION
fi

if [ -z "${JDK_FULL_VERSION}" ]; then
    echo "JDK version is required. Aborting build."
    exit 1
fi

JDK_MAJOR_VERSION=${JDK_FULL_VERSION%%.*}
PKG_NAME_AND_VERSION="openjdk-${JDK_MAJOR_VERSION}_${JDK_FULL_VERSION}"
CACHED_TARBALL="${CACHE_DIR}/${PKG_NAME_AND_VERSION}.orig.tar.gz"
LEGACY_TARBALL="${PKG_NAME_AND_VERSION}.orig.tar.gz"
if [ "${NON_INTERACTIVE}" = true ]; then
    JDK_TARBALL_URL="$(derive_jdk_tarball_url "${JDK_FULL_VERSION}")"
else
    read -r -p $'Enter the JDK tarball URL to download\n' JDK_TARBALL_URL
fi

mkdir -p "${CACHE_DIR}"
if [ -f "${CACHED_TARBALL}" ]; then
    echo "Using cached JDK source: ${CACHED_TARBALL}"
elif [ -f "${LEGACY_TARBALL}" ]; then
    echo "Seeding JDK source cache from existing tarball: ${LEGACY_TARBALL}"
    cp "${LEGACY_TARBALL}" "${CACHED_TARBALL}"
else
    echo "Downloading JDK source now..."
    curl -L "${JDK_TARBALL_URL}" -o "${CACHED_TARBALL}.part"
    mv "${CACHED_TARBALL}.part" "${CACHED_TARBALL}"
fi

if [ "${NON_INTERACTIVE}" = false ]; then
    echo "Did you install the following packages?"
    printf '* %s\n' "${REQUIRED_PACKAGES[@]}"
    echo
    echo "Install command:"
    printf 'sudo apt-get install'
    printf ' %s' "${REQUIRED_PACKAGES[@]}"
    echo

    read -r -p $'If so, enter \"yes\"\n' READY_TO_BUILD
    if [ "yes" != "${READY_TO_BUILD}" ]; then
        echo "Missing packages required for building. Aborting build."
        exit 1
    fi
fi

if [ "${NON_INTERACTIVE}" = false ]; then
    cat << EOF
Did you updated the following files?
* openjdk-${JDK_MAJOR_VERSION}/rules,
* openjdk-${JDK_MAJOR_VERSION}/changelog,
* openjdk-${JDK_MAJOR_VERSION}/copyright,
EOF

    read -r -p $'If so, enter \"yes\"\n' READY_TO_BUILD
    if [ "yes" != "${READY_TO_BUILD}" ]; then
        echo "Answer was not \"yes\". Aborting build."
        exit 1
    fi
fi

rm --recursive --force "${PKG_NAME_AND_VERSION}"
mkdir "${PKG_NAME_AND_VERSION}"
tar -xzf "${CACHED_TARBALL}" -C "${PKG_NAME_AND_VERSION}" --strip-components=1
cp -R "openjdk-${JDK_MAJOR_VERSION}/debian" "${PKG_NAME_AND_VERSION}"
(cd "${PKG_NAME_AND_VERSION}" && exec debuild -us -uc -d -b)
