UnityEngine2deb
===============

Create Debian packages of Unity Engine games

**u2deb**: Package a Unity game in two steps. First run `u2deb prepare <gamedir>` and follow the instructions.
The game files will be copied into a temporary directory and Debian packaging files will be generated.
You can manually edit those files. Then run `u2deb build` to create the package. To delete the temporary files
run `u2deb clean`. You can get a full list of options and environment variables with `u2deb --help`.

**copyunityengine**: This script will download and install Linux binaries of a Unity engine game and delete all previously
installed binary files. Usage is `copyunityengine <gamedir>`.
You can use this script to create native Linux versions of games that were released for
Windows only or to create native 64 bit versions if a Linux build was originally released only as 32 bit version.
You can also use it to install the screenselector plugin if the original build came without it.

Minimum dependencies: `debhelper imagemagick p7zip-full¹`

Recommended dependencies: `aria2¹ wget¹ execstack lintian libgtk2.0-0 libgtk2.0-0:i386 libglu1-mesa libglu1-mesa:i386`

¹ only required by copyunityengine

**Examples:**

Build 32 and 64 bit packages of a native game and store the platform independent
files in a separate "-data" package:
```
wget -O env.zip http://www.moddb.com/downloads/mirror/64567/100/dfda248f3f6f8dc9c4f9ef92b9abe1aa
unzip env.zip -d env-game

export PKGNAME=env-game
export UPSTREAMNAME=Env
./u2deb prepare env-game --data
./u2deb build
```

Build a 64 bit package from a 32 bit native game:
```
wget http://superhotgame-new.azurewebsites.net/BUILDS/SUPERHOT_Prototype_Linux.zip
unzip SUPERHOT_Prototype_Linux.zip

export PKGNAME=superhot-prototype
export UPSTREAMNAME="SUPERHOT Prototype"
./copyunityengine Linux
./u2deb prepare Linux --no-x86
./u2deb build
```

Build packages from a Windows-only game:
```
wget -O coelophyte.zip http://tinyurl.com/o2h6cpb
unzip coelophyte.zip -d coelophyte

./copyunityengine coelophyte
./u2deb prepare coelophyte
./u2deb build
```

**Package this tool:**

You can also build a Debian package from this tool.
```
sudo apt-get install debhelper git
git clone https://github.com/darealshinji/UnityEngine2deb.git
cd UnityEngine2deb
dpkg-buildpackage -b -us -uc
```
