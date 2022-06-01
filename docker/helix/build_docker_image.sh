#! /bin/bash
set -x

currdir=$(pwd|grep image)
if [ x$currdir == "x" ]; then
    cd image
fi

SRC_DIR=.
IMG_TAG="controlmsaas"

AAPI_ENDPOINT="se-sanb0x-aapi.us1.controlm.com"
AAPI_TOKEN=UFJER0ZQOjA1MjZiZDQwLTAwMjUtNDc5MS1iNDI5LTllNDdmMTU1MGM2MzpCdzdPVTRrVUU5WVlWOTNBM0cxTTk5dTJ5RWZERUlBWERPQk1BdlhPdVJNPQ==

startdate=`date`

sudo docker build --tag=$IMG_TAG $1\
  --build-arg AAPI_ENDPOINT=$AAPI_ENDPOINT \
  --build-arg AAPI_TOKEN=$AAPI_TOKEN \
  $SRC_DIR

echo $startdate `date`

sudo docker images
