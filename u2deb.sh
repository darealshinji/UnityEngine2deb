#!/bin/bash

# Copyright (c) 2014, djcj <djcj@gmx.de>
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

appversion="14.09.07.1"

appname=$(basename "$0")
topsrc=$(pwd)
debian="$topsrc/build/x86/debian"
cleanfiles="build icon source"

if [ -d "$topsrc/templates" ] ; then
  templates="$topsrc/templates"
elif [ -d "/usr/local/share/$appname" ] ; then
  templates="/usr/local/share/$appname"
elif [ -d "/usr/share/$appname" ] ; then
  templates="/usr/share/$appname"
else
  echo "Can't find the templates!"
  exit 1
fi

if [ "$1" = "-V" ] || [ "$1" = "--version" ] ; then
  echo $appversion
  exit 0
fi
if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "help" ] ; then
cat << EOF

 Create Debian packages of Unity Engine games

 Usage:
   $appname -h|--help|-V|--version
   $appname -p|prepare <path> [-Z=<method>] [-d|--data]
   $appname -b|build|make [-Z=<method>]
   $appname -c|clean

 options:
   -h, --help           print this message
   -V, --version        display version info and quit

   -p, prepare <path>   copy files from <path> and prepare a Debian
                           source package
   -b, build, make      build binary packages
   -c, clean            clean the working tree

   -d, --data           build a separate package for architecture-
                           independent files
   -Z=<method>          Specify compression method. Available are
                           gzip/gz, bzip2/bz2 and xz.  Default: xz
   --icon=<icon>        use this icon for the desktop entry

EOF
exit 1
fi


DATAPACKAGE="no"
ICON=""
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
      rm -rf $cleanfiles description
      echo "clean files in '$topsrc'"
      exit 0
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
    "help"|"-h"|"--version"|"-V")
      ;;
    *)
      path="$optarg"
      ;;
  esac
done


################# prepare #################
if [ $mode = "prepare" ] ; then
  [ "$Z" = "gz" ] && Z="gzip"
  [ "$Z" = "bz2" ] && Z="bzip2"
  if [ "$Z" != "gzip" ] && [ "$Z" != "bzip2" ] && [ "$Z" != "xz" ] ; then
    Z="xz"
  fi

  if [ -z "$path" ] ; then
    echo "no path specified"
    exit 1
  elif [ ! -e "$path" ] ; then
    echo "path to '$path' doesn't exist"
    exit 1
  elif [ ! -d "$path" ] ; then
    echo "'$path' is not a directory"
    exit 1
  else
    path="$( cd "$path" && pwd )"
  fi
  rm -rf $cleanfiles

  # copy source files
  mkdir "$topsrc/source"
  cp -r "$path"/* "$topsrc/source"

  # get the application name
  UPSTREAMNAME=$(basename "$(find source -type d -name *_Data)" | head -c-6)
  NAME=$(echo "$UPSTREAMNAME" | tr '[A-Z]' '[a-z]' | sed -e 's/\ //g; s/_//g')
  [ "$UPSTREAMNAME" != "$NAME" ] && rename "s/$UPSTREAMNAME/$NAME/" source/*

  # check for architectures
  X86="no"
  X86_64="no"
  [ -f "$topsrc/source/$NAME".x86 ] && X86="yes"
  [ -f "$topsrc/source/$NAME".x86_64 ] && X86_64="yes"
  if [ $X86 = "no" ] && [ $X86_64 = "no" ] ; then
    echo "neither $NAME.x86 nor $NAME.x86_64 found"
    exit 1
  fi

  # icon
  WITH_GPL_ICON="no"
  mkdir "$topsrc/icon"
  if [ -z "$ICON" ] || [ ! -f "$ICON" ] ; then
    if [ -f "$topsrc/source/${NAME}_Data/Resources/UnityPlayer.png" ] ; then
      cp "$topsrc/source/${NAME}_Data/Resources/UnityPlayer.png" "$topsrc/icon/$NAME.png"
      ICON="$topsrc/icon/$NAME.png"
    else
      cp "$templates/icon.svg" "$topsrc/icon/$NAME.svg"
      ICON="$topsrc/icon/$NAME.svg"
      WITH_GPL_ICON="yes"
    fi
    else
      cp "$ICON" "$topsrc/icon/$NAME.png"
      ICON="$topsrc/icon/$NAME.png"
  fi

  # enter packaging information
  echo ""
  echo "Please enter a brief description,"
  read -p "i.e. 'Unity engine video game': " SHORTDESCRIPTION
  if [ ! -f "$topsrc/description" ] ; then
    cp "$templates/description" "$topsrc"
    echo ""
    echo "Please add a more detailed description about the game in the text file"
    echo "$templates/description"
    echo "and press any key to continue."
    read -p "" -n1 -s
  fi
  echo ""
  echo "Enter the game's release version. It should begin with a number"
  read -p "and mustn't contain and spaces or underscores: " VERSION
  echo ""
  echo "Enter the package maintainer information."
  read -p "Use the following pattern: John Doe <nick@domain.org> " MAINTAINER
  echo ""
  read -p "What's the game's homepage? " HOMEPAGE
  echo ""
  read -p "What year is this game from? " YEAR
  echo ""
  read -p "Who's holding the copyright? " RIGHTHOLDER
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
  cp -r "$templates/source" "$templates/compat" \
	"$templates/link.mk" "$templates/lintian-overrides" \
	"$templates/rules" "$templates/make-icons.sh" "$debian"
  chmod a+x "$debian/rules" "$debian/make-icons.sh"

  cat >> "$topsrc/build/x86/${NAME}.desktop" << EOF
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

  echo "debian/${NAME}.6" > "$topsrc/build/x86/debian/${NAME}.manpages"

  cat >> "$topsrc/build/x86/debian/${NAME}.6" << EOF
.TH ${NAME^^} 6 "" "$(date +%d.%m.%Y)"
.SH NAME
$NAME \- $SHORTDESCRIPTION
.SH SYNOPSIS
.B $NAME
.SH OPTIONS
This game has no command line options.
.SH DESCRIPTION
EOF
  cat "$topsrc/description" | fold -s >> "$topsrc/build/x86/debian/${NAME}.6"
  cat >> "$topsrc/build/x86/debian/${NAME}.6" << EOF
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
License: other-1
 Copyright (c) $YEAR, $RIGHTHOLDER
 All Rights Reserved.

EOF
  cat "$templates/debian-copyright" >> "$debian/copyright"
  [ $WITH_GPL_ICON = "yes" ] && (cat "$templates/icon-copyright" >> "$debian/copyright")

  if [ $DATAPACKAGE = "yes" ] ; then
    DATADEPENDS=", ${NAME}-data (= \${binary:Version})"
  fi
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
Depends: \${misc:Depends}, \${shlibs:Depends}$DATADEPENDS
Description: $SHORTDESCRIPTION
EOF
  cat "$topsrc/description" | fold -s | sed -e 's/^ *//g' -e 's/^$/./g' -e 's/^ */ /g' >> "$debian/control"

  if [ $DATAPACKAGE = "yes" ] ; then
    cat >> "$debian/control" << EOF

