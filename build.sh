read -p "Enter the full qualified JDK version (e.g. 22.0.2+9)" JDK_FULL_VERSION

JDK_MAJOR_VERSION= ${JDK_FULL_VERSION:0:2}
PKG_NAME_AND_VERSION="openjdk-${JDK_MAJOR_VERSION}_${JDK_FULL_VERSION}"
read -p "Enter the JDK tarball URL to download" JDK_TARBALL_URL

cat << EOF
Did you updated the following files?
* openjdk-${JDK_MAJOR_VERSION}/rules,
* openjdk-${JDK_MAJOR_VERSION}/changelog,
* openjdk-${JDK_MAJOR_VERSION}/copyright,
EOF

read -p "If so, enter \"yes\"" READY_TO_BUILD
if [ "yes" != ${READY_TO_BUILD}]; then
    echo "Answer was not \"yes\". Aborting build.
    exit 1
fi
 
curl -L ${JDK_TARBALL_URL} -o ${PKG_NAME_AND_VERSION}.orig.tar.gz
mkdir ${PKG_NAME_AND_VERSION} 
tar -xzf ./${PKG_NAME_AND_VERSION}.orig.tar.gz -C ${PKG_NAME_AND_VERSION} --strip-components=1
cp -R openjdk-${JDK_MAJOR_VERSION}/debian/ ${PKG_NAME_AND_VERSION} 
cd ${PKG_NAME_AND_VERSION}
debuild -us -uc -d -b