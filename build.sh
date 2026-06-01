#!/bin/bash
set -euo pipefail

JDK_FULL_VERSION=""

usage() {
    cat << EOF
Usage: $0 [--jdk-version <version>]

Options:
  --jdk-version <version>  Full qualified JDK version, e.g. 26.0.1+8
  -h, --help              Show this help message
EOF
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

if [ -z "${JDK_FULL_VERSION}" ]; then
    read -r -p $'Enter the full qualified JDK version (e.g. 22.0.2+9)\n' JDK_FULL_VERSION
fi

if [ -z "${JDK_FULL_VERSION}" ]; then
    echo "JDK version is required. Aborting build."
    exit 1
fi

JDK_MAJOR_VERSION=${JDK_FULL_VERSION:0:2}
PKG_NAME_AND_VERSION="openjdk-${JDK_MAJOR_VERSION}_${JDK_FULL_VERSION}"
read -r -p $'Enter the JDK tarball URL to download\n' JDK_TARBALL_URL
echo "Downloading JDK source now..."
curl -L "${JDK_TARBALL_URL}" -o "${PKG_NAME_AND_VERSION}.orig.tar.gz"

cat << EOF
Did you installed the following packages?
* build-essential
* pandoc
* devscripts
* debhelper
EOF

read -r -p $'If so, enter \"yes\"\n' READY_TO_BUILD
if [ "yes" != "${READY_TO_BUILD}" ]; then
    echo "Missing packages required for building. Aborting build."
    exit 1
fi

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

rm --recursive --force "${PKG_NAME_AND_VERSION}"
mkdir "${PKG_NAME_AND_VERSION}"
tar -xzf "./${PKG_NAME_AND_VERSION}.orig.tar.gz" -C "${PKG_NAME_AND_VERSION}" --strip-components=1
cp -R "openjdk-${JDK_MAJOR_VERSION}/debian" "${PKG_NAME_AND_VERSION}"
(cd "${PKG_NAME_AND_VERSION}" && exec debuild -us -uc -d -b)
