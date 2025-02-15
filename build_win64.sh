#!/bin/bash
# 64 Bit Version
mkdir -p window/x86_64
luacdir53="lua53"
luacdir54="lua54"
luajitdir="luajit-2.1"
luapath=""
lualibname=""
outpath="Plugins"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while :
do
    echo "Please choose (1)luajit; (2)lua5.3; (3)lua5.4"
    if [ $# -eq 0 ] 
    then
        read input
        param_input=$input
    else
        param_input=$1
        echo "param_input: $param_input"
    fi
    case $param_input in
        "1")
            luapath=$luajitdir
            lualibname="libluajit"
            outpath="Plugins"
            break
        ;;
        "2")
            luapath=$luacdir53
            lualibname="liblua"
            outpath="Plugins53"
            break
        ;;
        "3")
            luapath=$luacdir53
            lualibname="liblua"
            outpath="Plugins54"
            break
        ;;
        *)
            echo "Please enter 1 or 2!!"
            continue
        ;;
    esac
done

echo "select : $luapath"

cd $DIR/$luapath
mingw32-make clean

case $luapath in
    $luacdir53)
        mingw32-make mingw BUILDMODE=static CC="gcc -m64 -std=gnu99"
    ;;
    $luacdir54)
        mingw32-make mingw BUILDMODE=static CC="gcc -m64 -std=gnu99"
    ;;
    $luajitdir)
        mingw32-make BUILDMODE=static CC="gcc -m64 -O2" XCFLAGS=-DLUAJIT_ENABLE_GC64
    ;;
esac

cp src/$lualibname.a ../window/x86_64/$lualibname.a
mingw32-make clean

cd ..
mkdir -p $outpath/x86_64

gcc -m64 -O2 -std=gnu99 -shared \
    tolua.c \
    int64.c \
    uint64.c \
    pb.c \
    lpeg/lpcap.c \
    lpeg/lpcode.c \
    lpeg/lpprint.c \
    lpeg/lptree.c \
    lpeg/lpvm.c \
    struct.c \
    cjson/strbuf.c \
    cjson/lua_cjson.c \
    cjson/fpconv.c \
    luasocket/auxiliar.c \
    luasocket/buffer.c \
    luasocket/except.c \
    luasocket/inet.c \
    luasocket/io.c \
    luasocket/luasocket.c \
    luasocket/mime.c \
    luasocket/options.c \
    luasocket/select.c \
    luasocket/tcp.c \
    luasocket/timeout.c \
    luasocket/udp.c \
    luasocket/wsocket.c \
    luasocket/compat.c \
    lsqlite3/sqlite3.c \
    lsqlite3/lsqlite3.c \
    lpack.c \
    -o $outpath/x86_64/tolua.dll \
    -I./ \
    -I$luapath/src \
    -Icjson \
    -Iluasocket \
    -Ilpeg \
    -lws2_32 \
    -Wl,--whole-archive window/x86_64/$lualibname.a -Wl,--no-whole-archive -static-libgcc -static-libstdc++

echo "build tolua.dll success"