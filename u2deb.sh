#!/bin/bash

set -e

# Copyright (c) 2014-2015, djcj <djcj@gmx.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

LANG=C
LANGUAGE=C
LC_ALL=C

appversion="15.03.12.1"

appname=$(basename "$0")
SCRIPTPATH="$(dirname "$(readlink -f "$0")")"
topsrc="/tmp/UnityEngine2deb_tmp"
builddir="$topsrc/build"
sourcedir="$topsrc/source"
icondir="$builddir/icon"
debian="$builddir/x86/debian"

[ -z $(which patchelfmod) ] && patchelf=no || patchelf=yes

errorExit() {
  echo "error: $1"
  exit 1
}

help() {
cat << EOF

 Create Debian packages of Unity Engine games

 Usage:
   $appname -h|--help|-V|--version
   $appname -p|prepare <path> [-Z=<method>] [-d|--data] [--icon=<icon>]
   $appname -b|build|make [-Z=<method>]
   $appname -c|clean

 Options:
   -h, --help           print this message
   -V, --version        display version info and quit

   -p, prepare <path>   copy files from <path> and prepare a Debian
                           source package
   -b, build, make      build binary packages
   -c, clean            delete the working tree

   -o=<path>,
   --output=<path>      save Debian packages in <path>

   -d, --data           build a separate package for architecture-
                           independent files
   -Z=<method>          Specify compression method. Available are
                           gzip/gz, bzip2/bz2 and xz.  Default: xz
   --icon=<icon>        use this icon for the desktop entry
   --no-x86             don't build an i386 package
   --no-x86_64          don't build an amd64 package

 Environment variables:
   UPSTREAMNAME         the original name of the game, including special chars
                           or spaces
   PKGNAME              specify a name for the executable and the package
   SHORTDESCRIPTION     a brief game description for the package and menu entry
   VERSION              the game's upstream version
   MAINTAINER           The package maintainer. Make sure to use the following
                           pattern: John Doe <nick@domain.org>
   HOMEPAGE             homepage of the game or the developer
   YEAR                 the year when the game was released
   RIGHTHOLDER          Who's holding the copyright?

EOF
}

if [ "$1" = "-V" ] || [ "$1" = "--version" ] ; then
  echo $appversion
  exit 0
fi
if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "help" ] ; then
  help
  exit 0
fi

if [ -d "$SCRIPTPATH/templates" ] ; then
  templates="$SCRIPTPATH/templates"
elif [ -d "$SCRIPTPATH/../share/$appname" ] ; then
  templates="$SCRIPTPATH/../share/$appname"
elif [ -d "/usr/local/share/$appname" ] ; then
  templates="/usr/local/share/$appname"
elif [ -d "/usr/share/$appname" ] ; then
  templates="/usr/share/$appname"
else
  errorExit "Can't find the templates!"
fi


DATAPACKAGE="no"
ICON=""
mode="empty"
OUTPUT="$HOME"
DISABLE_X86="no"
DISABLE_X86_64="no"
for opt; do
  optarg="${opt#*=}"
  case "$opt" in
    "prepare"|"-p")
      mode="prepare"
      ;;
    "build"|"-b"|"make")
      mode="build"
      ;;
    "clean"|"-c")
      rm -rvf "$topsrc"
      [ ! -L "$PWD/UnityEngine2deb_working_directory" ] || rm -v "$PWD/UnityEngine2deb_working_directory"
      exit 0
      ;;
    --output=*|-o=*)
      OUTPUT="$optarg"
      ;;
    "--data"|"-d")
      DATAPACKAGE="yes"
      ;;
    -Z=*)
      Z="$optarg"
      ;;
    --icon=*)
      ICON="$optarg"
      ;;
    "--no-x86")
      DISABLE_X86="yes"
      ;;
    "--no-x86_64")
      DISABLE_X86_64="yes"
      ;;
    "help"|"-h"|"--version"|"-V")
      ;;
    *)
      origpath="$optarg"
      ;;
  esac
done

if [ $DISABLE_X86 = "yes" ] && [ $DISABLE_X86_64 = "yes" ] ; then
  errorExit "you can't use \`--no-x86' together with \`--no-x86_64'"
fi

if [ $mode = "empty" ] ; then
  help
  exit 1
fi


