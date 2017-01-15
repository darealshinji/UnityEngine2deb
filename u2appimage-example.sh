#!/bin/bash

# This is a small example recipe showing how to
# create an AppImage (https://github.com/probonopd/AppImageKit/wiki)
# from Unity Engine games.

#APP=simple-unity4-example
APP=simple-unity5-example
LOWERAPP=${APP,,}

#VER1="4.7.2"
VER1="5.5.0"

mkdir -p $APP/$APP.AppDir/usr

cd $APP

wget -q https://github.com/probonopd/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

wget -q https://github.com/darealshinji/simple-unity3d-example/releases/download/r2/unity${VER1}-linux.tar.xz

cd $APP.AppDir

tar xf ../unity${VER1}-linux.tar.xz

rm -rf linux/test_Data/Plugins/x86 linux/test_Data/Mono/x86 linux/test.x86

mv linux ./usr/bin
mv ./usr/bin/test_Data ./usr/bin/${LOWERAPP}_Data
mv ./usr/bin/test.x86_64 ./usr/bin/${LOWERAPP}

cat <<EOF > ${LOWERAPP}.desktop
[Desktop Entry]
Type=Application
Terminal=false
Icon=$LOWERAPP
Name=$APP
Exec=$LOWERAPP
EOF

cp ./usr/bin/${LOWERAPP}_Data/Resources/UnityPlayer.png ${LOWERAPP}.png

get_apprun

#patch_usr

GLIBC_NEEDED=$(glibc_needed)
VERSION=$VER1.glibc$GLIBC_NEEDED
echo $VERSION

get_desktopintegration $LOWERAPP

cd ..

generate_appimage

