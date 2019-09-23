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
mkdir -p $PREFIX/3rd/cache

libz()
{
    libz_path=$ORIGIN_PWD/3rd/libz
    libz_tar_file=$ORIGIN_PWD/3rd/cache/zlib-1.2.9.tar.gz
    if [ ! -e $libz_tar_file  ]; then
        curl https://codeload.github.com/madler/zlib/tar.gz/v1.2.9 -o $libz_tar_file
    fi
    if [ ! -e $libz_path ]; then
        mkdir $libz_path && tar -xvzf $libz_tar_file -C $libz_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libz_path/build && cd $libz_path/build
        ../configure --prefix=$PREFIX
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libssl()
{
    libssl_path=$ORIGIN_PWD/3rd/libssli
    libssl_tar_file=$ORIGIN_PWD/3rd/cache/openssl-OpenSSL_1_1_1c.tar.gz
    if [ ! -e $libssl_tar_file ]; then
        curl https://codeload.github.com/openssl/openssl/tar.gz/OpenSSL_1_1_1c  -o $libssl_tar_file
    fi
    if [ ! -e $libssl_path ]; then
        mkdir $libssl_path && tar -xvzf $libssl_tar_file -C $libssl_path  --strip-components 1
    fi


    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libssl_path/build && cd $libssl_path/build
        ../config no-asm shared --prefix=$PREFIX
        sed -ie 's/-m64//' Makefile
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libjson-c()
{
    libjson_c_path=$ORIGIN_PWD/3rd/libjson_c
    libjson_c_tar_file=$ORIGIN_PWD/3rd/cache/json-c-json-c-0.13.1-20180305.tar.gz
    if [ ! -e $libjson_c_tar_file ]; then
       curl https://codeload.github.com/json-c/json-c/tar.gz/json-c-0.13.1-20180305 -o $libjson_c_tar_file
    fi

    if [ ! -e $libjson_c_path ]; then
        mkdir $libjson_c_path && tar -xvzf $libjson_c_tar_file -C $libjson_c_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}*)" ]; then
        ./autogen.sh
        mkdir -p $libjson_c_path/build && cd $libjson_c_path/build
        ../configure --prefix=$PREFIX --host=$HOST
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libsqlite3()
{
    libsqlite3_path=$ORIGIN_PWD/3rd/libsqlite3
    libsqlite3_tar_file=$ORIGIN_PWD/3rd/cache/sqlite-version-3.29.0.tar.gz
    if [ ! -e $libsqlite3_tar_file ]; then
        curl https://codeload.github.com/mackyle/sqlite/tar.gz/version-3.29.0 -o $libsqlite3_tar_file
    fi

    if [ ! -e $libsqlite3_path ]; then
        mkdir $libsqlite3_path && tar -xvzf $libsqlite3_tar_file -C $libsqlite3_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -name ${FUNCNAME[0]}.*)" ]; then
        autoreconf --force --install
        mkdir -p $libsqlite3_path/build && cd $libsqlite3_path/build
        ../configure --prefix=$PREFIX --host=$HOST
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

liblua()
{
    liblua_path=$ORIGIN_PWD/3rd/liblua
    liblua_tar_file=$ORIGIN_PWD/3rd/cache/lua-5.3.4.tar.gz
    if [ ! -e $liblua_tar_file ]; then
        curl https://codeload.github.com/lua/lua/tar.gz/v5.3.4 -o $liblua_tar_file
    fi

    if [ ! -e $liblua_path ]; then
        mkdir $liblua_path && tar -xvzf $liblua_tar_file -C $liblua_path  --strip-components 1
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
    libcurl_path=$ORIGIN_PWD/3rd/libcurl
    libcurl_tar_file=$ORIGIN_PWD/3rd/cache/curl-7.61.0.tar.gz
    if [ ! -e $libcurl_tar_file ]; then
        curl https://codeload.github.com/curl/curl/tar.gz/curl-7_61_0 -o $libcurl_tar_file
    fi

    if [ ! -e $libcurl_path ]; then
        mkdir $libcurl_path && tar -xvzf $libcurl_tar_file -C $libcurl_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
    [ ! -e $libcurl_path/configure ] && cd $libcurl_path && ./buildconf
        mkdir -p $libcurl_path/build && cd $libcurl_path/build
        ../configure --prefix=$PREFIX --host=$HOST
        make && make install
    [ $? -ne 0 ] && exit -1
    fi
}

libzmq()
{
    libzeromq_path=$ORIGIN_PWD/3rd/libzeromq
    libzeromq_tar_file=$ORIGIN_PWD/3rd/cache/libzmq-4.2.5.tar.gz
    if [ ! -e $libzeromq_tar_file ]; then
        curl https://codeload.github.com/zeromq/libzmq/tar.gz/v4.2.5 -o $libzeromq_tar_file
    fi

    if [ ! -e $libzeromq_path ]; then
        mkdir $libzeromq_path && tar -xvzf $libzeromq_tar_file -C $libzeromq_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $libzeromq_path && ./autogen.sh 
	./configure --host=$HOST --prefix=$PREFIX --disable-curve-keygen --disable-perf
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libuv()
{
    libuv_path=$ORIGIN_PWD/3rd/libuv
    libuv_tar_file=$ORIGIN_PWD/3rd/cache/libuv-1.20.0.tar.gz
    if [ ! -e $libuv_tar_file ]; then
        curl https://codeload.github.com/libuv/libuv/tar.gz/v1.20.0 -o $libuv_tar_file
    fi

    if [ ! -e $libuv_path ]; then
        mkdir $libuv_path && tar -xvzf $libuv_tar_file -C $libuv_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        ./autogen.sh
        mkdir -p $libuv_path/build && cd $libuv_path/build
        ../configure --prefix=$PREFIX --host=$HOST
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libwebsockets()
{
    libwebsockets_path=$ORIGIN_PWD/3rd/libwebsockets
    libwebsockets_tar_file=$ORIGIN_PWD/3rd/cache/libwebsockets-3.1.0.tar.gz
    if [ ! -e $libwebsockets_tar_file ]; then
        curl https://codeload.github.com/warmcat/libwebsockets/tar.gz/v3.1.0 -o $libwebsockets_tar_file
    fi
    if [ ! -e $libwebsockets_path ]; then
        mkdir $libwebsockets_path && tar -xvzf $libwebsockets_tar_file -C $libwebsockets_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libwebsockets_path/build && cd $libwebsockets_path/build
        cmake .. -DLWS_WITH_SSL=off -DLWS_WITHOUT_TESTAPPS=on \
            -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX $TOOLCHAIN
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libopen62541()
{
    libopen62541_path=$ORIGIN_PWD/3rd/libopen62541
    libopen62541_tar_file=$ORIGIN_PWD/3rd/cache/open62541-0.3.1.tar.gz
    if [ ! -e $libopen62541_tar_file ]; then
        curl https://codeload.github.com/open62541/open62541/tar.gz/v0.3.1 -o $libopen62541_tar_file
    fi
    if [ ! -e $libopen62541_path ]; then
        mkdir $libopen62541_path && tar -xvzf $libopen62541_tar_file -C $libopen62541_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libopen62541_path/build && cd $libopen62541_path/build
        sed -ie 's/-Wall -Wextra -Wpedantic/-Wall -Wextra -Wno-jump-misses-init/g' ../CMakeLists.txt
        cmake .. -DBUILD_SHARED_LIBS=ON -DUA_ENABLE_AMALGAMATION=ON \
            -DUA_LOGLEVEL=600 -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX $TOOLCHAIN
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libmosquitto()
{
    libmosquitto_path=$ORIGIN_PWD/3rd/libmosquitto
    libmosquitto_tar_file=$ORIGIN_PWD/3rd/cache/mosquitto-1.6.4.tar.gz
    if [ ! -e $libmosquitto_tar_file ]; then
        curl https://codeload.github.com/eclipse/mosquitto/tar.gz/v1.6.4 -o $libmosquitto_tar_file
    fi
    if [ ! -e $libmosquitto_path ]; then
        mkdir $libmosquitto_path && tar -xvzf $libmosquitto_tar_file -C $libmosquitto_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libmosquitto_path/build && cd $libmosquitto_path/build
        cmake .. -DWITH_TLS=off -DDOCUMENTATION=off -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX $TOOLCHAIN
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

cmocka()
{
    cmocka_path=$ORIGIN_PWD/3rd/cmocka
    cmocka_tar_file=$ORIGIN_PWD/3rd/cache/cmocka-1.1.5.tar.gz
    if [ ! -e $cmocka_tar_file ]; then
        curl https://git.cryptomilk.org/projects/cmocka.git/snapshot/cmocka-1.1.5.tar.gz -o $cmocka_tar_file
    fi
    if [ ! -e $cmocka_path ]; then
        mkdir $cmocka_path && tar -xvzf $cmocka_tar_file -C $cmocka_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib* -maxdepth 1 -name *${FUNCNAME[0]}*)" ]; then
        mkdir -p $cmocka_path/build && cd $cmocka_path/build
        cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$PREFIX
        make -j$JOBS && make install
        [ ! $? -eq 0 ] && exit 1
    fi
}


zlog()
{
    zlog_path=$ORIGIN_PWD/3rd/zlog
    zlog_tar_file=$ORIGIN_PWD/3rd/cache/zlog-1.2.14.tar.gz
     if [ ! -e $zlog_tar_file ]; then
         curl https://codeload.github.com/HardySimpson/zlog/tar.gz/1.2.14 -o $zlog_tar_file
     fi
    if [ ! -e $zlog_path ]; then
        mkdir $zlog_path && tar -xvzf $zlog_tar_file -C $zlog_path  --strip-components 1
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $zlog_path
        make PREFIX=$PREIFX && make PREFIX=$PREFIX install
        [ $? -ne 0 ] && exit -1
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
        [ $? -ne 0 ] && exit -1
    fi
}

bonfire()
{
    bonfire_path=$PREFIX/3rd/bonfire
    if [ ! -e $bonfire_path ]; then
        git clone https://github.com/deerlets/bonfire.git $bonfire_path
        cd $bonfire_path && git checkout v2.0.0
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name *${FUNCNAME[0]}.*)" ]; then
        mkdir -p $bonfire_path/build && cd $bonfire_path/build
        cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_DEBUG=on -DSPDNET_DEBUG=on
        make && make install
    fi
}

libzio()
{
    libzio_path=$PREFIX/3rd/libzio
    if [ ! -e $libzio_path ]; then
        git clone https://github.com/deerlets/libzio.git $libzio_path
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        mkdir -p $libzio_path/build && cd $libzio_path/build
        cmake .. -DWITH_TESTS=off -DCMAKE_INSTALL_PREFIX=$PREFIX
        make && make install
        [ $? -ne 0 ] && exit -1
    fi
}

libmodbus()
{
    libmodbus_path=$PREFIX/3rd/libmodbus
    if [ ! -e $libmodbus_path ]; then
        git clone https://github.com/stephane/libmodbus.git $libmodbus_path
        cd $libmodbus_path && git checkout v3.1.6
        #git clone https://github.com/deerlets/libmodbus.git $libmodbus_path
        #cd $libmodbus_path && git checkout yuqing-dev
        #ln -s ../../include $libmodbus_path/include
        #ln -s ../../lib $libmodbus_path/lib
    fi

    if [ ! "$(find $PREFIX/lib -maxdepth 1 -name ${FUNCNAME[0]}.*)" ]; then
        cd $libmodbus_path
        sed -ie 's/AC_FUNC_MALLOC/#&/' configure.ac
        ./autogen.sh
        ./configure --prefix=$PREFIX --host=$HOST --disable-tests
        #cd src
        #sed -ie 's/CFLAGS .*/& -I..\/include -L..\/lib -lzio/' Makefile
        make && make install
        [ $? -ne 0 ] && exit -1
        #cd -
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
        [ $? -ne 0 ] && exit -1
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
        [ $? -ne 0 ] && exit -1
    fi
}

if [ "$ARCH" != "x86" ]; then
    do_build libz
    do_build libssl
    #do_build libjson-c
    #do_build libsqlite3
    #do_build libcurl
    do_build libzmq
    #do_build libuv
    do_build libwebsockets
    do_build libmosquitto
    do_build cmocka
fi

do_build liblua
do_build zlog
do_build bonfire

#do_build libzio
do_build libmodbus
do_build libopen62541
#do_build libnodave
#do_build libtuxplc
