#! /bin/bash
set -x

IMG_TAG="controlmonprem"

if [ x$1 == "x" ]; then
    container_id=$(docker ps -a | grep $IMG_TAG | grep Up | awk '{print $1}')
else
    container_id=$1
fi

sudo docker ps
sudo docker stop $container_id -t 60

sudo docker inspect -f '{{.State.ExitCode}}' $container_id
dockerlog=$(sudo docker inspect -f '{{.LogPath}}' $container_id)
sudo cat $dockerlog

sudo docker ps
