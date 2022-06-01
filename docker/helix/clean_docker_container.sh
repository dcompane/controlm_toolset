#! /bin/bash
set -x

docker images -a
sudo docker rmi --force $(docker images -f "dangling=true" -q)
docker images -a
