# ppa-openjdk

This is a OpenJDK build, [published in a PPA](https://launchpad.net/~coffeelibs/+archive/ubuntu/openjdk).

## Why?

~~Ubuntu lags behind publishing the latest JDK versions. While you would usually download the JDK yourself or use SDKMAN, but this is not an option during PPA builds, because you're not allowed to download anything.~~

> [!TIP]
> Canonical announced to finally publish recent JDK builds itself! :tada: See [their press announcement](https://canonical.com/blog/introducing-canonical-builds-of-openjdk). However, it seems like they will only include specific JDK releases (please send them [this video](https://inside.java/2025/07/03/newscast-94/) about "LTS" versions) in Ubuntu LTS updates.
>
> Depending on whether Ubuntu will publish future "non-LTS" JDKs, the need for this project might diminish and we will archive this repo eventually. But only time will tell.

_ppa-openjdk_ to the rescue! Other than the distro's main package sources, your build may also depend on other PPAs, such as this one.

## How to use?

Let's say you want to use JDK 19 on Ubuntu Focal:

1. add `coffeelibs-jdk-19` to your package's build dependencies
2. make your PPA depend on this one
2. during your build `export JAVA_HOME=/usr/lib/jvm/java-19-coffeelibs` \*
3. use it, e.g. by running `${JAVA_HOME}/bin/jlink`

\* Please note, that this package does not set up any paths or symlinks itself.

## Building
To locally build a JDK, use `build.sh`.
