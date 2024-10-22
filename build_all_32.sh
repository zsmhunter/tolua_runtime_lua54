echo "Please choose (0)allversion; (1)luajit; (2)lua5.3; (3)lua5.4:"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
read input

if [ $input -eq 0 ] || [ $input -eq 1 ]; then
    echo "start build luajit"
	$DIR/build_x86.sh 1
	$DIR/build_win32.sh 1
	$DIR/build_arm.sh 1
fi
if [ $input -eq 0 ] || [ $input -eq 2 ]; then
    echo "start build lua5.3"
	$DIR/build_x86.sh 2
	$DIR/build_win32.sh 2
	$DIR/build_arm.sh 2
fi
if [ $input -eq 0 ] || [ $input -eq 3 ]; then
    echo "start build lua5.4"
    $DIR/build_x86.sh 3
	$DIR/build_win32.sh 3
	$DIR/build_arm.sh 3
fi