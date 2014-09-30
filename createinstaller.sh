#!/bin/bash
set -e

mkdir -p $DOWNLOADDIR

if [[ ${HOSTMACH} == "i686-w64-mingw32" ]]; then
	EXTENSION=exe
	ADMINDIR="@rootDir@"
	INSTALLERBASE=$DOWNLOADDIR/qtifw-win-x86/ifw-bld/bin/installerbase.exe
	cd $DOWNLOADDIR
	wget -c http://download.qt-project.org/snapshots/ifw/1.5/2014-02-13_50/installer-framework-build-win-x86.7z
	7z x -y -o$DOWNLOADDIR/qtifw-win-x86 $DOWNLOADDIR/installer-framework-build-win-x86.7z ifw-bld/bin/installerbase.exe
	cd $ROOTDIR
elif [[ ${HOSTMACH} == "x86_64-w64-mingw32" ]]; then
	EXTENSION=exe
	ADMINDIR="@rootDir@"
	INSTALLERBASE=$DOWNLOADDIR/qtifw-win-x64/ifw-bld/bin/installerbase.exe
	cd $DOWNLOADDIR
	wget -c http://download.qt-project.org/snapshots/ifw/1.5/2014-02-13_50/installer-framework-build-win-x86.7z
	7z x -y -o$DOWNLOADDIR/qtifw-win-x64 $DOWNLOADDIR/installer-framework-build-win-x86.7z ifw-bld/bin/installerbase.exe
	cd $ROOTDIR
elif [[ ${HOSTMACH} == "i686-pc-linux-gnu" ]]; then
	EXTENSION=run
	ADMINDIR=/opt/saturndev/saturn-sdk
	INSTALLERBASE=$DOWNLOADDIR/qtifw-linux-x86/ifw-bld/bin/installerbase
	cd $DOWNLOADDIR
	wget -c http://download.qt-project.org/snapshots/ifw/1.5/2014-02-13_50/installer-framework-build-linux-x86.7z
	7z x -y -o$DOWNLOADDIR/qtifw-linux-x86 $DOWNLOADDIR/installer-framework-build-linux-x86.7z ifw-bld/bin/installerbase
	cd $ROOTDIR
elif [[ ${HOSTMACH} == "x86_64-pc-linux-gnu" ]]; then
	EXTENSION=run
	ADMINDIR=/opt/saturndev/saturn-sdk
	INSTALLERBASE=$DOWNLOADDIR/qtifw-linux-x64/ifw-bld/bin/installerbase
	cd $DOWNLOADDIR
	wget -c http://download.qt-project.org/snapshots/ifw/1.5/2014-02-13_50/installer-framework-build-linux-x64.7z
	7z x -y -o$DOWNLOADDIR/qtifw-linux-x64 $DOWNLOADDIR/installer-framework-build-linux-x64.7z ifw-bld/bin/installerbase
	cd $ROOTDIR
else
	echo "Unknown build architecture: ${HOSTMACH}"
	exit 1
fi

export TAG_NAME=`git describe --tags | sed -e 's/_[0-9].*//'`
export VERSION_NUM=`git describe --match "${TAG_NAME}_[0-9]*" HEAD | sed -e 's/-g.*//' -e "s/${TAG_NAME}_//"`
export MAJOR_BUILD_NUM=`echo $VERSION_NUM | sed 's/-[^.]*$//' | sed -r 's/.[^.]*$//' | sed -r 's/.[^.]*$//'`
export MINOR_BUILD_NUM=`echo $VERSION_NUM | sed 's/-[^.]*$//' | sed -r 's/.[^.]*$//' | sed -r 's/.[.]*//'`
export REVISION_BUILD_NUM=`echo $VERSION_NUM | sed 's/-[^.]*$//' | sed -r 's/.*(.[0-9].)//'`
export BUILD_NUM=`echo $VERSION_NUM | sed -e 's/[0-9].[0-9].[0-9]//' -e 's/-//'`

if [ -x $TAG_NAME ]; then
	TAG_NAME=unknown
fi

if [ -z $MAJOR_BUILD_NUM ]; then
	MAJOR_BUILD_NUM=0
fi

if [ -z $MINOR_BUILD_NUM ]; then
	MINOR_BUILD_NUM=0
fi

if [ -z $REVISION_BUILD_NUM ]; then
	REVISION_BUILD_NUM=0
fi

if [ -z $BUILD_NUM ]; then
	BUILD_NUM=0
fi

mkdir -p installer/config

cat > installer/config/config.xml << __EOF__
<?xml version="1.0" encoding="UTF-8"?>
<Installer>
	<Name>SEGA Saturn SDK</Name>
	<Version>$MAJOR_BUILD_NUM.$MINOR_BUILD_NUM.$REVISION_BUILD_NUM.$BUILD_NUM</Version>
	<Title>SEGA Saturn SDK</Title>
	<Publisher>Open Game Developers</Publisher>
	<TargetDir>@homeDir@/saturndev/saturn-sdk</TargetDir>
	<AdminTargetDir>${ADMINDIR}</AdminTargetDir>
	<Watermark>watermark.png</Watermark>
	<InstallerWindowIcon>icon.png</InstallerWindowIcon>
	<StartMenuDir>SEGA Saturn SDK</StartMenuDir>

	<RemoteRepositories>
		<Repository>
			<Url>ftp://opengamedevelopers.org/saturn-sdk/installer/repo/gcc/elf/${HOSTMACH}</Url>
		</Repository>
		<Repository>
			<Url>ftp://opengamedevelopers.org/saturn-sdk/installer/repo/make/${HOSTMACH}</Url>
		</Repository>
	</RemoteRepositories>
</Installer>
__EOF__

cp $ROOTDIR/images/watermark.png $ROOTDIR/installer/config/watermark.png
cp $ROOTDIR/images/icon.png $ROOTDIR/installer/config/icon.png

cd $ROOTDIR/installer

printf "Creating installer ... "

mkdir -p nopackages

$QTIFWDIR/bin/binarycreator -t $INSTALLERBASE -p nopackages -c config/config.xml SEGA-Saturn-SDK_${HOSTMACH}_${TAG_NAME}_${MAJOR_BUILD_NUM}.${MINOR_BUILD_NUM}.${REVISION_BUILD_NUM}.${BUILD_NUM}.${EXTENSION}

if [ $? -ne "0" ]; then
	printf "FAILED\n"
	exit 1
fi

printf "OK\n"

