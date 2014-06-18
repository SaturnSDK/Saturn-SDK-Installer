#!/bin/bash
set -e

if [[ ${BUILDMACH} == "i686-w64-mingw32" ]]; then
	EXTENSION=exe
elif [[ ${BUILDMACH} == "x86_64-w64-mingw32" ]]; then
	EXTENSION=exe
elif [[ ${BUILDMACH} == "i686-pc-linux-gnu" ]]; then
	EXTENSION=run
elif [[ ${BUILDMACH} == "x86_64-pc-linux-gnu" ]]; then
	EXTENSION=run
else
	echo "Unknown build architecture: ${BUILDMACH}"
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
	<AdminTargetDir>/opt/saturndev/saturn-sdk</AdminTargetDir>
	<Watermark>watermark.png</Watermark>

	<RemoteRepositories>
		<Repository>
			<Url>ftp://opengamedevelopers.org/saturn-sdk/installer/repo/gcc/${BUILDMACH}</Url>
		</Repository>
		<Repository>
			<Url>ftp://opengamedevelopers.org/saturn-sdk/installer/repo/sgl</Url>
		</Repository>
	</RemoteRepositories>
</Installer>
__EOF__

cp $ROOTDIR/images/watermark.png $ROOTDIR/installer/config

cd $ROOTDIR/installer

printf "Creating installer ... "

mkdir -p nopackages

$QTIFWDIR/bin/binarycreator -p nopackages -c config/config.xml SEGA-Saturn-SDK_${BUILDMACH}_${TAG_NAME}_${MAJOR_BUILD_NUM}.${MINOR_BUILD_NUM}.${REVISION_BUILD_NUM}.${BUILD_NUM}.${EXTENSION}

if [ $? -ne "0" ]; then
	printf "FAILED\n"
	exit 1
fi

printf "OK\n"

