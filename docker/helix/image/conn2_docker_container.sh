#! /bin/bash
set -x

IMG_TAG="controlmsaas"

container_id=$(sudo docker ps -a | grep $IMG_TAG | grep Up | awk '{print $1}')
sudo docker ps 
sudo docker exec -i -t $container_id /bin/bash
