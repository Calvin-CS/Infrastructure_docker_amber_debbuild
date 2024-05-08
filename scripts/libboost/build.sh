#!/usr/bin/bash

# This is for libboost
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
PKGNAME=libboost-amberredist
SRCDIRECTORY=libboost
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)

# Download URL
LIBBOOSTVERSIONUNDERSCORE=$(sed "s:\.:_:g" <<< $LIBBOOSTVERSION)
URL="https://boostorg.jfrog.io/artifactory/main/release/${LIBBOOSTVERSION}/source/boost_${LIBBOOSTVERSIONUNDERSCORE}.tar.gz"

# Check to see if source is extracted, if not, extract it
if ! test -d /src/libboost; then
  echo "Making libboost src directory."
  mkdir /src/libboost
fi

# Check if src tar.gz exists, if NOT, download it
if ! test -f /src/libboost/libboost-${LIBBOOSTVERSIONUNDERSCORE}.tar.gz; then
  echo "Downloading source for libboost boost-${LIBBOOSTVERSIONUNDERSCORE}.tar.gz"
  wget ${URL} -O /src/libboost/libboost-${LIBBOOSTVERSIONUNDERSCORE}.tar.gz
fi

# Check if sources have been unzipped
if ! test -d /src/libboost/boost_${LIBBOOSTVERSIONUNDERSCORE}; then
  echo "Unzipping source for libboost boost-${LIBBOOSTVERSIONUNDERSCORE}.tar.gz"
  cd /src/libboost/
  tar zxfv libboost-${LIBBOOSTVERSIONUNDERSCORE}.tar.gz
fi

# Requires
if test -f /scripts/libboost/packages.dep; then
	DEPFILES=/scripts/libboost/packages.dep
	if test -f /scripts/libboost/packages.dep.${CODENAME}; then
		DEPFILES="$DEPFILES /scripts/libboost/packages.dep.${CODENAME}"
	fi
else
	if test -f /scripts/libboost/packages.dep.${CODENAME}; then
		DEPFILES="/scripts/libboost/packages.dep.${CODENAME}"
	fi
fi

REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
echo "Package requirements: ${REQUIRES}"

# Load required environment modules -- CUDA and OpenMPI
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIVERSION}

# Checkinstall build script
cd /src/libboost/boost_${LIBBOOSTVERSIONUNDERSCORE}
./bootstrap.sh --prefix=${INSTALLPREFIX}/boost-${LIBBOOSTVERSION}
echo "using mpi ;" >> tools/build/src/user-config.jam
./b2 --prefix=${INSTALLPREFIX}/boost-${LIBBOOSTVERSION} --with=all -j${NPROC}

# Checkinstall go go
checkinstall  \
	-D -y \
	-A amd64 \
	--pkgname=$PKGNAME \
	--pkgversion=$LIBBOOSTVERSION \
	--pkgrelease=$RELEASE \
	--maintainer=$MAINTAINEREMAIL \
	--requires=$REQUIRES \
	--strip=yes \
	--stripso=yes \
	--reset-uids=yes \
	--pakdir=/pkgs/$CODENAME \
	--install=yes \
	--exclude=/src/libboost/ \
	--include=$INSTALLPREFIX/boost-$LIBBOOSTVERSION \
	--backup \
	--fstrans \
	/scripts/libboost/install.sh

# Final cleanup of unpacked source files
rm -rf /src/libboost/boost_${LIBBOOSTVERSIONUNDERSCORE}