Package: ${NAME}-data
Architecture: all
Depends: \${misc:Depends}
Recommends: $NAME
Description: $SHORTDESCRIPTION - game data
EOF
    cat "$topsrc/description" | fold -s | sed -e 's/^ *//g' -e 's/^$/./g' -e 's/^ */ /g' >> "$debian/control"
    echo " ." >> "$debian/control"
    echo " This package installs the $NAME game data." >> "$debian/control"
  fi

  cat >> "$debian/changelog" << EOF
$NAME ($VERSION) unstable; urgency=medium

  * Initial release
 
 -- $MAINTAINER  $(date -R)
EOF

  if [ $X86_64 = "yes" ] ; then
    mkdir -p "$topsrc/build/x86_64/debian"
    cp -rf "$debian"/* "$topsrc/build/x86_64/debian"
    cp -f "$topsrc/build/x86/${NAME}.desktop" "$topsrc/build/x86_64"
    cat >> "$topsrc/build/x86_64/debian/confflags" << EOF
NAME = $NAME
ICON = "$ICON"
CPU = x86_64
xCPU = x86
DATAPACKAGE = $DATAPACKAGE
Z = $Z
EOF
  fi
  cat >> "$debian/confflags" << EOF
NAME = $NAME
ICON = "$ICON"
CPU = x86
xCPU = x86_64
DATAPACKAGE = $DATAPACKAGE
Z = $Z
EOF

  [ $X86 = "no" ] && rm -rf "$topsrc/build/x86"
  [ $X86_64 = "no" ] && rm -rf "$topsrc/build/x86_64"
  if [ -d "$topsrc/build/x86" ] ; then
    echo -n "copy source files to build/x86... "
    cp -r source "$topsrc/build/x86"
    echo "done"
  fi
  if [ -d "$topsrc/build/x86_64" ] ; then
    echo -n "copy source files to build/x86_64..."
    cp -r source "$topsrc/build/x86_64"
    echo "done"
  fi
  echo ""
  echo "The files are prepared. Run '$appname build' to build Debian packages."
  echo "Or modify the the files in build/* first"

  exit 0
fi


################## build ##################
if [ $mode = "build" ] ; then
  if [ ! -z "$Z" ] ; then
    [ "$Z" = "gz" ] && Z="gzip"
    [ "$Z" = "bz2" ] && Z="bzip2"
    echo "Z = $Z" >> "$debian/confflags"
  fi

  if [ ! -d "$topsrc/build/x86" ] && [ ! -d "$topsrc/build/x86_64" ] ; then
    echo "no files in '$topsrc/build'!"
    echo "run '$appname prepare <path>' first"
    exit 1
  fi

  if [ -d "$topsrc/build/x86" ] ; then
    cp -r "$topsrc/source" "$topsrc/build/x86"
    cd "$topsrc/build/x86"
    chmod a+x debian/rules
    dpkg-buildpackage -b -us -uc 2>&1 | tee "$topsrc/build/x86-build.log"
  fi

  if [ -d "$topsrc/build/x86_64" ] ; then
    cp -r source "$topsrc/build/x86_64"
    cd "$topsrc/build/x86_64"
    chmod a+x debian/rules
    dpkg-buildpackage -b -us -uc 2>&1 | tee "$topsrc/build/x86_64-build.log"
  fi

  cd "$topsrc/build"
  for f in *.deb ; do
    echo "$f:"
    dpkg-deb -I $f
    lintian $f
    echo ""
  done 2>&1 | tee "$topsrc/build/packages.log"
  for f in *.deb ; do
    echo "$f:"
    dpkg-deb -c $f
    echo ""
  done 2>&1 | tee -a "$topsrc/build/packages.log"
fi

exit 0
