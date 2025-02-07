#!/usr/bin/env bash
luacdir53="lua53"
luacdir54="lua54"
luajitdir="luajit-2.1"
luapath=""
lualibname=""
linkpath=""
outpath=""

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
            linkpath="iOS"
            break
        ;;
        "2")
            luapath=$luacdir53
            lualibname="liblua"
            outpath="Plugins53"
            linkpath="iOS53"
            break
        ;;
        "3")
            luapath=$luacdir54
            lualibname="liblua"
            outpath="Plugins54"
            linkpath="iOS54"
            break
        ;;
        *)
            echo "Please enter 1 or 2!!"
            continue
        ;;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIPO="xcrun -sdk iphoneos lipo"
STRIP="xcrun -sdk iphoneos strip"

SRCDIR=$DIR/$luapath/
DESTDIR=$DIR/$linkpath
IXCODE=`xcode-select -print-path`
ISDK=$IXCODE/Platforms/iPhoneOS.platform/Developer
ISDKD=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/
ISDKVER=iPhoneOS.sdk
ISDKP=$IXCODE/usr/bin/

if [ ! -e $ISDKP/ar ]; then 
  sudo cp $ISDKD/usr/bin/ar $ISDKP
fi

if [ ! -e $ISDKP/ranlib ]; then
  sudo cp $ISDKD/usr/bin/ranlib $ISDKP
fi

if [ ! -e $ISDKP/strip ]; then
  sudo cp $ISDKD/usr/bin/strip $ISDKP
fi

rm "$DESTDIR"/*.a

case $luapath in 
    $luacdir53)
        cd $DESTDIR/lua53/
        xcodebuild clean
        xcodebuild -configuration=Release
        cp -f ./build/Release-iphoneos/$lualibname.a "$DESTDIR"/$lualibname.a
        cd ../
    ;;
    $luacdir54)
        cd $DESTDIR/lua54/
        xcodebuild clean
        xcodebuild -configuration=Release
        cp -f ./build/Release-iphoneos/$lualibname.a "$DESTDIR"/$lualibname.a
        cd ../
    ;;
    $luajitdir)
        cd $SRCDIR
#        make clean
#        ISDKF="-arch armv7 -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=8.0 -fembed-bitcode"
#        make HOST_CC="gcc -m32" TARGET_FLAGS="$ISDKF" TARGET=armv7 TARGET_SYS=iOS BUILDMODE=static
#        mv "$SRCDIR"/src/$lualibname.a "$DESTDIR"/$lualibname-armv7.a
#
#        make clean
#        ISDKF="-arch armv7s -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=8.0 -fembed-bitcode"
#        make HOST_CC="gcc -m32" TARGET_FLAGS="$ISDKF" TARGET=armv7s TARGET_SYS=iOS BUILDMODE=static
#        mv "$SRCDIR"/src/$lualibname.a "$DESTDIR"/$lualibname-armv7s.a

        make clean
        ISDKF="-arch arm64 -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=8.0 -fembed-bitcode"
        make HOST_CC="gcc " TARGET_FLAGS="$ISDKF" TARGET=arm64 TARGET_SYS=iOS BUILDMODE=static
        mv "$SRCDIR"/src/$lualibname.a "$DESTDIR"/$lualibname-arm64.a
        make clean

        cd ../$linkpath
        $LIPO -create "$DESTDIR"/$lualibname-*.a -output "$DESTDIR"/$lualibname.a
        $STRIP -S "$DESTDIR"/$lualibname.a
    ;;
esac

xcodebuild clean
xcodebuild -configuration=Release
mkdir -p ../$outpath/iOS
cp -f ./build/Release-iphoneos/libtolua.a ../$outpath/iOS/
