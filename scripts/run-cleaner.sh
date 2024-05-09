#!/usr/bin/bash

# Welcome
echo "##############################################################"
echo "# Welcome to the Amber/AmberTools deb cleaner for Ubuntu!"
echo "##############################################################"

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

CODENAME=$(lsb_release -cs)

SUBBUILDS=("cuda" "openmpi" "boost" "plumed" "amber")
for build in ${SUBBUILDS[@]}
do

    # echo out some steps
    echo "##############################################################"
    echo "# Removing sources for ${build}"
    echo "##############################################################"
    echo ""

    # remove /src/${build}
    rm -rf /src/${build}
done

# remove pkgs
echo "##############################################################"
echo "# Removing packages for ${CODENAME}"
echo "##############################################################"
echo ""
rm -rf /pkgs/${CODENAME}