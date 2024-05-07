#!/bin/bash

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

echo "PLUMED Version: ${PLUMEDVERSION}"

# Cleanup INSTALLPREFIX directory if it exists
if test -d ${INSTALLPREFIX}/plumed-${PLUMEDVERSION}; then
    echo "Removing old ${INSTALLPREFIX}/plumed-${PLUMEDVERSION}..."
    rm -rf ${INSTALLPREFIX}/plumed-${PLUMEDVERSION}
fi

# Load required environment modules -- CUDA and OpenMPI
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIEXACTVERSION}

# run the make install
cd /src/plumed/plumed-${PLUMEDVERSION}
make install

# make the updated modules file
sed -e "s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:OPENMPIEXACTVERSION:${OPENMPIEXACTVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g" /scripts/plumed/inc/plumed-environment > ${MODULESDIR}/plumed-${PLUMEDVERSION}
