#!/usr/bin/bash

if [ -z $1 ]
then
	echo "Requires argument (focal, jammy, noble, or 'all')";
	exit 1;
fi

# argument processing
if [ $1 == "all" ]
then
	DIST=("focal" "jammy" "noble")
else
	DIST=($1)
fi

# loop through the dists
for dist in ${DIST[@]}
do
	echo "Running dist $dist..."
	CONTAINERNAME="builder-$dist"
	docker run -it -v "$(pwd)"/src:/src -v "$(pwd)"/pkgs:/pkgs -v "$(pwd)"/scripts:/scripts $CONTAINERNAME:latest /usr/bin/bash
done
