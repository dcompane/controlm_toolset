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

ctm_cn="ctmsrv.dc01"
base_dir=`pwd`
base_dir="${base_dir}/.."

# This script is for the Control-M Server Zone 2

dir=${CONTROLM_SERVER}/data/SSL

cd $dir

#5. Create the new ctmkeystore.p12 keystore

#5.1 Backup the current/original keystore

if [ ! -d "$CONTROLM_SERVER/data/SSL/cert.ori" ]; then
	cp -Rv $CONTROLM_SERVER/data/SSL/cert \
		$CONTROLM_SERVER/data/SSL/cert.ori
fi

#5.2 Create CA Chain
if [ ! -f ${base_dir}/rootCA/certs/ctmchainCA.crt ]; then
    cat ${base_dir}/intCA/certs/ctmintCA.crt ${base_dir}/rootCA/certs/ctmrootCA.crt  > ${base_dir}/rootCA/certs/ctmchainCA.crt
    chmod 777 ${base_dir}/rootCA/certs/ctmchainCA.crt
fi

#6. Create the new ctmkeystore.p12
rm -f private_keys/.ctmkeystore.p12.passwd
openssl rand -base64 -out private_keys/.ctmkeystore.p12.passwd 16
chmod 400 private_keys/.ctmkeystore.p12.passwd

openssl pkcs12 -in ${base_dir}/intCA/certs/${ctm_cn}.crt \
	-inkey ${CONTROLM_SERVER}/data/SSL/private_keys/${ctm_cn}.pem \
	-passin file:${CONTROLM_SERVER}/data/SSL/private_keys/.${ctm_cn}.key.passwd \
	-out ${CONTROLM_SERVER}/data/SSL/private_keys/ctmkeystore.p12 -name codn \
	-passout file:${CONTROLM_SERVER}/data/SSL/private_keys/.ctmkeystore.p12.passwd \
	-CAfile ${base_dir}//rootCA/certs/ctmchainCA.crt \
	-caname tomcat \
	-export \
	-chain 
	# If Java 11 still used (per docs)
	#-certpbe pbeWithSHA1And3-KeyTripleDES-CBC \
	#-keypbe pbeWithSHA1And3-KeyTripleDES-CBC \

# Adding the CA as trustedCertEntry to the keystore 
keytool -importcert -storetype PKCS12 -noprompt \
	-keystore ${CONTROLM_SERVER}/data/SSL/private_keys/ctmkeystore.p12 \
	-alias ca -file ~/sslctm/intCA/certs/ctmchainCA.crt \
	-storepass `cat ${CONTROLM_SERVER}/data/SSL/private_keys/.ctmkeystore.p12.passwd`

#6.2 Verify the keystore
openssl pkcs12 -info -in ${CONTROLM_SERVER}/data/SSL/private_keys/ctmkeystore.p12 \
       	-passin file:${CONTROLM_SERVER}/data/SSL/private_keys/.ctmkeystore.p12.passwd \
       	-passout file:${CONTROLM_SERVER}/data/SSL/private_keys/.${ctm_cn}.key.passwd


keytool -list -v -keystore ${CONTROLM_SERVER}/data/SSL/private_keys/ctmkeystore.p12 \
	-storepass $(cat ${CONTROLM_SERVER}/data/SSL/private_keys/.ctmkeystore.p12.passwd)


echo Zone 2 certificate private key located in $CONTROLM_SERVER/data/SSL/private_keys
echo Zone 2 private key l passphrase located in $CONTROLM_SERVER/data/SSL/private_keys
echo New ctmkeystore.p12 keystore located in $CONTROLM_SERVER/data/SSL/private_keys

 
exit

