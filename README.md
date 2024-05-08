# Infrastructure_docker_amber_debbuild

This repo is a collection of scripts that makes building Amber (https://ambermd.org/) less painful for the Ubuntu operating system.


It uses Docker to pull down Ubuntu base images (AMD64), then uses debian packaging tools to create a series of .deb files for Amber and it's dependencies. 

What do these scripts do?

- Downloads, compiles and makes .deb files for the following dependencies for the speicifed Ubuntu version:

  : NVIDIA CUDA toolkit - https://developer.nvidia.com/cuda-toolkit

    Packaged created: cuda-amberredist

  : OpenMPI - https://www.open-mpi.org/

    Package created: openmpi-amberredist

  : Libboost - https://www.boost.org/

    Package created: boost-amberredist

  : Plumed - https://www.plumed.org/

    Package created: plumed-amberredist

- Downloads, compiles, and makes .deb files for the speicifed Ubuntu version

  : AmberTools - https://ambermd.org/

  : Amber - https://ambermd.org (optional)

    Package created: amber##   (where ## is the version number)


Frequently Asked Questions:

- How do I start / use this?

  1. Install Docker

  2. Open scripts/variables.env and edit the the MAINTAINER variables, and the LICENSE acceptance variables.

  3. Decide on what Ubuntu OS version you will be building for:

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

  
  This process will take a lot of time (hours) depending on your hardware -- my workstation takes about 1.5 hours to make all the packages. I'd recommend making a repository and putting them all in a repository - to make dependency auto-solving a lot easier.


- Where are my built .deb files?

  pkgs/<oscodename>/


- Ickk -- what's with all the leftover files? How do I get rid of them?

  Run ./clean.sh <oscodename>


- I installed the .deb files -- how do I use this?

  The packages SHOULD have installed a ton of dependencies, including environment-modules. To get everything in the path correctly, run:
  

  module -s load amber24


  This will automatically source the appropriate amber.sh file as well as load all the required dependencies (CUDA, OpenMPI, Plumed, etc). All the amber programs in Amber's bin directory should be available now.


- Why don't you use Ubuntu's built-in CUDA, OpenMPI, Libboost?

  Many reasons. I started this project because the built-in Ubuntu 24.04 LTS CUDA version would not compile with Amber. I needed a different CUDA version that would work correctly, and there wasn't much availble in public repositories. For MPI, my particular use case requires the enabling of Java within MPI, so I needed to compile from scratch. Basically, in order to make these packages work as broadly as possible I detached key dependencies from OS default package dependencies/requirements.


- What if I don't like that?

  Don't use this builder then -- problem solved! ;)


- What Ubuntu operating systems do this work for?

  20.04 LTS (focal), 22.04 LTS (jammy), 24.04 LTS (noble)


- Can I use different versions than the defaults? 

  Yep -- I just haven't tested most of them! YMMV!


- Will you just host the .deb files you created for me?

  No -- this violates the various licenses. You have to build and host them yourself.


- Does this support other architectures besides amd64? 

  No


- Who do I contact if I have questions?

  Chris Wieringa <cwieri39@calvin.edu> -- no promise I'll get back to you since I don't officially support this.
