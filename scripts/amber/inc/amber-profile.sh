#!/usr/bin/bash

# Amber relies on Environment Modules -- auto load them
# here along with auto-handling of prereq

# automatically load modules
. /etc/profile.d/modules.sh

# automatically load prereq modules
export MODULES_AUTO_HANDLING=1
