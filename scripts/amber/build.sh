#!/usr/bin/bash

# This is for Amber
# https://ambermd.org/
# Use ONLY official releases and MATCHING versions
# Tested: 
#   AmberTools24, Amber24

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

# Variables you shouldn't change
# ###################################################
PKGNAME=amber
SRCDIRECTORY=amber${AMBERVERSION}_src
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)

# Download URL
# AmberTools: POST form to - https://ambermd.org/cgi-bin/AmberTools24-get.pl
# enctype="multipart/form-data"
# Form values: Name (max 50), Institution (max 50), Submit=' Download '

AMBERTOOLSFORMDATA=Name=$(printf %s "${MAINTAINERNAME}"|jq -sRr @uri)\&Institution=$(printf %s "${MAINTAINERINSTITUTION}"|jq -sRr @uri)\&SUBMIT=$(printf %s ' Download '|jq -sRr @uri)
AMBERTOOLSURL=https://ambermd.org/cgi-bin/AmberTools${AMBERTOOLSVERSION}-get.pl

# Amber: POST form to - https://ambermd.org/cgi-bin/Amber24free-get.pl
# enctype="multipart/form-data"
# Form values: Name (max 50), Institution (max 50), Submit=' Accept non-commercial license and download '
AMBERFORMDATA=Name=$(printf %s "${MAINTAINERNAME}"|jq -sRr @uri)\&Institution=$(printf %s "${MAINTAINERINSTITUTION}"|jq -sRr @uri)\&SUBMIT=$(printf %s ' Accept non-commercial license and download '|jq -sRr @uri)
AMBERURL=https://ambermd.org/cgi-bin/Amber${AMBERVERSION}free-get.pl

# Check to see if source is extracted, if not, extract it
if ! test -d /src/amber; then
  echo "Making amber src directory."
  mkdir /src/amber
fi

# Download and extract AmberTools
# Check if AmberTools src tar.bz2 exists, if NOT, download it
if ! test -f /src/amber/AmberTools${AMBERTOOLSVERSION}.tar.bz2; then
  echo "Downloading source for AmberTools AmberTools${AMBERTOOLSVERSION}.tar.bz2"
  wget ${AMBERTOOLSURL} --post-data="${AMBERTOOLSFORMDATA}" -O /src/amber/AmberTools${AMBERTOOLSVERSION}.tar.bz2
fi

# Check if sources have been unzipped
if ! test -f /src/amber/.AmberToolsUnzipped; then
  echo "Unzipping source for AmberTools AmberTools${AMBERTOOLSVERSION}.tar.bz2"
  cd /src/amber/
  tar xfjpv AmberTools${AMBERTOOLSVERSION}.tar.bz2
  touch .AmberToolsUnzipped
fi

# Download and extract Amber
# NOTE: Depends on license agreement!
echo "Amber accept license: ${AMBERACCEPTLICENSE}"
if [ ! -z "${AMBERACCEPTLICENSE}" ]; then
    if [[ $AMBERACCEPTLICENSE == 'TRUE' ]]; then

        # Check if Amber src tar.bz2 exists, if NOT, download it
        if ! test -f /src/amber/Amber${AMBERVERSION}.tar.bz2; then
            echo "Downloading source for Amber Amber${AMBERVERSION}.tar.bz2"
            wget ${AMBERURL} --post-data="${AMBERFORMDATA}" -O /src/amber/Amber${AMBERVERSION}.tar.bz2
        fi

        # Check if sources have been unzipped
        if ! test -f /src/amber/.AmberUnzipped; then
            echo "Unzipping source for Amber Amber${AMBERTOOLSVERSION}.tar.bz2"
            cd /src/amber/
            tar xfjpv Amber${AMBERVERSION}.tar.bz2
            touch .AmberUnzipped
        fi
    else
        echo "AMBERACCEPTLICENSE is NOT set to TRUE! Skipping download and extraction of Amber${AMBERVERSION}!"
    fi
else
    echo "AMBERACCEPTLICENSE is NOT SET! Skipping download and extraction of Amber${AMBERVERSION}!"
fi

# Requires
if test -f /scripts/amber/packages.dep; then
	DEPFILES=/scripts/amber/packages.dep
	if test -f /scripts/amber/packages.dep.${CODENAME}; then
		DEPFILES="$DEPFILES /scripts/amber/packages.dep.${CODENAME}"
	fi
else
	if test -f /scripts/amber/packages.dep.${CODENAME}; then
		DEPFILES="/scripts/amber/packages.dep.${CODENAME}"
	fi
fi

REQUIRES=$(cat ${DEPFILES} | xargs | tr " " ",")
echo "Package requirements: ${REQUIRES}"

# Load required environment modules -- CUDA, OpenMPI, Plumed
module avail
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIEXACTVERSION}
module load plumed-${PLUMEDVERSION}
env

# Copy in a modified run_cmake file from /scripts/amber/inc/
rm -f /src/amber/amber${AMBERVERSION}_src/build/run_cmake
if test -f /scripts/amber/inc/run_cmake.${CODENAME}; then
	sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:LIBBOOSTVERSION:${LIBBOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIEXACTVERSION:${OPENMPIEXACTVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/amber/inc/run_cmake.${CODENAME} > /src/amber/amber${AMBERVERSION}_src/build/run_cmake
else
    sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:LIBBOOSTVERSION:${LIBBOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIEXACTVERSION:${OPENMPIEXACTVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/amber/inc/run_cmake > /src/amber/amber${AMBERVERSION}_src/build/run_cmake
fi
chmod 0755 /src/amber/amber${AMBERVERSION}_src/build/run_cmake

# Checkinstall build script
cd /src/amber/amber${AMBERVERSION}_src/build
echo "y" | ./clean_build
./run_cmake
make -j${NPROC}

# # Checkinstall go go
checkinstall  \
	-D -y \
	-A amd64 \
	--pkgname=$PKGNAME \
	--pkgversion=$AMBERVERSION \
	--pkgrelease=$RELEASE \
	--maintainer=$MAINTAINEREMAIL \
	--requires=$REQUIRES \
	--strip=yes \
	--stripso=yes \
	--reset-uids=yes \
	--pakdir=/pkgs/$CODENAME \
	--install=no \
	--exclude=/src/amber/ \
	--include=$INSTALLPREFIX/amber$AMBERVERSION \
	/scripts/amber/install.sh

# Final cleanup of unpacked source files
rm -rf /src/amber/amber${AMBERVERSION}