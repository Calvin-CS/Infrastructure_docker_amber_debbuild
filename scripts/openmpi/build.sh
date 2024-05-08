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
echo "OPENMPIMAJORVERSION: $OPENMPIMAJORVERSION"

# Variables you shouldn't change
# ###################################################
PKGNAME=openmpi-amberredist
SRCDIRECTORY=openmpi
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)

# Download URL
URL="https://download.open-mpi.org/release/open-mpi/v${OPENMPIMAJORVERSION}/openmpi-${OPENMPIVERSION}.tar.gz"

# Check to see if source is extracted, if not, extract it
if ! test -d /src/openmpi; then
  echo "Making openmpi src directory."
  mkdir /src/openmpi
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

# Requires
if test -f /scripts/openmpi/packages.dep; then
	DEPFILES=/scripts/openmpi/packages.dep
	if test -f /scripts/openmpi/packages.dep.${CODENAME}; then
		DEPFILES="$DEPFILES /scripts/openmpi/packages.dep.${CODENAME}"
	fi
else
	if test -f /scripts/openmpi/packages.dep.${CODENAME}; then
		DEPFILES="/scripts/openmpi/packages.dep.${CODENAME}"
	fi
fi

REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
echo "Package requirements: ${REQUIRES}"

# Load required environment modules -- CUDA
module purge
module load cuda-${CUDAVERSION}

# Checkinstall build script
cd /src/openmpi/openmpi-${OPENMPIVERSION}
make clean
./configure --prefix=${INSTALLPREFIX}/openmpi-${OPENMPIVERSION} --enable-mpi-java --with-cuda=${INSTALLPREFIX}/cuda-${CUDAVERSION}/linux-x86_64 --without-ofi --without-verbs --without-psm2 --with-devel-headers --enable-mpi-cxx --enable-mpi-fortran --with-pmix=/usr/lib/x86_64-linux-gnu/pmix2
make -j${NPROC}

# Checkinstall go go
echo "$PKGNAME:$OPENMPIVERSION:$RELEASE:$MAINTAINEREMAIL:$REQUIRES:$CODENAME:$INSTALLPREFIX/openmpi-$OPENMPIVERSION:$MODULESDIR/openmpi-$OPENMPIVERSION"
checkinstall  \
	-D -y \
	-A amd64 \
	--pkgname=$PKGNAME \
	--pkgversion=$OPENMPIVERSION \
	--pkgrelease=$RELEASE \
	--maintainer=$MAINTAINEREMAIL \
	--requires=$REQUIRES \
	--strip=yes \
	--stripso=yes \
	--reset-uids=yes \
	--pakdir=/pkgs/$CODENAME \
	--install=yes \
	--exclude=/src/openmpi/ \
	--include=$INSTALLPREFIX/openmpi-$OPENMPIVERSION \
	--include=$MODULESDIR/openmpi-$OPENMPIVERSION \
	--backup \
	--fstrans \
	/scripts/openmpi/install.sh


# Final cleanup of unpacked source files
rm -rf /src/openmpi/openmpi-${OPENMPIVERSION}