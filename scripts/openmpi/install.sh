#!/bin/bash

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

echo "OpenMPI Version: ${OPENMPIEXACTVERSION}"

# Cleanup INSTALLPREFIX directory if it exists
if test -d ${INSTALLPREFIX}/openmpi-${OPENMPIEXACTVERSION}; then
    echo "Removing old ${INSTALLPREFIX}/openmpi-${OPENMPIEXACTVERSION}..."
    rm -rf ${INSTALLPREFIX}/openmpi-${OPENMPIEXACTVERSION}
fi

# run the make install
cd /src/openmpi/openmpi-${OPENMPIEXACTVERSION}
make install

# make the updated modules file
sed -e "s:OPENMPIEXACTVERSION:${OPENMPIEXACTVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g" /scripts/openmpi/inc/setupmpi.sh > ${INSTALLPREFIX}/openmpi-${OPENMPIEXACTVERSION}/setupmpi.sh
sed -e "s:OPENMPIEXACTVERSION:${OPENMPIEXACTVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/openmpi/inc/openmpi-environment > ${MODULESDIR}/openmpi-${OPENMPIEXACTVERSION}
