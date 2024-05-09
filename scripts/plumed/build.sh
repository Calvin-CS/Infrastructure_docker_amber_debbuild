#!/usr/bin/bash

# This is for PLUMED
# https://github.com/plumed/plumed2
# Use ONLY official releases
# Tested: 2.9.0
# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

# Variables you shouldn't change
# ###################################################
PKGNAME=plumed-redist
SRCDIRECTORY=plumed
VERSION=$PLUMEDVERSION
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)
SECTION=libs

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Downloads"
echo "# # # # #"

# Download URL
URL=https://github.com/plumed/plumed2/releases/download/v${PLUMEDVERSION}/plumed-src-${PLUMEDVERSION}.tgz

# Check to see if source is extracted, if not, extract it
if ! test -d /src/${SRCDIRECTORY}; then
  echo "${SRCDIRECTORY} - Making ${SRCDIRECTORY} src directory."
  mkdir /src/${SRCDIRECTORY}
else
  echo "${SRCDIRECTORY} - src/${SRCDIRECTORY} exists."
fi

# Check if src tar.gz exists, if NOT, download it
if ! test -f /src/plumed/plumed-src-${PLUMEDVERSION}.tgz; then
  echo "Downloading source for plumed plumed-src-${PLUMEDVERSION}.tgz"
  wget ${URL} -O /src/plumed/plumed-src-${PLUMEDVERSION}.tgz
fi

# Check if sources have been unzipped
if ! test -d /src/plumed/plumed-${PLUMEDVERSION}; then
  echo "Unzipping source for plumed plumed-${PLUMEDVERSION}.tgz"
  cd /src/plumed/
  tar zxfv plumed-src-${PLUMEDVERSION}.tgz
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

#echo "Package requirements: ${REQUIRES}"

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Load required module environment"
echo "# # # # #"
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIVERSION}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Sources BUILD"
echo "# # # # #"

# build script
cd /src/plumed/plumed-${PLUMEDVERSION}
./configure --prefix=${INSTALLPREFIX}/plumed-${PLUMEDVERSION}
make -j${NPROC}
make install

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

# make the updated modules file(s)
if test -f /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment.${CODENAME}; then
  sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment.${CODENAME} > /chroot/${SRCDIRECTORY}/${MODULESDIR}/${SRCDIRECTORY}-${VERSION}
else
  sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment > /chroot/${SRCDIRECTORY}/${MODULESDIR}/${SRCDIRECTORY}-${VERSION}
fi

# Build and send the deb file to /pkgs
mkdir -p /pkgs/${CODENAME}
cd /chroot/
ls -R /chroot/
cat /chroot/${SRCDIRECTORY}/DEBIAN/control
dpkg-deb -b ${SRCDIRECTORY} /pkgs/${CODENAME}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - INSTALL DEBIAN PACKAGE"
echo "# # # # #"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  /pkgs/${CODENAME}/${PKGNAME}_${VERSION}-${RELEASE}_amd64.deb


###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Load module environment"
echo "# # # # #"
module load ${SRCDIRECTORY}-${VERSION}
module avail

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - FINAL CLEANUP"
echo "# # # # #"

# Cleanup of flat source files
rm -rf /src/${SRCDIRECTORY}/${SRCDIRECTORY}-${VERSION} /chroot/${SRCDIRECTORY}