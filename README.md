# ppa-openjdk

This is a OpenJDK build, [published in a PPA](https://launchpad.net/~coffeelibs/+archive/ubuntu/openjdk).

## Why?

Ubuntu lags behind publishing the latest JDK versions. While you would usually download the JDK yourself or use SDKMAN, but this is not an option during PPA builds, because you're not allowed to download anything.

_ppa-openjdk_ to the rescue! Other than the distro's main package sources, your build may also depend on other PPAs, such as this one.

## How to use?

Let's say you want to use JDK 19 on Ubuntu Focal:

1. add `coffeelibs-jdk-19` to your package's build dependencies
2. make your PPA depend on this one
2. during your build `export JAVA_HOME=/usr/lib/jvm/java-19-coffeelibs` \*
3. use it, e.g. by running `${JAVA_HOME}/bin/jlink`

\* Please note, that this package does not set up any paths or symlinks itself.