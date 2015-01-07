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

   -d, --data           build a separate package for architecture-
                           independent files
   -Z=<method>          Specify compression method. Available are
                           gzip/gz, bzip2/bz2 and xz.  Default: xz
   --icon=<icon>        use this icon for the desktop entry
```

Example:
```
# download a game
wget http://superhotgame.com/SUPERHOT_Prototype_Linux.zip
wget http://fs1.directupload.net/images/150103/8jk9r9gd.png
unzip SUPERHOT_Prototype_Linux.zip
mv "Linux/SUPERHOT September 2013_Data" "Linux/SUPERHOT_Prototype_Data"
mv "Linux/SUPERHOT September 2013.x86" "Linux/SUPERHOT_Prototype.x86"

# create package
./u2deb.sh prepare ./Linux --icon=8jk9r9gd.png
./u2deb.sh make -Z=bz2
./u2deb.sh clean
```

Minimum dependencies: `debhelper librsvg2-bin imagemagick execstack`

Recommended dependencies:<br>
`libgtk2.0-0 libgtk2.0-0:i386 libglu1-mesa libglu1-mesa:i386 patchelfmod` [<sup>[1]</sup>](https://github.com/darealshinji/patchelfmod)
