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
PKGNAME=amber${AMBERVERSION}
SRCDIRECTORY=amber${AMBERVERSION}
VERSION=${AMBERVERSION}
RELEASE=$(date +%Y%m%d%H%M)
CODENAME=$(lsb_release -cs)
NPROC=$(nproc)
SECTION=science


###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Downloads"
echo "# # # # #"

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
echo "# ${SRCDIRECTORY} - Load required environment"
echo "# # # # #"

# Load required environment modules -- CUDA, OpenMPI, Plumed
module avail
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIVERSION}
module load plumed-${PLUMEDVERSION}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Sources BUILD"
echo "# # # # #"

# Copy in a modified run_cmake file from /scripts/amber/inc/
rm -f /src/amber/amber${AMBERVERSION}_src/build/run_cmake
if test -f /scripts/amber/inc/run_cmake.${CODENAME}; then
	sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/amber/inc/run_cmake.${CODENAME} > /src/amber/amber${AMBERVERSION}_src/build/run_cmake
else
    sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/amber/inc/run_cmake > /src/amber/amber${AMBERVERSION}_src/build/run_cmake
fi
chmod 0755 /src/amber/amber${AMBERVERSION}_src/build/run_cmake

# build script
cd /src/amber/amber${AMBERVERSION}_src/build
echo "y" | ./clean_build
./run_cmake
make -j${NPROC} install

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
sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment > /chroot/${SRCDIRECTORY}/${MODULESDIR}/${SRCDIRECTORY}

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
rm -rf /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src /chroot/${SRCDIRECTORY}
