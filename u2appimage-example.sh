#!/bin/bash
set -e
set -x

# This is a small example recipe showing how to
# create an AppImage (https://github.com/probonopd/AppImageKit/wiki)
# from Unity Engine games.

# name of the game
APP=simple-unity5-example
LOWERAPP=${APP,,}

# replace this with the game's actual version string
VER1="5.5.0"

# create directories
mkdir -p $APP/$APP.AppDir/usr
cd $APP

# download and source the functions needed to build an AppImage
wget -q https://github.com/probonopd/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

# download the game
wget -q https://github.com/darealshinji/simple-unity3d-example/releases/download/r2/unity${VER1}-linux.tar.xz

# move into AppDir
cd $APP.AppDir

# extract the downloaded game files
tar xf ../unity${VER1}-linux.tar.xz

# delete 32 bit binaries (can be skipped, but this will save some space)
rm -rf linux/test_Data/Plugins/x86 linux/test_Data/Mono/x86 linux/test.x86

# move game files into the AppDir's usr/bin directory and rename them
mv linux ./usr/bin
mv ./usr/bin/test_Data ./usr/bin/${LOWERAPP}_Data
mv ./usr/bin/test.x86_64 ./usr/bin/${LOWERAPP}

# create a .desktop file
cat <<EOF > ${LOWERAPP}.desktop
[Desktop Entry]
Name=$APP
Exec=$LOWERAPP
Terminal=false
Type=Application
Icon=$LOWERAPP
Categories=Game;
StartupNotify=true
EOF

# copy the game icon file
cp ./usr/bin/${LOWERAPP}_Data/Resources/UnityPlayer.png ${LOWERAPP}.png

# copy runtime dependencies (the required system libraries to run the game);
# this should usually not be necessary for Unity Engine games (they're
# very portable and distribution agnostic)
#copy_deps
#move_lib

# download the needed AppImage runtime files
get_apprun

# append required minimum glibc version to the version string
GLIBC_NEEDED=$(glibc_needed)
VERSION=$VER1.glibc$GLIBC_NEEDED
echo $VERSION

# this will enable desktop integration (optional)
get_desktopintegration $LOWERAPP

# leave AppDir
cd ..

# build AppImage
generate_appimage

