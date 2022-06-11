#! /bin/bash
set -x

container_id=$(docker ps -a | grep controlmop | grep Up | awk '{print $1}')
sudo docker ps
sudo docker logs $container_id
