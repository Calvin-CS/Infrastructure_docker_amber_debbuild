#!/usr/bin/bash

# This is for CUDA
# https://developer.download.nvidia.com/compute/cuda/redist/
# Use ONLY official redist releases
# Tested: 11.8.0

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

# Variables you shouldn't change
# ###################################################
PKGNAME=cuda-amberredist
SRCDIRECTORY=cuda
VERSION=$CUDAVERSION
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)
SECTION=libs

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Downloads"
echo "# # # # #"

# Download URL
URL=https://raw.githubusercontent.com/NVIDIA/build-system-archive-import-examples/main/parse_redist.py

# Check to see if source is extracted, if not, extract it
if ! test -d /src/${SRCDIRECTORY}; then
  echo "${SRCDIRECTORY} - Making ${SRCDIRECTORY} src directory."
  mkdir /src/${SRCDIRECTORY}
else
  echo "${SRCDIRECTORY} - src/${SRCDIRECTORY} exists."
fi

# Check if download script exists, if NOT, download it
if ! test -f /src/${SRCDIRECTORY}/parse_redist.py; then
  echo "${SRCDIRECTORY} - Downloading source for ${SRCDIRECTORY} parse_redist.py."
  wget ${URL} -O /src/${SRCDIRECTORY}/parse_redist.py
else
  echo "${SRCDIRECTORY} - parse_redist.py exists."
fi

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Install required dependencies"
echo "# # # # #"

# Requires
if test -f /scripts/${SRCDIRECTORY}/packages.dep; then
	DEPFILES=/scripts/${SRCDIRECTORY}/packages.dep
	if test -f /scripts/${SRCDIRECTORY}/packages.dep.${CODENAME}; then
		DEPFILES="${DEPFILES} /scripts/${SRCDIRECTORY}/packages.dep.${CODENAME}"
	fi
	REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
else
	if test -f /scripts/${SRCDIRECTORY}/packages.dep.${CODENAME}; then
		DEPFILES="/scripts/${SRCDIRECTORY}/packages.dep.${CODENAME}"
		REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
	else
		DEPFILES=
		REQUIRES=
	fi
fi

#echo "${SRCDIRECTORY} - Package requirements: ${REQUIRES}"

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Sources BUILD"
echo "# # # # #"

# Check for Ubuntu 24.04 workaround -- if miniconda is installed, use that 
# for Python instead of built in python3
if [ -d /opt/conda ]; then
  . /opt/conda/etc/profile.d/conda.sh
  conda activate base
fi

# Download and flatten things
cd /src/${SRCDIRECTORY}
python3 parse_redist.py --product cuda --os linux --arch x86_64 --label $VERSION -w

# Install it into the system - into $INSTALLPREFIX
cd /src/${SRCDIRECTORY}/flat
mkdir -p ${INSTALLPREFIX}/${SRCDIRECTORY}-${VERSION}/
mv linux-x86_64 ${INSTALLPREFIX}/${SRCDIRECTORY}-${VERSION}/

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - DEBIAN PACKAGE CREATION"
echo "# # # # # "

# Make a DEBIAN package chroot environment, and populate the control file
mkdir -p /chroot/${SRCDIRECTORY}/DEBIAN /chroot/${SRCDIRECTORY}/${MODULESDIR}
sed -e "s:PKGNAME:${PKGNAME}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:VERSION:${VERSION}:g; s:RELEASE:${RELEASE}:g; s:MAINTAINERNAME:${MAINTAINERNAME}:g; s:MAINTAINEREMAIL:${MAINTAINEREMAIL}:g; s:REQUIRES:${REQUIRES}:g; s:SECTION:${SECTION}:g" /scripts/control-template > /chroot/${SRCDIRECTORY}/DEBIAN/control
mkdir -p /chroot/${SRCDIRECTORY}/${INSTALLPREFIX}

# mv the source directory
mv ${INSTALLPREFIX}/${SRCDIRECTORY}-${VERSION} /chroot/${SRCDIRECTORY}/${INSTALLPREFIX}/

# make the updated modules file
sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment > /chroot/${SRCDIRECTORY}/${MODULESDIR}/${SRCDIRECTORY}-${VERSION}

# Build and send the deb file to /pkgs
mkdir -p /pkgs/${CODENAME}
cd /chroot/
dpkg-deb -b ${SRCDIRECTORY} /pkgs/${CODENAME}

###########################
echo "# # # # #""
echo "# ${SRCDIRECTORY} - INSTALL DEBIAN PACKAGE"
echo "# # # # #""
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  /pkgs/${CODENAME}/${PKGNAME}_${VERSION}-${RELEASE}_amd64.deb

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - FINAL CLEANUP"
echo "# # # # #"

# Cleanup of flat source files
rm -rf /src/${SRCDIRECTORY}/flat /chroot/${SRCDIRECTORY}
