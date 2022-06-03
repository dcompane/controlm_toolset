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

# INSTALL_* allows to add a plugin during the build process
INSTALL_AIT="Y"   # Application Integrator
INSTALL_MQL="Y"   # Databases
INSTALL_AMZ="Y"   # AWS
INSTALL_AZR="Y"   # Azure
INSTALL_CBD="Y"   # Hadoop
INSTALL_INF="Y"   # Informatica
INSTALL_AFP="Y"   # Managed File Transfer
INSTALL_RMC="Y"   # SAP

startdate=`date`

# $1 allows to add options like --no-cache
sudo docker build --tag=$IMG_TAG $1 \
  --build-arg AAPI_ENDPOINT=$AAPI_ENDPOINT \
  --build-arg AAPI_TOKEN=$AAPI_TOKEN \
  --build-arg INSTALL_AIT=$INSTALL_AIT \
  --build-arg INSTALL_MQL=$INSTALL_MQL \
  --build-arg INSTALL_AMZ=$INSTALL_AMZ \
  --build-arg INSTALL_AZR=$INSTALL_AZR \
  --build-arg INSTALL_CBD=$INSTALL_CBD \
  --build-arg INSTALL_INF=$INSTALL_INF \
  --build-arg INSTALL_AFP=$INSTALL_AFP \
  --build-arg INSTALL_RMC=$INSTALL_RMC \
  $SRC_DIR

echo $startdate `date`

sudo docker images
