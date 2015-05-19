UnityEngine2deb
===============

Create Debian packages of Unity Engine games
```
 Usage:
   u2deb.sh -h|--help|-V|--version
   u2deb.sh -p|prepare <path> [OPTIONS]
   u2deb.sh -b|build|make [OPTIONS]
   u2deb.sh -c|clean [OPTIONS]

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
                           Default: /tmp/UnityEngine2deb_tmp

   -d, --data           build a separate package for architecture-
                           independent files
   -Z=<method>          Specify compression method. Available are
                           gzip/gz, bzip2/bz2 and xz.  Default: xz
   --icon=<icon>        use this icon for the desktop entry
   --no-x86             don't build an i386 package
   --no-x86_64          don't build an amd64 package
   --no-patchelf        don't remove unused DT_NEEDED entries from ELF binary
                           file headers

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
```

Example:
```
# download a game
wget -O env.zip http://www.moddb.com/downloads/mirror/64567/100/dfda248f3f6f8dc9c4f9ef92b9abe1aa
unzip env.zip -d env-game

# create package
export PKGNAME=env-game   # don't conflict with the /usr/bin/env command
export UPSTREAMNAME=Env
./u2deb.sh prepare env-game --data
./u2deb.sh make
./u2deb.sh clean
```

Minimum dependencies: `debhelper imagemagick`

Recommended dependencies: `execstack libgtk2.0-0 libgtk2.0-0:i386 libglu1-mesa libglu1-mesa:i386`
