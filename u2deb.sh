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
scriptpath="$(dirname "$(readlink -f "$0")")"
linkname="UnityEngine2deb_working_directory"
defaultwd="/tmp/UnityEngine2deb_tmp"

[ -z $(which patchelfmod) ] && patchelfmod=no || patchelfmod=yes

errorExit() {
  echo "error: $1"
  exit 1
}

help() {
cat << EOF

 Create Debian packages of Unity Engine games

 Usage:
   $appname -h|--help|-V|--version
   $appname -p|prepare <path> [OPTIONS]
   $appname -b|build|make [OPTIONS]
   $appname -c|clean [OPTIONS]

 Options:
   -h, --help           print this message
   -V, --version        display version info and quit

   -p, prepare <path>   copy files from <path> and prepare a Debian
                           source package
   -b, build, make      build binary packages
   -c, clean            delete the working tree

   -o=<path>,
   --output=<path>      save Debian packages in <path>
   --working-dir=<path> Working directory where the temporary files are stored.
                           Default: $defaultwd

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
   COPYRIGHT            Who's holding the copyright?

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

if [ -d "$scriptpath/templates" ] ; then
  templates="$scriptpath/templates"
elif [ -d "$scriptpath/../share/$appname" ] ; then
  templates="$scriptpath/../share/$appname"
elif [ -d "/usr/local/share/$appname" ] ; then
  templates="/usr/local/share/$appname"
elif [ -d "/usr/share/$appname" ] ; then
  templates="/usr/share/$appname"
else
  errorExit "Can't find the templates!"
fi


datapackage="no"
icon=""
mode="empty"
output="$HOME"
disable_x86="no"
disable_x86_64="no"
wd=""
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
      mode="clean"
      ;;
    --output=*|-o=*)
      output="$optarg"
      ;;
    --working-dir=*)
      wd="$optarg"
      ;;
    "--data"|"-d")
      datapackage="yes"
      ;;
    -Z=*)
      compression="$optarg"
      ;;
    --icon=*)
      icon="$optarg"
      ;;
    "--no-x86")
      disable_x86="yes"
      ;;
    "--no-x86_64")
      disable_x86_64="yes"
      ;;
    "help"|"-h"|"--version"|"-V")
      ;;
    *)
      origpath="$optarg"
      ;;
  esac
done

if [ $disable_x86 = "yes" ] && [ $disable_x86_64 = "yes" ] ; then
  errorExit "you can't use \`--no-x86' together with \`--no-x86_64'"
fi

if [ $mode = "empty" ] ; then
  help
  exit 1
fi

if ([ $mode = "build" ] || [ $mode = "clean" ]) && [ -L "$PWD/$linkname" ] && [ -z "$wd" ] ; then
  wd="$(readlink "$PWD/$linkname")"
fi
[ -n "$wd" ] && topsrc="$wd" || topsrc="$defaultwd"
builddir="$topsrc/build"
sourcedir="$topsrc/source"
icondir="$builddir/icon"
debian="$builddir/x86/debian"



################## clean ##################
if [ $mode = "clean" ] ; then
  rm -rvf "$topsrc"
  [ ! -L "$PWD/$linkname" ] || rm -v "$PWD/$linkname"
  exit 0
fi


