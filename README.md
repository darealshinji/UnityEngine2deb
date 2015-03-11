UnityEngine2deb
===============

Create Debian packages of Unity Engine games
```
 Usage:
   u2deb.sh -h|--help|-V|--version
   u2deb.sh -p|prepare <path> [-Z=<method>] [-d|--data] [--icon=<icon>]
   u2deb.sh -b|build|make [-Z=<method>]
   u2deb.sh -c|clean

 options:
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
   FILENAME             specify a name for the executable and the package
   SHORTDESCRIPTION     a brief game description for the package and menu entry
   VERSION              the game's upstream version
   MAINTAINER           The package maintainer. Make sure to use the following
                           pattern: John Doe <nick@domain.org>
   HOMEPAGE             homepage of the game or the developer
   YEAR                 the year when the game was released
   RIGHTHOLDER          Who's holding the copyright?
```

Example:
```
# download a game
wget http://superhotgame.com/SUPERHOT_Prototype_Linux.zip
wget -O sh-icon.png http://fs1.directupload.net/images/150103/8jk9r9gd.png
unzip SUPERHOT_Prototype_Linux.zip

# create package
export UPSTREAMNAME="SUPERHOT Prototype"
./u2deb.sh prepare ./Linux --icon=sh-icon.png
./u2deb.sh make -Z=bz2
./u2deb.sh clean
```

Minimum dependencies: `debhelper librsvg2-bin imagemagick execstack`

Recommended dependencies:<br>
`libgtk2.0-0 libgtk2.0-0:i386 libglu1-mesa libglu1-mesa:i386 patchelfmod` [<sup>[1]</sup>](https://github.com/darealshinji/patchelfmod)
