luacdir53="lua53"
luacdir54="lua54"
luajitdir="luajit-2.1"
luapath=""
lualibname=""
lualinkpath=""
outpath=""
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
            lualinkpath="android"
            outpath="Plugins"
            break
        ;;
        "2")
            luapath=$luacdir53
            lualibname="liblua"
            lualinkpath="android53"
            outpath="Plugins53"
            break
        ;;
        "3")
            luapath=$luacdir54
            lualibname="liblua"
            lualinkpath="android54"
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
cd $DIR/$luapath/src

# Android/ARM, armeabi-v7a (ARMv7 VFP), Android 4.0+ (ICS)
NDK=D:/Program/Android/Sdk/ndk/16.1.4479499
NDKABI=21
NDKVER=$NDK/toolchains/arm-linux-androideabi-4.9
NDKP=$NDKVER/prebuilt/windows-x86_64/bin/arm-linux-androideabi-
NDKF="-isystem $NDK/sysroot/usr/include/arm-linux-androideabi -D__ANDROID_API__=$NDKABI -D_FILE_OFFSET_BITS=32"
NDK_SYSROOT_BUILD=$NDK/sysroot
NDK_SYSROOT_LINK=$NDK/platforms/android-$NDKABI/arch-arm
NDKARCH="-march=armv7-a -mfloat-abi=softfp -Wl,--fix-cortex-a8"

case $luapath in 
    $luacdir53)
        $NDK/ndk-build.cmd clean APP_ABI="armeabi-v7a,x86,arm64-v8a" APP_PLATFORM=android-$NDKABI
        $NDK/ndk-build.cmd APP_ABI="armeabi-v7a" APP_PLATFORM=android-$NDKABI
        cp obj/local/armeabi-v7a/$lualibname.a ../../android53/jni/
        $NDK/ndk-build.cmd clean APP_ABI="armeabi-v7a,x86,arm64-v8a" APP_PLATFORM=android-$NDKABI
    ;;
    $luacdir54)
        $NDK/ndk-build.cmd clean APP_ABI="armeabi-v7a,x86,arm64-v8a" APP_PLATFORM=android-$NDKABI
        $NDK/ndk-build.cmd APP_ABI="armeabi-v7a" APP_PLATFORM=android-$NDKABI
        cp obj/local/armeabi-v7a/$lualibname.a ../../android54/jni/
        $NDK/ndk-build.cmd clean APP_ABI="armeabi-v7a,x86,arm64-v8a" APP_PLATFORM=android-$NDKABI
    ;;
    $luajitdir)
        make clean        
        make HOST_CC="gcc -m32" CROSS=$NDKP TARGET_SYS=Linux TARGET_FLAGS="$NDKF $NDKARCH" TARGET_SHLDFLAGS="--sysroot $NDK_SYSROOT_LINK" TARGET_LDFLAGS="--sysroot $NDK_SYSROOT_LINK" TARGET_CFLAGS="--sysroot $NDK_SYSROOT_BUILD"
        cp ./$lualibname.a ../../android/jni/libluajit.a
        make clean
    ;;
esac

cd ../../$lualinkpath
$NDK/ndk-build.cmd clean APP_ABI="armeabi-v7a,x86,arm64-v8a" APP_PLATFORM=android-$NDKABI
$NDK/ndk-build.cmd APP_ABI="armeabi-v7a" APP_PLATFORM=android-$NDKABI
mkdir -p ../$outpath/Android/libs/armeabi-v7a
cp libs/armeabi-v7a/libtolua.so ../$outpath/Android/libs/armeabi-v7a
$NDK/ndk-build.cmd clean APP_ABI="armeabi-v7a,x86,arm64-v8a" APP_PLATFORM=android-$NDKABI