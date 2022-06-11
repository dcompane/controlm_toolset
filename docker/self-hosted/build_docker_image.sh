#! /bin/bash
set -x

cd image
SRC_DIR=.
IMG_TAG="controlmonprem"

AAPI_ENDPOINT=192.168.4.35
AAPI_USER=emuser
AAPI_PASS=empass

startdate=`date`

sudo docker build --tag=$IMG_TAG $1\
  --build-arg AAPI_ENDPOINT=$AAPI_ENDPOINT \
  --build-arg AAPI_USER=$AAPI_USER \
  --build-arg AAPI_PASSWORD=$AAPI_PASS \
  $SRC_DIR

echo $startdate `date`

sudo docker images