################# prepare #################
if [ $mode = "prepare" ] ; then
  [ "$Z" = "gz" ] && Z="gzip"
  [ "$Z" = "bz2" ] && Z="bzip2"
  if [ "$Z" != "gzip" ] && [ "$Z" != "bzip2" ] && [ "$Z" != "xz" ] ; then
    Z="xz"
  fi

  if [ -z "$origpath" ] ; then
    errorExit "no path specified"
  elif [ ! -e "$origpath" ] ; then
    errorExit "path to '$origpath' doesn't exist"
  elif [ ! -d "$origpath" ] ; then
    errorExit "'$origpath' is not a directory"
  else
    path="$( cd "$origpath" && pwd )"
  fi
  rm -rf $cleanfiles

  # get the application name
  FILENAME="$(basename "$(find "$origpath" -type d -name *_Data)" | head -c-6)"
  [ -z "$PKGNAME" ] && NAME="$FILENAME" || NAME="$PKGNAME"
  [ -z "$UPSTREAMNAME" ] && UPSTREAMNAME="$NAME"
  if [ -n "$UPSTREAMNAME" ] && [ -n "$PKGNAME" ] ; then
    NAME="$PKGNAME"
  fi

  # check for architectures
  X86="no"
  X86_64="no"
  RENAME_TO_X86="no"
  RENAME_TO_X86_64="no"
  [ -f "$origpath/$FILENAME".x86 ] && X86="yes"
  [ -f "$origpath/$FILENAME".x86_64 ] && X86_64="yes"
  if [ $X86 = "no" ] && [ $X86_64 = "no" ] ; then
    echo "neither '$FILENAME.x86' nor '$FILENAME.x86_64' found"
    if [ -f "$origpath/$FILENAME" ] ; then
      if [ "$(file "$origpath/$FILENAME" | grep 'ELF 32-bit')" ]; then
        echo "'$FILENAME' (x86) found"
        X86="yes"
        RENAME_TO_X86="yes"
      elif [ "$(file "$origpath/$FILENAME" | grep 'ELF 64-bit')" ]; then
        echo "'$FILENAME' (x86_64) found"
        X86_64="yes"
        RENAME_TO_X86_64="yes"
      else
        errorExit "'$FILENAME' was found but is not a valid ELF binary"
      fi
    else
      errorExit "couldn't find '$FILENAME' either"
    fi
  fi
  if [ $DISABLE_X86 = "yes" ] && [ $X86_64 = "no" ] ; then
    errorExit "x86 disabled but no x86_64 binary found"
  elif [ $DISABLE_X86_64 = "yes" ] && [ $X86 = "no" ] ; then
    errorExit "x86_64 disabled but no x86 binary found"
  fi

  # create working directory and symlink
  [ ! -L "$PWD/UnityEngine2deb_working_directory" ] || rm "$PWD/UnityEngine2deb_working_directory"
  rm -rf "$topsrc"
  mkdir -p "$topsrc"
  ln -s "$topsrc" "$PWD/UnityEngine2deb_working_directory"

  # copy source files
  echo "copy source files... "
  mkdir -p "$sourcedir"
  cp -vr "$origpath"/* "$sourcedir"
  echo "done"

  # remove executable bits
  find "$sourcedir" -type f -exec chmod a-x '{}' \;

  # remove executable stack
  if [ $(which execstack) ]; then
    find "$sourcedir" -name libmono.so -exec execstack -c '{}' \;
  fi

  # delete unnecessary files
  for f in libCSteamworks.so libsteam_api.so libSteamworksNative.so SteamworksNative.dll \
           UnityEngine.dll.mdb Thumbs.db .DS_Store ;
  do
    find "$sourcedir" -name "$f" -delete
  done
  rm -f "$sourcedir"/*.txt
  rm -rf `find "$sourcedir" -type d -name __MACOSX`

  # rename application
  NAME=$(echo "$NAME" | sed -e 's/\(.*\)/\L\1/; s/\ -\ /-/g; s/\ /-/g; s/_/-/g')
  [ "$FILENAME" != "$NAME" ] && rename "s/$FILENAME/$NAME/" "$sourcedir"/*
  if [ "$RENAME_TO_X86" = "yes" ] && [ -f "$sourcedir/$NAME" ] ; then
    mv "$sourcedir/$NAME" "$sourcedir/${NAME}.x86"
    echo "application was renamed to ${NAME}.x86"
  elif [ "$RENAME_TO_X86_64" = "yes" ] && [ -f "$sourcedir/$NAME" ] ; then
    mv "$sourcedir/$NAME" "$sourcedir/${NAME}.x86_64"
    echo "application was renamed to ${NAME}.x86_64"
  fi

  # icon
  WITH_GPL_ICON="no"
  mkdir -p "$icondir"
  if [ -z "$ICON" ] || [ ! -f "$ICON" ] ; then
    if [ -f "$sourcedir/${NAME}_Data/Resources/UnityPlayer.png" ] ; then
      cp "$sourcedir/${NAME}_Data/Resources/UnityPlayer.png" "$icondir/$NAME.png"
      ICON="$icondir/$NAME.png"
    else
      cp "$templates/icon.svg" "$icondir/$NAME.svg"
      ICON="$icondir/$NAME.svg"
      WITH_GPL_ICON="yes"
    fi
    else
      cp "$ICON" "$icondir/$NAME.png"
      ICON="$icondir/$NAME.png"
  fi

  # enter packaging information
  echo ""
  echo "name: $UPSTREAMNAME"
  echo "application/package name: $NAME"
  if [ -z "$SHORTDESCRIPTION" ] ; then
    echo ""
    echo "Please enter a brief description,"
    read -p "i.e. 'Unity engine video game': " SHORTDESCRIPTION
  else
    echo "description: $SHORTDESCRIPTION"
  fi
  if [ -f "$PWD/description" ] ; then
    cp "$PWD/description" "$topsrc"
  else
    cp "$templates/description" "$topsrc"
    echo ""
    echo "Please add a more detailed description about the game in the text file"
    echo "$topsrc/description"
    echo "and press any key to continue."
    read -p "" -n1 -s
  fi
  echo "" >> "$topsrc/description"  # add a new line to the end of the file
  if [ -z "$VERSION" ] ; then
    echo ""
    echo "Enter the game's release version. It should begin with a number"
    read -p "and mustn't contain and spaces or underscores: " VERSION
  else
    echo "package version: $VERSION"
  fi
  if [ -z "$MAINTAINER" ] ; then
    echo ""
    echo "Enter the package maintainer information."
    echo "Use the following pattern: John Doe <nick@domain.org>"
    read -p " " MAINTAINER
  else
    echo "package maintainer: $MAINTAINER"
  fi
  if [ -z "$HOMEPAGE" ] ; then
    echo ""
    read -p "What's the game's homepage? " HOMEPAGE
  else
    echo "homepage: $HOMEPAGE"
  fi
  if [ -z "$YEAR" ] ; then
    echo ""
    read -p "What year is this game from? " YEAR
  else
    echo "year: $YEAR"
  fi
  if [ -z "$RIGHTHOLDER" ] ; then
    echo ""
    read -p "Who's holding the copyright? " RIGHTHOLDER
  else
    echo "copyright: $RIGHTHOLDER"
  fi
  echo ""
  echo ""
  [ -z "$SHORTDESCRIPTION" ] && SHORTDESCRIPTION="Unity engine video game"
  [ -z "$VERSION" ] && VERSION=$(date +%y.%m.%d.1)
  [ -z "$MAINTAINER" ] && MAINTAINER="John Doe <nick@domain.org>"
  [ -z "$HOMEPAGE" ] && HOMEPAGE="http://www.unity3d.com/"
  [ -z "$YEAR" ] && YEAR=$(date +%Y)
  [ -z "$RIGHTHOLDER" ] && RIGHTHOLDER="the creator of '$NAME'"

  # create Debian files
  mkdir -p "$debian"
  cp -r \
  "$templates/source" \
  "$templates/compat" \
  "$templates/lintian-overrides" \
  "$templates/rules" \
  "$templates/make-icons.sh" "$debian"
  chmod a+x "$debian/rules" "$debian/make-icons.sh"

  cat >> "$builddir/x86/${NAME}.desktop" << EOF
[Desktop Entry]
Name=$UPSTREAMNAME
Comment=$SHORTDESCRIPTION
TryExec=/usr/lib/$NAME/$NAME
Exec=$NAME
Type=Application
Categories=Game;
StartupNotify=true
Icon=$NAME
EOF

  echo "debian/${NAME}.6" > "$builddir/x86/debian/${NAME}.manpages"

  cat >> "$builddir/x86/debian/${NAME}.6" << EOF
.TH ${NAME^^} 6 "" "$(date +%d.%m.%Y)"
.SH NAME
$NAME \- $SHORTDESCRIPTION
.SH SYNOPSIS
.B $NAME
.SH OPTIONS
This game has no command line options.
.SH DESCRIPTION
EOF
  fold -s "$topsrc/description" >> "$builddir/x86/debian/${NAME}.6"
  cat >> "$builddir/x86/debian/${NAME}.6" << EOF
.SH SEE ALSO
.I $HOMEPAGE
.SH AUTHOR
$RIGHTHOLDER
EOF

  cat >> "$debian/copyright" << EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $UPSTREAMNAME
Source: $HOMEPAGE

Files: *
Copyright: $YEAR $RIGHTHOLDER
License:
 Copyright (c) $YEAR, $RIGHTHOLDER
 All Rights Reserved.

EOF
  cat "$templates/debian-copyright" >> "$debian/copyright"
  [ $WITH_GPL_ICON = "yes" ] && (cat "$templates/icon-copyright" >> "$debian/copyright")

  [ $DATAPACKAGE = "yes" ] && DATADEPENDS=", ${NAME}-data (= \${binary:Version})"
  cat >> "$debian/control" << EOF
Source: $NAME
Section: games
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper (>= 9)
Standards-Version: 3.9.5
Homepage: $HOMEPAGE

Package: $NAME
Architecture: any
Depends: \${misc:Depends}, \${shlibs:Depends}, libpulse0$DATADEPENDS
Description: $SHORTDESCRIPTION
EOF
  fold -s -w 79 "$topsrc/description" | sed 's/^/ /g; s/^ $/ ./g; s/ $//g' >> "$debian/control"

  if [ $DATAPACKAGE = "yes" ] ; then
    cat >> "$debian/control" << EOF

Package: ${NAME}-data
Architecture: all
Depends: \${misc:Depends}
Recommends: $NAME
Description: $SHORTDESCRIPTION - game data
EOF
    fold -s -w 79 "$topsrc/description" | sed 's/^/ /g; s/^ $/ ./g; s/ $//g' >> "$debian/control"
    echo " ." >> "$debian/control"
    echo " This package installs the $NAME game data." >> "$debian/control"
  fi

  cat >> "$debian/changelog" << EOF
$NAME ($VERSION) unstable; urgency=medium

  * Initial release
 
 -- $MAINTAINER  $(date -R)
EOF

  if [ $X86_64 = "yes" ] ; then
    mkdir -p "$builddir/x86_64/debian"
    cp -rf "$debian"/* "$builddir/x86_64/debian"
    cp -f "$builddir/x86/${NAME}.desktop" "$builddir/x86_64"
    cat >> "$builddir/x86_64/debian/confflags" << EOF
NAME = $NAME
ICON = "$ICON"
ARCH = x86_64
DATAPACKAGE = $DATAPACKAGE
Z = $Z
PATCHELF = $patchelf
EOF
  fi
  cat >> "$debian/confflags" << EOF
NAME = $NAME
ICON = "$ICON"
ARCH = x86
DATAPACKAGE = $DATAPACKAGE
Z = $Z
PATCHELF = $patchelf
EOF

  [ $DISABLE_X86 = "yes" ] && rm -rf "$builddir/x86"
  [ $DISABLE_X86_64 = "yes" ] && rm -rf "$builddir/x86_64"
  if [ -d "$builddir/x86" ] ; then
    echo "copy files to build/x86... "
    cp -vr $sourcedir "$builddir/x86"
    echo "done"
  fi
  if [ -d "$builddir/x86_64" ] ; then
    echo "copy files to build/x86_64..."
    cp -vr $sourcedir "$builddir/x86_64"
    echo "done"
  fi
  if [ -d "$builddir/x86" ] && [ -d "$builddir/x86_64" ] ; then
    echo "arch_only = --arch" >> "$builddir/x86_64/debian/confflags"
  fi
  echo ""
  echo "The files are prepared. Run '$appname build' to build Debian packages."
  echo "Or modify the the files in '$builddir' first."

  exit 0
fi


################## build ##################
buildpackage () {
  arch=${1}
  name="$(grep 'NAME = ' $builddir/$arch/debian/confflags | sed -e 's/NAME = //')"
  if [ -d "$builddir/${arch}" ] ; then
    cd "$builddir/${arch}"
    chmod a+x debian/rules source/${name}.${arch}
    mv source/${name}.${arch} source/${name}
    test ${arch} = "x86" && purge=x86_64 || purge=x86
    rm -rf source/${name}_Data/Mono/${purge} source/${name}_Data/Plugins/${purge} source/${name}.${purge}
    dpkg-buildpackage -b -us -uc 2>&1 | tee "$builddir/${arch}-build.log"
  fi
}

if [ $mode = "build" ] ; then
  if [ ! -z "$Z" ] ; then
    [ "$Z" = "gz" ] && Z="gzip"
    [ "$Z" = "bz2" ] && Z="bzip2"
    echo "Z = $Z" >> "$debian/confflags"
  fi

  if [ ! -d "$builddir/x86" ] && [ ! -d "$builddir/x86_64" ] ; then
    echo "no files in '$builddir'!"
    errorExit "run '$appname prepare <path>' first"
  fi

  buildpackage x86
  buildpackage x86_64

  cd "$builddir"
  echo ""
  ls *.deb >/dev/null
  if [ $(echo $?) = 0 ] ; then
    for f in *.deb ; do
      echo "$f:"
      dpkg-deb -I $f
      lintian $f
      echo ""
    done 2>&1 | tee "$builddir/packages.log"
    for f in *.deb ; do
      echo "$f:"
      dpkg-deb -c $f
      echo ""
    done 2>&1 | tee -a "$builddir/packages.log"
  fi
  cp -f *.deb "$OUTPUT"
  echo "Debian packages copied to '$OUTPUT'"
fi

exit 0
