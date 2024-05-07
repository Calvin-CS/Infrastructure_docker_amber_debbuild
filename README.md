# Infrastructure_docker_amber_debbuild

This repo is a collection of scripts that makes building
Amber (https://ambermd.org/) less painful for the Ubuntu
operating system.

It uses Docker to pull down Ubuntu base images, then uses
debian packaging tools (specifically checkinstall) to
create a series of .deb files for Amber and it's 
dependencies. 

What does it do?
- Downloads, compiles and makes .deb files for the 
  following dependencies:
  : NVIDIA CUDA toolkit - https://developer.nvidia.com/cuda-toolkit
    Packaged created: cuda-redist
  : OpenMPI - https://www.open-mpi.org/
    Package created: openmpi-redist
  : Libboost - https://www.boost.org/
    Package created: libboost-redist
  : Plumed - https://www.plumed.org/
    Package created: plumed-redist
- Downloads, compiles, and makes .deb files for
  : AmberTools - https://ambermd.org/
    Amber - https://ambermd.org (optional)
    Package created: amber

Frequently Asked Questions:
- How do I start / use this?
  1. Install Docker
  2. Open scripts/variables.env and edit the the MAINTAINER variables,
     and the LICENSE acceptance variables.
  3. Decide on what Ubuntu version you will be building:
     focal - Ubuntu 20.04 LTS
     jammy - Ubuntu 22.04 LTS
     noble - Ubuntu 24.04 LTS
  4. Build the appropriate Docker image to build your packages
     ./build.sh <oscodename>

     Example: for Ubuntu 24.04 LTS (noble), run:
     ./build.sh noble
  5. Start the build process
     ./run.sh <oscodename>

     Example: for Ubuntu 24.04 LTS (noble), run:
     ./run.sh noble
  
  This process will take a lot of time (hours) depending on your
  hardware -- my workstation takes about 3 hours to make all the
  packages.

- Where are my built .deb files?
  pkgs/<oscodename>/

- Why don't you use Ubuntu's built-in CUDA, OpenMPI, Libboost?
  Many reasons. I started this project because the built-in Ubuntu 24.04
  LTS version would not compile with Amber, and I needed a different
  CUDA version that would work correctly. For MPI, my particular use
  case requires the enabling of Java within MPI, so I needed to compile
  from scratch. Basically, in order to make these packages work as
  broadly as possible I detached key dependencies from OS requirements.

- What if I don't like that?
  Don't use this builder then -- problem solved! ;)

- What Ubuntu operating systems do this work for?
  20.04 LTS (focal), 22.04 LTS (jammy), 24.04 LTS (noble)

- Can I use different versions than the defaults? 
  Yep -- I just haven't tested most of them!