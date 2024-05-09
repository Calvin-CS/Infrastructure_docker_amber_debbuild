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
SRCDIRECTORY=amber
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
if ! test -d /src/${SRCDIRECTORY}; then
  echo "Making ${SRCDIRECTORY} src directory."
  mkdir /src/${SRCDIRECTORY}
fi

# Download and extract AmberTools
# Check if AmberTools src tar.bz2 exists, if NOT, download it
if ! test -f /src/${SRCDIRECTORY}/AmberTools${AMBERTOOLSVERSION}.tar.bz2; then
  echo "Downloading source for AmberTools AmberTools${AMBERTOOLSVERSION}.tar.bz2"
  wget ${AMBERTOOLSURL} --post-data="${AMBERTOOLSFORMDATA}" -O /src/amber/AmberTools${AMBERTOOLSVERSION}.tar.bz2
fi

# Check if sources have been unzipped
if ! test -f /src/${SRCDIRECTORY}/.AmberToolsUnzipped; then
  echo "Unzipping source for AmberTools AmberTools${AMBERTOOLSVERSION}.tar.bz2"
  cd /src/${SRCDIRECTORY}/
  tar xfjpv AmberTools${AMBERTOOLSVERSION}.tar.bz2
  touch .AmberToolsUnzipped
fi

# Download and extract Amber
# NOTE: Depends on license agreement!
echo "Amber accept license: ${AMBERACCEPTLICENSE}"
if [ ! -z "${AMBERACCEPTLICENSE}" ]; then
    if [[ $AMBERACCEPTLICENSE == 'TRUE' ]]; then

        # Check if Amber src tar.bz2 exists, if NOT, download it
        if ! test -f /src/${SRCDIRECTORY}/Amber${AMBERVERSION}.tar.bz2; then
            echo "Downloading source for Amber Amber${AMBERVERSION}.tar.bz2"
            wget ${AMBERURL} --post-data="${AMBERFORMDATA}" -O /src/${SRCDIRECTORY}/Amber${AMBERVERSION}.tar.bz2
        fi

        # Check if sources have been unzipped
        if ! test -f /src/${SRCDIRECTORY}/.AmberUnzipped; then
            echo "Unzipping source for Amber Amber${AMBERTOOLSVERSION}.tar.bz2"
            cd /src/${SRCDIRECTORY}/
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
echo "# ${SRCDIRECTORY} - Load required module environment"
echo "# # # # #"
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIVERSION}
module load plumed-${PLUMEDVERSION}

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - Sources BUILD"
echo "# # # # #"

# Copy in a modified run_cmake file from /scripts/amber/inc/
rm -f /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src/build/run_cmake
if test -f /scripts/${SRCDIRECTORY}/inc/run_cmake.${CODENAME}; then
	  sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/run_cmake.${CODENAME} > /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src/build/run_cmake
else
    sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/run_cmake > /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src/build/run_cmake
fi
chmod 0755 /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src/build/run_cmake

# build script
cd /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src/build
echo "y" | ./clean_build
./run_cmake
make -j${NPROC} install

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - DEBIAN PACKAGE CREATION"
echo "# # # # # "

# Make a DEBIAN package chroot environment, and populate the control file
mkdir -p /chroot/${PKGNAME}/DEBIAN /chroot/${PKGNAME}/${MODULESDIR} /chroot/${PKGNAME}/etc/profile.d/
sed -e "s:PKGNAME:${PKGNAME}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:VERSION:${VERSION}:g; s:RELEASE:${RELEASE}:g; s:MAINTAINERNAME:${MAINTAINERNAME}:g; s:MAINTAINEREMAIL:${MAINTAINEREMAIL}:g; s:REQUIRES:${REQUIRES}:g; s:SECTION:${SECTION}:g" /scripts/control-template > /chroot/${PKGNAME}/DEBIAN/control
mkdir -p /chroot/${PKGNAME}/${INSTALLPREFIX}

# mv the source directory
mv ${INSTALLPREFIX}/${PKGNAME} /chroot/${PKGNAME}/${INSTALLPREFIX}/

# make the updated modules file
if test -f /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment.${CODENAME}; then
  sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment.${CODENAME} > /chroot/${PKGNAME}/${MODULESDIR}/${PKGNAME}
else
  sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:BOOSTVERSION:${BOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/${SRCDIRECTORY}/inc/${SRCDIRECTORY}-environment > /chroot/${PKGNAME}/${MODULESDIR}/${PKGNAME}
fi

# add a profile for amber to autoload modules
cp /scripts/${SRCDIRECTORY}/inc/amber-profile.sh /chroot/${PKGNAME}/etc/profile.d/

# Build and send the deb file to /pkgs
mkdir -p /pkgs/${CODENAME}
cd /chroot/
ls -R /chroot/
cat /chroot/${PKGNAME}/DEBIAN/control
dpkg-deb -b ${PKGNAME} /pkgs/${CODENAME}

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
module load ${PKGNAME}
module avail

###########################
echo "# # # # #"
echo "# ${SRCDIRECTORY} - FINAL CLEANUP"
echo "# # # # #"

# Cleanup of flat source files
rm -rf /src/${SRCDIRECTORY}/amber${AMBERVERSION}_src /src/${SRCDIRECTORY}/.AmberToolsUnzipped /src/${SRCDIRECTORY}/.AmberUnzipped /chroot/${PKGNAME}
