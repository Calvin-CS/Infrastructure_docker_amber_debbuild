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

# no caches; so clean everything
docker image prune -a -f

# loop through the dists
for dist in ${DIST[@]}
do
	echo "Building dist $dist..."
	CONTAINERNAME="builder-$dist"
	docker build --no-cache -t $CONTAINERNAME:latest -f Dockerfile.$dist .
done
