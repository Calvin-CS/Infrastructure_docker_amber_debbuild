#!/bin/bash

echo "CUDA Version: ${CUDAVERSION}"

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Cleanup INSTALLPREFIX directory if it exists
if test -d ${INSTALLPREFIX}/cuda-${CUDAVERSION}; then
    echo "Removing old ${INSTALLPREFIX}/cuda-${CUDAVERSION}..."
    rm -rf ${INSTALLPREFIX}/cuda-${CUDAVERSION}
fi

# run the redist script
python3 parse_redist.py --product cuda --os linux --arch x86_64 --output ${INSTALLPREFIX}/cuda-$CUDAVERSION --label $CUDAVERSION
#rm *.xz

# make the updated modules file
sed -e "s:CUDAVERSION:${CUDAVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g" /scripts/cuda/inc/cuda-environment > ${MODULESDIR}/cuda-${CUDAVERSION}