################# prepare #################
if [ $mode = "prepare" ] ; then
  [ "$compression" = "gz" ] && compression="gzip"
  [ "$compression" = "bz2" ] && compression="bzip2"
  if [ "$compression" != "gzip" ] && [ "$compression" != "bzip2" ] && [ "$compression" != "xz" ] ; then
    compression="xz"
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
  filename="$(basename "$(find "$origpath" -type d -name *_Data)" | head -c-6)"
  [ -z "$PKGNAME" ] && name="$filename" || name="$PKGNAME"
  [ -z "$UPSTREAMNAME" ] && UPSTREAMNAME="$name"
  if [ -n "$UPSTREAMNAME" ] && [ -n "$PKGNAME" ] ; then
    name="$PKGNAME"
  fi

  # check for architectures
  x86="no"
  x86_64="no"
  rename_to_x86="no"
  rename_to_x86_64="no"
  [ -f "$origpath/$filename".x86 ] && x86="yes"
  [ -f "$origpath/$filename".x86_64 ] && x86_64="yes"
  if [ $x86 = "no" ] && [ $x86_64 = "no" ] ; then
    echo "neither '$filename.x86' nor '$filename.x86_64' found"
    if [ -f "$origpath/$filename" ] ; then
      if [ "$(file "$origpath/$filename" | grep 'ELF 32-bit')" ]; then
        echo "'$filename' (x86) found"
        x86="yes"
        rename_to_x86="yes"
      elif [ "$(file "$origpath/$filename" | grep 'ELF 64-bit')" ]; then
        echo "'$filename' (x86_64) found"
        x86_64="yes"
        rename_to_x86_64="yes"
      else
        errorExit "'$filename' was found but is not a valid ELF binary"
      fi
    else
      errorExit "couldn't find '$filename' either"
    fi
  fi
  if [ $disable_x86 = "yes" ] && [ $x86_64 = "no" ] ; then
    errorExit "x86 disabled but no x86_64 binary found"
  elif [ $disable_x86_64 = "yes" ] && [ $x86 = "no" ] ; then
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
  name=$(echo "$name" | sed -e 's/\(.*\)/\L\1/; s/\ -\ /-/g; s/\ /-/g; s/_/-/g')
  [ "$filename" != "$name" ] && rename "s/$filename/$name/" "$sourcedir"/*
  if [ "$rename_to_x86" = "yes" ] && [ -f "$sourcedir/$name" ] ; then
    mv "$sourcedir/$name" "$sourcedir/${name}.x86"
    echo "application was renamed to ${name}.x86"
  elif [ "$rename_to_x86_64" = "yes" ] && [ -f "$sourcedir/$name" ] ; then
    mv "$sourcedir/$name" "$sourcedir/${name}.x86_64"
    echo "application was renamed to ${name}.x86_64"
  fi

  # icon
  with_gpl_icon="no"
  mkdir -p "$icondir"
  if [ -z "$icon" ] || [ ! -f "$icon" ] ; then
    if [ -f "$sourcedir/${name}_Data/Resources/UnityPlayer.png" ] ; then
      cp "$sourcedir/${name}_Data/Resources/UnityPlayer.png" "$icondir/$name.png"
      icon="$icondir/$name.png"
    else
      cp "$templates/icon.svg" "$icondir/$name.svg"
      icon="$icondir/$name.svg"
      with_gpl_icon="yes"
    fi
    else
      cp "$icon" "$icondir/$name.png"
      icon="$icondir/$name.png"
  fi

  # enter packaging information
  echo ""
  echo "name: $UPSTREAMNAME"
  echo "application/package name: $name"
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
  if [ -z "$COPYRIGHT" ] ; then
    echo ""
    read -p "Who's holding the copyright? " COPYRIGHT
  else
    echo "copyright: $COPYRIGHT"
  fi
  echo ""
  echo ""
  [ -z "$SHORTDESCRIPTION" ] && SHORTDESCRIPTION="Unity engine video game"
  [ -z "$VERSION" ] && VERSION=$(date +%y.%m.%d.1)
  [ -z "$MAINTAINER" ] && MAINTAINER="John Doe <nick@domain.org>"
  [ -z "$HOMEPAGE" ] && HOMEPAGE="http://www.unity3d.com/"
  [ -z "$YEAR" ] && YEAR=$(date +%Y)
  [ -z "$COPYRIGHT" ] && COPYRIGHT="the creator of '$name'"

  # create Debian files
  mkdir -p "$debian"
  cp -r \
  "$templates/source" \
  "$templates/compat" \
  "$templates/lintian-overrides" \
  "$templates/rules" \
  "$templates/make-icons.sh" "$debian"
  chmod a+x "$debian/rules" "$debian/make-icons.sh"

  cat >> "$builddir/x86/${name}.desktop" << EOF
[Desktop Entry]
Name=$UPSTREAMNAME
Comment=$SHORTDESCRIPTION
TryExec=/usr/lib/$name/$name
Exec=$name
Type=Application
Categories=Game;
StartupNotify=true
Icon=$name
EOF

  echo "debian/${name}.6" > "$builddir/x86/debian/${name}.manpages"

  cat >> "$builddir/x86/debian/${name}.6" << EOF
.TH ${name^^} 6 "" "$(date +%d.%m.%Y)"
.SH NAME
$name \- $SHORTDESCRIPTION
.SH SYNOPSIS
.B $name
.SH OPTIONS
This game has no command line options.
.SH DESCRIPTION
EOF
  fold -s "$topsrc/description" >> "$builddir/x86/debian/${name}.6"
  cat >> "$builddir/x86/debian/${name}.6" << EOF
.SH SEE ALSO
.I $HOMEPAGE
.SH AUTHOR
$COPYRIGHT
EOF

  cat >> "$debian/copyright" << EOF
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $UPSTREAMNAME
Source: $HOMEPAGE

Files: *
Copyright: $YEAR $COPYRIGHT
License:
 Copyright (c) $YEAR, $COPYRIGHT
 All Rights Reserved.

EOF
  cat "$templates/debian-copyright" >> "$debian/copyright"
  [ $with_gpl_icon = "yes" ] && (cat "$templates/icon-copyright" >> "$debian/copyright")

  [ $datapackage = "yes" ] && datadeps=", ${name}-data (= \${binary:Version})"
  cat >> "$debian/control" << EOF
Source: $name
Section: games
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper (>= 9)
Standards-Version: 3.9.5
Homepage: $HOMEPAGE

Package: $name
Architecture: any
Depends: \${misc:Depends}, \${shlibs:Depends}, libpulse0$datadeps
Description: $SHORTDESCRIPTION
EOF
  fold -s -w 79 "$topsrc/description" | sed 's/^/ /g; s/^ $/ ./g; s/ $//g' >> "$debian/control"

  if [ $datapackage = "yes" ] ; then
    cat >> "$debian/control" << EOF

Package: ${name}-data
Architecture: all
Depends: \${misc:Depends}
Recommends: $name
Description: $SHORTDESCRIPTION - game data
EOF
    fold -s -w 79 "$topsrc/description" | sed 's/^/ /g; s/^ $/ ./g; s/ $//g' >> "$debian/control"
    echo " ." >> "$debian/control"
    echo " This package installs the $name game data." >> "$debian/control"
  fi

  cat >> "$debian/changelog" << EOF
$name ($VERSION) unstable; urgency=medium

  * Initial release
 
 -- $MAINTAINER  $(date -R)
EOF

  if [ $x86_64 = "yes" ] ; then
    mkdir -p "$builddir/x86_64/debian"
    cp -rf "$debian"/* "$builddir/x86_64/debian"
    cp -f "$builddir/x86/${name}.desktop" "$builddir/x86_64"
    cat >> "$builddir/x86_64/debian/confflags" << EOF
NAME = $name
ICON = "$icon"
ARCH = x86_64
DATAPACKAGE = $datapackage
Z = $compression
PATCHELFMOD = $patchelfmod
EOF
  fi
  cat >> "$debian/confflags" << EOF
NAME = $name
ICON = "$icon"
ARCH = x86
DATAPACKAGE = $datapackage
Z = $compression
PATCHELFMOD = $patchelfmod
EOF

  [ $disable_x86 = "yes" ] && rm -rf "$builddir/x86"
  [ $disable_x86_64 = "yes" ] && rm -rf "$builddir/x86_64"
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
  if [ ! -z "$compression" ] ; then
    [ "$compression" = "gz" ] && compression="gzip"
    [ "$compression" = "bz2" ] && compression="bzip2"
    echo "Z = $compression" >> "$builddir/x86/debian/confflags"
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
  cp -f *.deb "$output"
  echo "Debian packages copied to '$output'"
fi

exit 0
