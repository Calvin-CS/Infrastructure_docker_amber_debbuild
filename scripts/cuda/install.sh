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

# Check for Ubuntu 24.04 workaround -- if miniconda is installed, use that 
# for Python instead of built in python3
if [ -d /opt/conda ]; then
  . /opt/conda/etc/profile.d/conda.sh
  conda activate base
fi

# run the redist script
cd /tmp/cuda/flat
mkdir -p ${INSTALLPREFIX}/cuda-${CUDAVERSION}
rsync -av linux-x86_64 ${INSTALLPREFIX}/cuda-${CUDAVERSION}/

# make the updated modules file
sed -e "s:CUDAVERSION:${CUDAVERSION}:g; s:INSTALLPREFIX:${INSTALLPREFIX}:g" /scripts/cuda/inc/cuda-environment > ${MODULESDIR}/cuda-${CUDAVERSION}
