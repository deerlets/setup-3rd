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
    export CC=arm-linux-gnueabihf-gcc
    export CXX=arm-linux-gnueabihf-g++
    export STRIP=arm-linux-gnueabihf-strip
    export AR=arm-linux-gnueabihf-ar
    HOST=arm-linux-gnueabihf
    TOOLCHAIN="-DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/ToolChain.cmake"
else
    export CC=gcc
    export CXX=g++
    export STRIP=strip
    export AR=ar
fi

libz()
{
    libz_path=$PREFIX/3rd/libz
    if [ ! -e $libz_path ]; then
        git clone https://github.com/madler/zlib.git $libz_path
        cd $libz_path && git checkout v1.2.9
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $libz_path
        ./configure --prefix=$PREFIX
        make && make install
    fi
}

libssl()
{
    libssl_path=$PREFIX/3rd/libssl
    if [ ! -e $libssl_path ]; then
        git clone https://github.com/openssl/openssl.git $libssl_path
        cd $libssl_path && git checkout OpenSSL_1_1_1c
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $libssl_path
        ./config no-asm shared --prefix=$PREFIX
        sed -ie 's/-m64//' Makefile
        make && make install
    fi
}

libjson-c()
{
    libjson_c_path=$PREFIX/3rd/libjson_c
    if [ ! -e $libjson_c_path ]; then
        git clone https://github.com/json-c/json-c.git $libjson_c_path
        cd $libjson_c_path && git checkout json-c-0.13.1-20180305
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}*)" ]; then
        cd $libjson_c_path
        ./autogen.sh
        ./configure --prefix=$PREFIX --host=$HOST
        make && make install
    fi
}

libsqlite3()
{
    libsqlite3_path=$PREFIX/3rd/libsqlite3
    if [ ! -e $libsqlite3_path ]; then
        git clone https://github.com/mackyle/sqlite.git $libsqlite3_path
    fi

    if [ ! "$(find $PREFIX/lib -name ${FUNCNAME[0]}.*)" ]; then
        cd $libsqlite3_path
        autoreconf --force --install
        ./configure --prefix=$PREFIX --host=$HOST
        make && make install
    fi
}

liblua()
{
    liblua_path=$PREFIX/3rd/liblua
    if [ ! -e $liblua_path ]; then
        git clone https://github.com/lua/lua $liblua_path
        cd $liblua_path && git checkout v5.3.4
    fi

    if [ ! "$(find $PREFIX/lib -name ${FUNCNAME[0]}.*)" ]; then
        cd $liblua_path
        find . -name '*.c' -exec $CC -c -fPIC {} \; && $CC -shared -o liblua.so *.o
        mkdir -p $PREFIX/lib && cp liblua.so $PREFIX/lib
        mkdir -p $PREFIX/include/lua && cp lua.h lualib.h lauxlib.h luaconf.h $PREFIX/include/lua
    fi
}

libcurl()
{
    libcurl_path=$PREFIX/3rd/libcurl
    if [ ! -e $libcurl_path ]; then
        git clone https://github.com/curl/curl.git $libcurl_path
        cd $libcurl_path && git checkout curl-7_61_0
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd  $libcurl_path
        ./configure --prefix=$PREFIX --host=$HOST
        make && make install
    fi
}

libzmq()
{
    libzeromq_path=$PREFIX/3rd/libzeromq
    if [ ! -e $libzeromq_path ]; then
        git clone https://github.com/zeromq/libzmq.git $libzeromq_path
        cd $libzeromq_path && git checkout v4.2.5
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libzeromq_path/build && cd $libzeromq_path/build
        cmake .. -DWITH_OPENPGM=off -DBUILD_TESTS=off -DWITH_PERF_TOOL=off \
            -DCMAKE_INSTALL_PREFIX=$PREFIX $TOOLCHAIN
        make && make install
    fi
}

libuv()
{
    libuv_path=$PREFIX/3rd/libuv
    if [ ! -e $libuv_path ]; then
        git clone https://github.com/libuv/libuv.git $libuv_path
        cd $libuv_path && git checkout v1.20.0
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $libuv_path
        ./autogen.sh
        ./configure --prefix=$PREFIX --host=$HOST
        make && make install
    fi
}

libwebsockets()
{
    libwebsockets_path=$PREFIX/3rd/libwebsockets
    if [ ! -e $libwebsockets_path ]; then
        git clone https://github.com/warmcat/libwebsockets.git $libwebsockets_path
        cd $libwebsockets_path && git checkout v2.4.2
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libwebsockets_path/build && cd $libwebsockets_path/build
        cmake .. -DLWS_WITH_LIBUV=1 -DLWS_WITH_SSL=off -DLWS_WITHOUT_TESTAPPS=on \
            -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX $TOOLCHAIN
        make && make install
    fi
}

