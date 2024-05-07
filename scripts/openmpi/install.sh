#!/bin/bash

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

echo "OpenMPI Version: ${OPENMPIVERSION}"

# Figure out the major version of OPENMPI, based off of OPENMPIVERSION
OPENMPIMAJORVERSION=$(echo $OPENMPIVERSION | awk -F. '{print $1 "." $2;}' -)
echo "OPENMPIMAJORVERSION: $OPENMPIMAJORVERSION"

# Cleanup INSTALLPREFIX directory if it exists
if test -d ${INSTALLPREFIX}/openmpi-${OPENMPIVERSION}; then
    echo "Removing old ${INSTALLPREFIX}/openmpi-${OPENMPIVERSION}..."
    rm -rf ${INSTALLPREFIX}/openmpi-${OPENMPIVERSION}
fi

# run the make install
cd /src/openmpi/openmpi-${OPENMPIVERSION}
make install

# make the updated modules file
sed -e "s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g" /scripts/openmpi/inc/setupmpi.sh > ${INSTALLPREFIX}/openmpi-${OPENMPIVERSION}/setupmpi.sh
sed -e "s:OPENMPIVERSION:${OPENMPIVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/openmpi/inc/openmpi-environment > ${MODULESDIR}/openmpi-${OPENMPIVERSION}
