#!/usr/bin/env bash
lua53dir="macnojit53/"
lua54dir="macnojit54/"
lua51dir="macnojit/"
luapath=""
lualibname="liblua"
outpath=""

while :
do
    echo "Please choose (1)lua5.1; (2)lua5.3; (3)lua5.4"
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
            luapath=$lua51dir
            outpath="Plugins"
            break
        ;;
        "2")
            luapath=$lua53dir
            outpath="Plugins53"
            break
        ;;
        "3")
            luapath=$lua54dir
            outpath="Plugins54"
            break
        ;;
        *)
            echo "Please enter 1 or 2!!"
            continue
        ;;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/$luapath
xcodebuild clean
xcodebuild -configuration=Release
mkdir -p ../$outpath
cp -r build/Release/tolua.bundle ../$outpath/
