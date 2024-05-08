#!/usr/bin/bash

# This is for boost
# https://www.boost.org/
# Use ONLY official releases
# Tested: 1.85.0

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

# Variables you shouldn't change
# ###################################################
PKGNAME=boost-amberredist
SRCDIRECTORY=boost
VERSION=$BOOSTVERSION
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)
SECTION=libs


###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Downloads"
echo "# # # # #"

# Download URL
BOOSTVERSIONUNDERSCORE=$(sed "s:\.:_:g" <<< $BOOSTVERSION)
URL="https://boostorg.jfrog.io/artifactory/main/release/${BOOSTVERSION}/source/boost_${BOOSTVERSIONUNDERSCORE}.tar.gz"

# Check to see if source is extracted, if not, extract it
if ! test -d /src/${SRCDIRECTORY}; then
  echo "${SRCDIRECTORY} - Making ${SRCDIRECTORY} src directory."
  mkdir /src/${SRCDIRECTORY}
else
  echo "${SRCDIRECTORY} - src/${SRCDIRECTORY} exists."
fi

# Check if src tar.gz exists, if NOT, download it
if ! test -f /src/boost/boost-${BOOSTVERSIONUNDERSCORE}.tar.gz; then
  echo "Downloading source for boost boost-${BOOSTVERSIONUNDERSCORE}.tar.gz"
  wget ${URL} -O /src/boost/boost-${BOOSTVERSIONUNDERSCORE}.tar.gz
fi

# Check if sources have been unzipped
if ! test -d /src/boost/boost_${BOOSTVERSIONUNDERSCORE}; then
  echo "Unzipping source for boost boost-${BOOSTVERSIONUNDERSCORE}.tar.gz"
  cd /src/boost/
  tar zxfv boost-${BOOSTVERSIONUNDERSCORE}.tar.gz
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

# Load required environment modules -- CUDA and OpenMPI
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIVERSION}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Sources BUILD"
echo "# # # # #"

# build it
cd /src/boost/boost_${BOOSTVERSIONUNDERSCORE}
./bootstrap.sh --prefix=${INSTALLPREFIX}/${SRCDIRECTORY}-${BOOSTVERSION}
echo "using mpi ;" >> tools/build/src/user-config.jam
./b2 --prefix=${INSTALLPREFIX}/${SRCDIRECTORY}-${BOOSTVERSION} --with=all -j${NPROC}
./b2 install --prefix=${INSTALLPREFIX}/${SRCDIRECTORY}-${BOOSTVERSION} --with=all -j${NPROC}

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
# N/A for libboost

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