#!/bin/bash
set -e

QTIFW_VER=`${QTIFWDIR}/bin/installerbase --version | sed 's/.* //' | sed 's/^"\(.*\)".*/\1/' | sed '1!d'`

if [[ ${QTIFW_VER} != "2."* ]]; then
	echo "Error: Qt Installer Framework version is not 2 or greater"
	exit 1
fi

mkdir -p ${DOWNLOADDIR}

function set_windows_vars_common( )
{
	EXTENSION=exe
	ADMINDIR="@rootDir@"
}

function download_extract_windows( )
{
	INSTALLERBASE=${DOWNLOADDIR}/qtifw-win-x86/ifw-pkg/bin/installerbase.exe
	wget -c http://download.qt.io/snapshots/ifw/installer-framework/30/installer-framework-build-stripped-win-x86.7z
	7z x -y -o${DOWNLOADDIR}/qtifw-win-x86 ${DOWNLOADDIR}/installer-framework-build-stripped-win-x86.7z ifw-pkg/bin/installerbase.exe
}

function set_linux_vars_common( )
{
	EXTENSION=run
	ADMINDIR=/opt/saturndev/saturn-sdk
}

cd ${DOWNLOADDIR}

if [[ ${HOSTMACH} == "i686-w64-mingw32" ]]; then
	set_windows_vars_common
	download_extract_windows
elif [[ ${HOSTMACH} == "x86_64-w64-mingw32" ]]; then
	set_windows_vars_common
	download_extract_windows
elif [[ ${HOSTMACH} == "i686-pc-linux-gnu" ]]; then
	set_linux_vars_common
	INSTALLERBASE=${DOWNLOADDIR}/qtifw-linux-x86/ifw-pkg/bin/installerbase
	wget -c http://download.qt.io/snapshots/ifw/installer-framework/30/installer-framework-build-stripped-linux-x86.7z
	7z x -y -o${DOWNLOADDIR}/qtifw-linux-x86 ${DOWNLOADDIR}/installer-framework-build-stripped-linux-x86.7z ifw-pkg/bin/installerbase
elif [[ ${HOSTMACH} == "x86_64-pc-linux-gnu" ]]; then
	set_linux_vars_common
	INSTALLERBASE=${DOWNLOADDIR}/qtifw-linux-x64/ifw-pkg/bin/installerbase
	wget -c http://download.qt.io/snapshots/ifw/installer-framework/30/installer-framework-build-stripped-linux-x64.7z
	7z x -y -o${DOWNLOADDIR}/qtifw-linux-x64 ${DOWNLOADDIR}/installer-framework-build-stripped-linux-x64.7z ifw-pkg/bin/installerbase
else
	echo "Unknown build architecture: ${HOSTMACH}"
	exit 1
fi

cd $ROOTDIR
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
	<Publisher>SEGA Dev</Publisher>
	<TargetDir>@homeDir@/saturndev/saturn-sdk</TargetDir>
	<AdminTargetDir>${ADMINDIR}</AdminTargetDir>
	<Watermark>watermark.png</Watermark>
	<InstallerWindowIcon>icon.png</InstallerWindowIcon>
	<StartMenuDir>SEGA Saturn SDK</StartMenuDir>

	<RemoteRepositories>
		<Repository>
			<Url>http://files.segadev.net/saturn-sdk/installer/repo/gcc/elf/${HOSTMACH}</Url>
		</Repository>
		<Repository>
			<Url>http://files.segadev.net/saturn-sdk/installer/repo/make/${HOSTMACH}</Url>
		</Repository>
		<Repository>
			<Url>http://files.segadev.net/saturn-sdk/installer/repo/ide/${HOSTMACH}</Url>
		</Repository>
__EOF__

# Add MSYS2 for Windows
if [[ "${HOSTMACH}" == "i686-w64-mingw32" ]] || [[ "${HOSTMACH}" == "x86_64-w64-mingw32" ]]; then
cat >> installer/config/config.xml << __EOF__
		<Repository>
			<Url>http://files.segadev.net/saturn-sdk/installer/repo/msys2/${HOSTMACH}</Url>
		</Repository>
__EOF__
fi

cat >> installer/config/config.xml << __EOF__
	</RemoteRepositories>
</Installer>
__EOF__

cp $ROOTDIR/images/watermark.png $ROOTDIR/installer/config/watermark.png
cp $ROOTDIR/images/icon.png $ROOTDIR/installer/config/icon.png

cd $ROOTDIR/installer

printf "Creating installer ... "

mkdir -p packages/base/{meta,data}

cat > packages/base/meta/package.xml << __EOF__
<?xml version="1.0" encoding="UTF-8"?>
<Package>
	<Name>base</Name>
	<ForcedInstallation>true</ForcedInstallation>
	<DisplayName>Base</DisplayName>
	<Description>Required installation option</Description>
	<ReleaseDate>2015-07-01</ReleaseDate>
	<Version>$MAJOR_BUILD_NUM.$MINOR_BUILD_NUM.$REVISION_BUILD_NUM.$BUILD_NUM</Version>
	<Script>installscript.qs</Script>
</Package>
__EOF__

cat > packages/base/meta/installscript.qs << __EOF__
function Component( )
{
}

Component.prototype.createOperations = function( )
{
	component.createOperations( );

	if( installer.value( "os" ) === "x11" )
	{
		var Args = [ "export SATURN_ROOT=", "@homeDir@/.bashrc" ];
		var Output = installer.execute( "grep", Args );
		if( Output[ 1 ] === 0 )
		{
			component.addOperation( "LineReplace", "@homeDir@/.bashrc",
				"export SATURN_ROOT=", "export SATURN_ROOT=@TargetDir@" );
		}
		else
		{
			component.addOperation( "AppendFile", "@homeDir@/.bashrc",
				"export SATURN_ROOT=@TargetDir@" );
		}
	}
	if( installer.value( "os" ) === "win" )
	{
		component.addOperation( "EnvironmentVariable", "SATURN_ROOT",
			"@TargetDir@", true );
	}
}
__EOF__

$QTIFWDIR/bin/binarycreator -t $INSTALLERBASE -p packages -c config/config.xml SEGA-Saturn-SDK_${HOSTMACH}_${TAG_NAME}_${MAJOR_BUILD_NUM}.${MINOR_BUILD_NUM}.${REVISION_BUILD_NUM}.${BUILD_NUM}.${EXTENSION}

if [ $? -ne "0" ]; then
	printf "FAILED\n"
	exit 1
fi

printf "OK\n"

