#! /bin/bash

# (c) 2020 - 2022 Daniel Companeetz, BMC Software, Inc.
# All rights reserved.

# BSD 3-Clause License

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# SPDX-License-Identifier: BSD-3-Clause
# For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html

set -x

# $1 is the endpoint

currdir=$(pwd|grep image)
if [ x$currdir == "x" ]; then
    cd image
fi

SRC_DIR=.
IMG_TAG="controlmsaas"

AAPI_ENDPOINT="sandbox.controlm.com"
AAPI_TOKEN=UFJER0ZQOjA1MjZiZDQdwLTAwMjUtNDc5MS1iNDI5LTllNDdmMTU1MGM2MzpCdzdPVTRrVUU5WVlWOTNBM0cxTTk5dTJ5RWZERUlBWERPQk1BdlhPdVJNPQ==
AAPI_ENVIRONMENT="endpoint"

# INSTALL_* allows to add a plugin during the build process
INSTALL_AIT="N"   # Application Integrator
INSTALL_MQL="N"   # Databases
INSTALL_AMZ="N"   # AWS
INSTALL_AZR="N"   # Azure
INSTALL_CBD="N"   # Hadoop
INSTALL_INF="N"   # Informatica
INSTALL_AFP="N"   # Managed File Transfer
INSTALL_RMC="N"   # SAP

startdate=`date`

# $1 allows to add options like --no-cache
sudo docker build --tag=$IMG_TAG $1 \
  --build-arg AAPI_ENDPOINT=$AAPI_ENDPOINT \
  --build-arg AAPI_TOKEN=$AAPI_TOKEN \
  --build-arg AAPI_ENVIRONMENT=$AAPI_ENVIRONMENT \
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