libopen62541()
{
    libopen62541_path=$PREFIX/3rd/libopen62541
    if [ ! -e $libopen62541_path ]; then
        git clone https://github.com/open62541/open62541.git $libopen62541_path
        cd $libopen62541_path && git checkout v0.3-rc4
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libopen62541_path/build && cd $libopen62541_path/build
        cmake .. -DBUILD_SHARED_LIBS=ON -DUA_ENABLE_AMALGAMATION=ON \
            -DUA_LOGLEVEL=600 -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX $TOOLCHAIN
        make && make install
    fi
}

libmosquitto()
{
    libmosquitto_path=$PREFIX/3rd/libmosquitto
    if [ ! -e $libmosquitto_path ]; then
        git clone https://github.com/eclipse/mosquitto.git $libmosquitto_path
        cd $libmosquitto_path && git checkout v1.4.15
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd  $libmosquitto_path
        cmake -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX $TOOLCHAIN
        make && make install
    fi
}

cmocka()
{
    cmocka_path=$PREFIX/3rd/cmocka
    if [ ! -e $cmocka_path ]; then
        git clone https://git.cryptomilk.org/projects/cmocka.git $cmocka_path
    fi

    if [ ! "$(find $PREFIX/lib* -maxdepth 1 -name *${FUNCNAME[0]}*)" ]; then
        mkdir -p $cmocka_path/build && cd $cmocka_path/build
        cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX
        make -j$JOBS && make install
        [ ! $? -eq 0 ] && exit 1
    fi
}

libgossip()
{
    libgossip_path=$PREFIX/3rd/libgossip
    if [ ! -e $libgossip_path ]; then
        git clone https://github.com/deerlets/libgossip.git $libgossip_path
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libgossip_path/build && cd $libgossip_path/build
        cmake .. -DWITH_TESTS=off -DCMAKE_INSTALL_PREFIX=$PREFIX
        make && make install
    fi
}

zebra()
{
    zebra_path=$PREFIX/3rd/zebra
    if [ ! -e $zebra_path ]; then
        git clone https://github.com/deerlets/zebra.git $zebra_path
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name *${FUNCNAME[0]}.*)" ]; then
        mkdir -p $zebra_path/build && cd $zebra_path/build
        cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_DEBUG=on -DSPDNET_DEBUG=on
        make && make install
    fi
}

libzio()
{
    libzio_path=$PREFIX/3rd/libzio
    if [ ! -e $libzio_path ]; then
        git clone https://gitee.com/deerlets/libzio.git $libzio_path
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libzio_path/build && cd $libzio_path/build
        cmake .. -DWITH_TESTS=off -DCMAKE_INSTALL_PREFIX=$PREFIX
        make && make install
    fi
}

libmodbus()
{
    libmodbus_path=$PREFIX/3rd/libmodbus
    if [ ! -e $libmodbus_path ]; then
        git clone https://gitee.com/deerlets/libmodbus.git $libmodbus_path
        cd $libmodbus_path && git checkout yuqing-dev
        ln -s ../../include $libmodbus_path/include
        ln -s ../../lib $libmodbus_path/lib
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $libmodbus_path
        sed -ie 's/AC_FUNC_MALLOC/#&/' configure.ac
        ./autogen.sh
        ./configure --prefix=$PREFIX --host=$HOST --disable-tests
        cd src
        sed -ie 's/CFLAGS .*/& -I..\/include -L..\/lib -lzio/' Makefile
        make && make install
        cd -
        sed -ie 's/#AC_FUNC_MALLOC/AC_FUNC_MALLOC/' configure.ac
    fi
}

libnodave()
{
    libnodave_path=$PREFIX/3rd/libnodave
    if [ ! -e $libnodave_path ]; then
        git clone $GIT_BASE/iot/nodave.git $libnodave_path
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libnodave_path/build && cd $libnodave_path/build
        cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX $TOOLCHAIN
        make && make install
    fi
}

libtuxplc()
{
    libtuxplc_path=$PREFIX/3rd/libtuxplc
    if [ ! -e $libtuxplc_path ]; then
        git clone $GIT_BASE/mirrors/TuxPLC.git $libtuxplc_path
    fi
    cd $libtuxplc_path && git checkout litai-dev

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libtuxplc_path/build && cd $libtuxplc_path/build
        cmake ../tuxeip -DWITH_TESTS=off -DCMAKE_INSTALL_PREFIX=$PREFIX $TOOLCHAIN
        make && make install
    fi
}

if [ "$ARCH" != "x86" ]; then
    do_build libz
    do_build libssl
    do_build libjson-c
    do_build libsqlite3
    do_build libcurl
    do_build libzmq
    do_build libuv
    do_build libmosquitto
    #do_build cmocka
fi

do_build liblua
do_build libwebsockets
do_build libopen62541

do_build libgossip
do_build zebra

do_build libzio
do_build libmodbus

#do_build libnodave
#do_build libtuxplc
