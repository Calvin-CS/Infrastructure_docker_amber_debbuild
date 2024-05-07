#!/bin/bash

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# variables
echo "libboost Version: ${LIBBOOSTVERSION}"
LIBBOOSTVERSIONUNDERSCORE=$(sed "s:\.:_:g" <<< $LIBBOOSTVERSION)
NPROC=$(nproc)

# Cleanup INSTALLPREFIX directory if it exists
if test -d ${INSTALLPREFIX}/libboost-${LIBBOOSTVERSION}; then
    echo "Removing old ${INSTALLPREFIX}/libboost-${LIBBOOSTVERSION}..."
    rm -rf ${INSTALLPREFIX}/libboost-${LIBBOOSTVERSION}
fi

# Load required environment modules -- CUDA and OpenMPI
module purge
module load cuda-${CUDAVERSION}
module load openmpi-${OPENMPIEXACTVERSION}

# run the make install
cd /src/libboost/boost_${LIBBOOSTVERSIONUNDERSCORE}
./b2 install --prefix=${INSTALLPREFIX}/boost-${LIBBOOSTVERSION} --with=all -j${NPROC}
