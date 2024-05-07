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

# Variables you shouldn't change
# ###################################################
PKGNAME=openmpi-redist
SRCDIRECTORY=openmpi
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)

# Download URL
URL="https://download.open-mpi.org/release/open-mpi/v${OPENMPIMAJORVERSION}/openmpi-${OPENMPIEXACTVERSION}.tar.gz"

# Check to see if source is extracted, if not, extract it
if ! test -d /src/openmpi; then
  echo "Making openmpi src directory."
  mkdir /src/openmpi
fi

# Check if src tar.gz exists, if NOT, download it
if ! test -f /src/openmpi/openmpi-${OPENMPIEXACTVERSION}.tar.gz; then
  echo "Downloading source for openmpi openmpi-${OPENMPIEXACTVERSION}.tar.gz"
  wget ${URL} -O /src/openmpi/openmpi-${OPENMPIEXACTVERSION}.tar.gz
fi

# Check if sources have been unzipped
if ! test -d /src/openmpi/openmpi-${OPENMPIEXACTVERSION}; then
  echo "Unzipping source for openmpi openmpi-${OPENMPIEXACTVERSION}.tar.gz"
  cd /src/openmpi/
  tar zxfv openmpi-${OPENMPIEXACTVERSION}.tar.gz
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
cd /src/openmpi/openmpi-${OPENMPIEXACTVERSION}
make clean
./configure --prefix=${INSTALLPREFIX}/openmpi-${OPENMPIEXACTVERSION} --enable-mpi-java --with-cuda=${INSTALLPREFIX}/cuda-${CUDAVERSION}/linux-x86_64 --without-ofi --without-verbs --without-psm2 --with-devel-headers --enable-mpi-cxx --enable-mpi-fortran
make -j${NPROC}

# Checkinstall go go
checkinstall  \
	-D -y \
	-A amd64 \
	--pkgname=$PKGNAME \
	--pkgversion=$OPENMPIEXACTVERSION \
	--pkgrelease=$RELEASE \
	--maintainer=$MAINTAINEREMAIL \
	--requires=$REQUIRES \
	--strip=yes \
	--stripso=yes \
	--reset-uids=yes \
	--pakdir=/pkgs/$CODENAME \
	--install=yes \
	--exclude=/src/openmpi/ \
	--include=$INSTALLPREFIX/openmpi-$OPENMPIEXACTVERSION \
	--include=$MODULESDIR/openmpi-$OPENMPIEXACTVERSION \
	/scripts/openmpi/install.sh

# Final cleanup of unpacked source files
rm -rf /src/openmpi/openmpi-${OPENMPIEXACTVERSION}