#! /bin/bash
set -x

if [ $# -eq 0 ]; then
    echo "No arguments provided - using SIGUSR1"
    SIGNAL="SIGUSR1"
else 
    SIGNAL="$1"
fi



IMG_TAG="controlmonprem"

container_id=$(docker ps -a | grep $IMG_TAG | grep Up | awk '{print $1}')
sudo docker ps
sudo docker kill --signal="$SIGNAL" $container_id
#sudo docker stop $container_id

sudo docker inspect -f '{{.State.ExitCode}}' $container_id
dockerlog=$(sudo docker inspect -f '{{.LogPath}}' $container_id)
sudo cat $dockerlog

sudo docker ps -a | head -2
