#! /bin/bash
set -x

SRC_DIR=.
CTM_SERVER=dc01
CTM_HOSTGRP=HG_DCO_Docker


docker run --net host \
--cgroupns=host \
--add-host dc01:192.168.4.35 \
-e CTM_SERVER=$CTM_SERVER \
-e CTM_HOSTGROUP=$CTM_HOSTGRP -dt controlmonprem

sudo docker ps

