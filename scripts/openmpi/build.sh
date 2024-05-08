#!/usr/bin/bash

# This is for OpenMPI
# https://www.open-mpi.org/software/ompi/
# Use ONLY official redist releases
# Tested: 4.1.6  5.0.3

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

# Figure out the major version of OPENMPI, based off of OPENMPIVERSION
OPENMPIMAJORVERSION=$(echo $OPENMPIVERSION | awk -F. '{print $1 "." $2;}' -)
#echo "OPENMPIMAJORVERSION: $OPENMPIMAJORVERSION"

# Variables you shouldn't change
# ###################################################
PKGNAME=openmpi-amberredist
SRCDIRECTORY=openmpi
VERSION=$OPENMPIVERSION
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)
SECTION=libs

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Downloads"
echo "# # # # #"

# Download URL
URL="https://download.open-mpi.org/release/open-mpi/v${OPENMPIMAJORVERSION}/openmpi-${OPENMPIVERSION}.tar.gz"

# Check to see if source is extracted, if not, extract it
if ! test -d /src/${SRCDIRECTORY}; then
  echo "${SRCDIRECTORY} - Making ${SRCDIRECTORY} src directory."
  mkdir /src/${SRCDIRECTORY}
else
  echo "${SRCDIRECTORY} - src/${SRCDIRECTORY} exists."
fi

# Check if src tar.gz exists, if NOT, download it
if ! test -f /src/openmpi/openmpi-${OPENMPIVERSION}.tar.gz; then
  echo "Downloading source for openmpi openmpi-${OPENMPIVERSION}.tar.gz"
  wget ${URL} -O /src/openmpi/openmpi-${OPENMPIVERSION}.tar.gz
fi

# Check if sources have been unzipped
if ! test -d /src/openmpi/openmpi-${OPENMPIVERSION}; then
  echo "Unzipping source for openmpi openmpi-${OPENMPIVERSION}.tar.gz"
  cd /src/openmpi/
  tar zxfv openmpi-${OPENMPIVERSION}.tar.gz
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
echo "# ${SRCDIRECTORY} - Load required environment"
echo "# # # # #"

# Load required environment modules -- CUDA
module purge
module load cuda-${CUDAVERSION}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Sources BUILD"
echo "# # # # #"

cd /src/openmpi/openmpi-${OPENMPIVERSION}
make clean

# do different things based off of distribution
if [ $CODENAME == 'noble' ]; then
	CONFIGUREADD=--with-pmix=/usr/lib/x86_64-linux-gnu/pmix2
else
	CONFIGUREADD=
fi
./configure --prefix=${INSTALLPREFIX}/openmpi-${OPENMPIVERSION} --enable-mpi-java --with-cuda=${INSTALLPREFIX}/cuda-${CUDAVERSION}/linux-x86_64 --without-ofi --without-verbs --without-psm2 --with-devel-headers --enable-mpi-cxx --enable-mpi-fortran ${CONFIGUREADD}
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
sed -e "s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g" /scripts/openmpi/inc/setupmpi.sh > /chroot/${SRCDIRECTORY}/${INSTALLPREFIX}/openmpi-${OPENMPIVERSION}/setupmpi.sh
sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment > /chroot/${SRCDIRECTORY}/${MODULESDIR}/${SRCDIRECTORY}-${VERSION}

# Build and send the deb file to /pkgs
mkdir -p /pkgs/${CODENAME}
cd /chroot/
dpkg-deb -b ${SRCDIRECTORY} /pkgs/${CODENAME}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - INSTALL DEBIAN PACKAGE"
echo "# # # # #"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  /pkgs/${CODENAME}/${PKGNAME}_${VERSION}-${RELEASE}_amd64.deb

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - FINAL CLEANUP"
echo "# # # # #"

# Cleanup of flat source files
rm -rf /src/${SRCDIRECTORY}/${SRCDIRECTORY}-${VERSION} /chroot/${SRCDIRECTORY}