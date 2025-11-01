#! /bin/bash

# BSD 3-Clause License

# Copyright (c) 2021, 2025, BMC Software, Inc.; Daniel Companeetz
# All rights reserved.

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

# Change Log
# Date (YMD)    Name                  What
# --------      ------------------    ------------------------
# 20251031      Daniel Companeetz     Initial release

# See https://documents.bmc.com/supportu/9.0.22/en-US/Documentation/ctmkeytool.htm#Create

set -x

if [ -v "${CONTROLM_SERVER}" ]; then
  echo "Error: CONTROLM_SERVER is not set. This needs to run under the CTM Server. Seems it is running under the EM" >&2
  exit 1
fi


# This script is for the Control-M Server Zone 2

dir=${CONTROLM_SERVER}/data/SSL

cd $dir

#7. Deploy the created ctmserver p12 store

# DO NOT REGENERATE THE KEY PASSWORD
# rm -f private_keys/.ctmsrv.key.passwd
# openssl rand -base64 -out ${CONTROLM_SERVER}/data/SSL/private_keys/.ctmsrv.key.passwd  16
# bmcryptpw -m ${CONTROLM_SERVER}/data/SSL/private_keys/.ctmsrv.key.passwd -g
# chmod 400 private_keys/.ctmsrv.key.passwd

echo if your AG is a separate account or server, you should copy from the CTMS to here
echo    -keystore ${CONTROLM_SERVER}/data/SSL/private_keys/ctmkeystore.p12 
        -password $(cat ${CONTROLM_SERVER}/data/SSL/private_keys/.ctmkeystore.p12.passwd)
echo to some place where the next command will find them
echo    and adjust the command with full paths.



~/ctm_agent/ctm/exe/ctmkeytool \
	-keystore ${CONTROLM_SERVER}/data/SSL/private_keys/ctmkeystore.p12 \
	-password $(cat ${CONTROLM_SERVER}/data/SSL/private_keys/.ctmkeystore.p12.passwd) \
        -passwkey ~/ctm_agent/ctm/data/keys/local.key


exit
