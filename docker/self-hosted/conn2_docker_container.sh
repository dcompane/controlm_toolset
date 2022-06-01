#! /bin/bash
set -x

container_id=$(docker ps -a | grep controlmonprem | grep Up | awk '{print $1}')
sudo docker ps
sudo docker exec -i -t $container_id /bin/bash
