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
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)

# Download URL
URL=https://github.com/plumed/plumed2/releases/download/v${PLUMEDVERSION}/plumed-src-${PLUMEDVERSION}.tgz

# Check to see if source is extracted, if not, extract it
if ! test -d /src/plumed; then
  echo "Making plumed src directory."
  mkdir /src/plumed
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

# Requires
if test -f /scripts/plumed/packages.dep; then
	DEPFILES=/scripts/plumed/packages.dep
	if test -f /scripts/plumed/packages.dep.${CODENAME}; then
		DEPFILES="$DEPFILES /scripts/plumed/packages.dep.${CODENAME}"
	fi
else
	if test -f /scripts/plumed/packages.dep.${CODENAME}; then
		DEPFILES="/scripts/plumed/packages.dep.${CODENAME}"
	fi
fi

REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
echo "Package requirements: ${REQUIRES}"

# Load required environment modules -- CUDA and OpenMPI
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIVERSION}

# Checkinstall build script
cd /src/plumed/plumed-${PLUMEDVERSION}
./configure --prefix=${INSTALLPREFIX}/plumed-${PLUMEDVERSION}
make -j${NPROC}


# Checkinstall go go
checkinstall  \
	-D -y \
	-A amd64 \
	--pkgname=$PKGNAME \
	--pkgversion=$PLUMEDVERSION \
	--pkgrelease=$RELEASE \
	--maintainer=$MAINTAINEREMAIL \
	--requires=$REQUIRES \
	--strip=yes \
	--stripso=yes \
	--reset-uids=yes \
	--pakdir=/pkgs/$CODENAME \
	--install=yes \
	--exclude=/src/plumed/ \
	--include=$INSTALLPREFIX/boost-$PLUMEDVERSION \
	/scripts/plumed/install.sh

# Final cleanup of unpacked source files
rm -rf /src/plumed/plumed-${PLUMEDVERSION}