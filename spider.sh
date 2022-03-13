#!/bin/bash
#
# Author: yonzkon <yonzkon@gmail.com>
# Maintainer: yonzkon <yonzkon@gmail.com>
#

# Caution!! Don't touch this file unless you're clear of all the conceptions.

# usage
usage()
{
    echo -e "USAGE: $0 [PREFIX] [ARCH]"
    echo -e "\tPREFIX   install prefix, [default: ./]"
    echo -e "\tARCH     arm | x86, [default: x86]"
}
[[ "$*" =~ "help" ]] && usage && exit -1

# logging aspect
do_build()
{
    echo -e "\033[32m($(date '+%Y-%m-%d %H:%M:%S')): Building $1\033[0m"
    $*
    echo -e "\033[32m($(date '+%Y-%m-%d %H:%M:%S')): Finished $1\033[0m"
}

# change directory to the location of this script
ORIGIN_PWD=$(pwd)
SCRIPT_DIR=$(cd `dirname $0`; pwd)

# parse options
PREFIX=$ORIGIN_PWD && [ -n "$1" ] && PREFIX=$1
ARCH=x86 && [ -n "$2" ] && ARCH=$2

# setup cross-chain
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
if [ "$ARCH" = "arm" ]; then
    HOST=arm-linux-gnueabihf
    export CC=$HOST-gcc
    export CXX=$HOST-g++
    export CPP=$HOST-cpp
    export AS=$HOST-as
    export LD=$HOST-ld
    export STRIP=$HOST-strip
    TOOLCHAIN="-DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/ToolChain.cmake"
else
    export CC=gcc
    export CXX=g++
    export CPP=cpp
    export AS=as
    export LD=ld
    export STRIP=strip
fi

export C_INCLUDE_PATH=$PREFIX/include
export CPLUS_INCLUDE_PATH=$PREFIX/include
export LD_LIBRARY_PATH=$PREFIX/lib
mkdir -p $PREFIX/share/
echo "CPPFLAGS=-I$PREFIX/include LDFLAGS=-L$PREFIX/lib" > $PREFIX/share/config.site
mkdir -p $ORIGIN_PWD/3rd/cache

spider()
{
    spider_path=/root/spider
    git clone https://github.com/deerlets/spider.git $spider_path
    cd $spider_path && git checkout v2.1
    mkdir -p $spider_path/build && cd $spider_path/build
    cmake .. -DBUILD_DEBUG=on -DBUILD_TESTS=off
    make
}

spider-apps()
{
    spider_apps_path=/root/spider-apps
    git clone https://github.com/deerlets/spider-apps.git $spider_apps_path
    cd $spider_apps_path && git checkout master
    mkdir -p $spider_apps_path/build && cd $spider_apps_path/build
    cmake .. -DBUILD_DEBUG=on
    make
    cp -a apps/* /root/spider/build/apps/
}

spider-web()
{
    spider_web_path=/root/spider-web
    git clone https://github.com/deerlets/spider-web.git $spider_web_path
    cd $spider_web_path && git checkout master
    npm install
    npm run build
    cp -a build /root/spider/build/web
}

do_build spider
do_build spider-apps
do_build spider-web
