#!/bin/bash

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# variables
NPROC=$(nproc)

# Cleanup INSTALLPREFIX directory if it exists
if test -d ${INSTALLPREFIX}/amber${AMBERVERSION}; then
    echo "Removing old ${INSTALLPREFIX}/amber${AMBERVERSION}..."
    rm -rf ${INSTALLPREFIX}/amber${AMBERVERSION}
fi

# Load required environment modules -- CUDA and OpenMPI
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIEXACTVERSION}
module load plumed-${PLUMEDVERSION}

# run the make install
cd /src/amber/amber${AMBERVERSION}_src/build
make -j${NPROC} install

# make the updated modules file
sed -e "s:INSTALLPREFIX:${INSTALLPREFIX}:g; s:AMBERVERSION:${AMBERVERSION}:g; s:LIBBOOSTVERSION:${LIBBOOSTVERSION}:g; s:PLUMEDVERSION:${PLUMEDVERSION}:g; s:OPENMPIEXACTVERSION:${OPENMPIEXACTVERSION}:g; s:CUDAVERSION:${CUDAVERSION}:g"" /scripts/amber/inc/amber-environment > ${MODULESDIR}/amber${AMBERVERSION}
