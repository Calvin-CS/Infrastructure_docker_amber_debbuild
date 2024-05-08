#!/usr/bin/bash

# Read in variables
set -a
source <(cat /scripts/variables.env | \
    sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +a

# Source modules
. /etc/profile.d/modules.sh


CODENAME=$(lsb_release -cs)

# First off, check to make sure that we have accepted all license terms and non-default
# values are set for key variables
if [ $CODENAME == 'focal' ]; then
    echo "i'm focal"
    exit 1
else
    echo "not focal"
fi
