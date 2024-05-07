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
PKGNAME=cuda-redist
SRCDIRECTORY=cuda
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)

# Download URL
URL=https://raw.githubusercontent.com/NVIDIA/build-system-archive-import-examples/main/parse_redist.py

# Check to see if source is extracted, if not, extract it
if ! test -d /src/cuda; then
  echo "cuda - Making cuda src directory."
  mkdir /src/cuda
else
  echo "cuda - src/cuda exists."
fi

# Check if download script exists, if NOT, download it
if ! test -f /src/cuda/parse_redist.py; then
  echo "cuda - Downloading source for CUDA parse_redist.py."
  wget ${URL} -O /src/cuda/parse_redist.py
else
  echo "cuda - parse_redist.py exists."
fi

# Requires
if test -f /scripts/cuda/packages.dep; then
	DEPFILES=/scripts/cuda/packages.dep
	if test -f /scripts/cuda/packages.dep.${CODENAME}; then
		DEPFILES="$DEPFILES /scripts/cuda/packages.dep.${CODENAME}"
	fi
	REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
else
	if test -f /scripts/cuda/packages.dep.${CODENAME}; then
		DEPFILES="/scripts/cuda/packages.dep.${CODENAME}"
		REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
	else
		DEPFILES=
		REQUIRES=
	fi
fi

echo "cuda - Package requirements: ${REQUIRES}"

# Checkinstall build script
cd /src/$SRCDIRECTORY

# Checkinstall go go
checkinstall \
	-D -y \
	-A amd64 \
	--pkgname=$PKGNAME \
	--pkgversion=$CUDAVERSION \
	--pkgrelease=$RELEASE \
	--maintainer=$MAINTAINEREMAIL \
	--requires=$REQUIRES \
	--strip=yes \
	--stripso=yes \
	--reset-uids=yes \
	--pakdir=/pkgs/$CODENAME \
	--install=yes \
	--exclude=/src/cuda/ \
	--include=$INSTALLPREFIX/cuda-$CUDAVERSION \
	--include=$MODULESDIR/cuda-$CUDAVERSION \
	/scripts/cuda/install.sh

# Final cleanup of unpacked source files
rm -rf /src/cuda/*.tar.xz /src/cuda/*.tgz