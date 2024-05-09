#!/bin/bash

if [ -z $1 ]
then
	echo "Requires argument (focal, jammy, noble or 'all')";
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
	echo "Cleaning dist $dist... within Docker"
	CONTAINERNAME="builder-$dist"
	docker run -it -v "$(pwd)"/src:/src -v "$(pwd)"/pkgs:/pkgs -v "$(pwd)"/scripts:/scripts $CONTAINERNAME:latest /scripts/run-cleaner.sh

	# now, cleanup the docker images
	# first prune stopped containers
	docker container prune -f
	docker rmi $(docker images "builder-${dist}" -a -q)
done

docker builder prune -a -f