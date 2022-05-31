#! /bin/bash
set -x

IMG_TAG="controlmsaas"

CTM_HOSTGROUP="HG_DCO_Docker"
AGENT_TAG="dco_docker"

sudo docker run --net host \
  -e CTM_HOSTGROUP=$CTM_HOSTGROUP \
  -e AGENT_TAG=$AGENT_TAG -dt $IMG_TAG

sudo docker ps

