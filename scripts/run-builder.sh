#!/usr/bin/bash

# Welcome
echo "##############################################################"
echo "# Welcome to the Amber/AmberTools deb builder for Ubuntu!"
echo "#"
echo "# These scripts are for system administration convienence,"
echo "# and all licenses, terms and conditions, and legal"
echo "# responsibilities are accepted and bound to the person"
echo "# running these scripts. Use this builder at your own RISK."
echo "#"
echo "# Get some coffee or go out for lunch -- this is gonna take"
echo "# a LOOOOONG TIME...."
echo "##############################################################"

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh

# First off, check to make sure that we have accepted all license terms and non-default
# values are set for key variables
if [ -z "${MAINTAINERNAME}" ]; then
    echo "Please edit variables.env to set your MAINTAINERNAME."
    exit 1
elif [[ $MAINTAINERNAME == 'My Name' ]]; then
    echo "Please edit variables.env to set your MAINTAINERNAME."
    exit 1
elif [ -z "${MAINTAINEREMAIL}" ]; then
    echo "Please edit variables.env to set your MAINTAINER email address."
    exit 1
elif [[ $MAINTAINEREMAIL == 'myemail@mydomain.com' ]]; then
    echo "Please edit variables.env to set your MAINTAINER email address."
    exit 1
elif [ -z "${MAINTAINERINSTITUTION}" ]; then
    echo "Please edit variables.env to set your MAINTAINERINSTITUTION."
    exit 1
elif [[ $MAINTAINERINSTITUTION == 'My Institution' ]]; then
    echo "Please edit variables.env to set your MAINTAINERINSTITUTION."
    exit 1
elif [ -z "${AMBERTOOLSACCEPTLICENSE}" ]; then
    echo "Please accept the AmberTools license by setting AMBERTOOLSACCEPTLICENSE=TRUE in variables.env"
    exit 1
elif [[ $AMBERTOOLSACCEPTLICENSE != 'TRUE' ]]; then
    echo "Please accept the AmberTools license by setting AMBERTOOLSACCEPTLICENSE=TRUE in variables.env"
    exit 1
fi

CODENAME=$(lsb_release -cs)

# Refresh APT cache
apt-get update -y

SUBBUILDS=("cuda" "openmpi" "libboost" "plumed" "amber")
for build in ${SUBBUILDS[@]}
do

    # echo out some steps
    echo "##############################################################"
    echo "# ${build}"
    echo "##############################################################"
    echo ""

    # First, do the dependencies
    echo "${build} - Installing generic dependencies"
    if test -f /scripts/${build}/packages.dep; then
        echo " -- installing from /scripts/${build}/packages.dep"
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            `cat /scripts/${build}/packages.dep | uniq | xargs` 
    fi

    echo "${build} - Installing OS specific dependencies"
    if test -f /scripts/${build}/packages.dep.${CODENAME}; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            `cat /scripts/${build}/packages.dep.${CODENAME} | uniq | xargs`
    fi

    # Run the build
    echo "${build} - Running build.sh script to build packages"
    cd /scripts/${build}
    ./build.sh
done

# Output what I did!
echo "##############################################################"
echo "# BUILD COMPLETE!"
echo "# -----------------------------------------------------------"
echo "# Debian packages can be found in: ./pkgs/${CODENAME}"
echo "# All these packages are required to install the amber package."
echo "# Have a nice day!"
echo "##############################################################"
ls -al /pkgs/${CODENAME}/*.deb