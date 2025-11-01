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

if [ -z "${EM_HOME}" ]; then
  echo "Error: EM_HOME is not set. Run em $0 to start this script" >&2
  exit 1
fi

ctm_cn="ctmem.dc01"

# This script is for the Enterprise Manager Zone 1
#   Execute this script as the EM Linux user
# See Note on Step 3 at https://documents.bmc.com/supportu/9.0.22/en-US/Documentation/Zone_1_SSL_configuration.htm#Generati2
#   Run: em tcsh
# and then run this script

base_dir=`pwd`
base_dir=${base_dir}/..

dir=${EM_HOME}/data/SSL

cd $dir

#5. Create the new tomcat.p12 keystore

#5.1 Backup the current/original keystore

if [ ! -f "$EM_HOME/ini/ssl/tomcat.p12.ori" ]; then
        cp $EM_HOME/ini/ssl/tomcat.p12 $EM_HOME/ini/ssl/tomcat.p12.ori
        cp $EM_HOME/ini/ssl/tomcat.ini $EM_HOME/ini/ssl/tomcat.ini.ori
        cp $EM_HOME/etc/emweb/tomcat/conf/server.xml $EM_HOME/etc/emweb/tomcat/conf/server.xml.ori
fi

#5.2 Create CA Chain
cat $base_dir/intCA/certs/ctmintCA.crt $base_dir/rootCA/certs/ctmrootCA.crt  > $base_dir/intCA/certs/ctmchainCA.crt

chmod 777 $base_dir/intCA/certs/ctmchainCA.crt

cp $base_dir/intCA/certs/ctmchainCA.crt $base_dir/intCA/certs/ctmchainCA.pem

#6. Create the new tomcat.p12
rm -f private_keys/.tomcat.p12.passwd
openssl rand -base64 -out private_keys/.tomcat.p12.passwd 16
chmod 400 private_keys/.tomcat.p12.passwd

openssl pkcs12 -in $base_dir/intCA/certs/${ctm_cn}.crt \
        -inkey ${EM_HOME}/data/SSL/private_keys/${ctm_cn}.pem \
        -passin file:${EM_HOME}/data/SSL/private_keys/.${ctm_cn}.key.passwd \
        -out ${EM_HOME}/data/SSL/private_keys/tomcat.p12 -name $ctm_cn \
        -passout file:${EM_HOME}/data/SSL/private_keys/.tomcat.p12.passwd \
        -CAfile $base_dir/intCA/certs/ctmchainCA.crt \
        -name tomcat \
        -caname tomcat \
        -export \
        -chain

#6.2 Verify the keystore
openssl pkcs12 -info -in ${EM_HOME}/data/SSL/private_keys/tomcat.p12 \
        -passin file:${EM_HOME}/data/SSL/private_keys/.tomcat.p12.passwd \
        -passout file:${EM_HOME}/data/SSL/private_keys/.${ctm_cn}.key.passwd



echo Zone 1 certificate private key located in $EM_HOME/data/SSL/private_keys
echo Zone 1 private key l passphrase ocated in $EM_HOME/data/SSL/private_keys
echo New tomcat.p12 keystore located in $EM_HOME/data/SSL/private_keys
echo   "tomcat.p12 will copied to $EM_HOME/ini/ssl (next line in this script does it)."
echo ""

cp $EM_HOME/data/SSL/private_keys/tomcat.p12 $EM_HOME/ini/ssl


stop_web_server

em manage_webserver -action set_tomcat_conf -sslMode true

em manage_webserver -action create_secure_connection \
        -keystoreFilename tomcat.p12 \
        -keystorePassword `cat ${EM_HOME}/data/SSL/private_keys/.tomcat.p12.passwd` \
        -updateExistingConnector

emcryptocli `cat ${EM_HOME}/data/SSL/private_keys/.tomcat.p12.passwd` $EM_HOME/ini/ssl/tomcat.ini



echo You will also need to import the root and intermediate certs in your client system for the browser to recognize the server certificate.

sleep 30

start_web_server

echo "EM Zone 1 Tomcat SSL setup is complete."

echo "Download the new Control-M Zone 1 certificates (depending what you need) from:"
echo "  $base_dir/rootCA/certs/ctmrootCA.crt"
echo "  $base_dir/intCA/certs/ctmintCA.crt"
echo "  $base_dir/intCA/certs/ctmchainCA.crt"
echo "Import these into your browser or client system to avoid certificate warnings."
echo "   and use the AddCerts2Stores.ps1 script to add them to Windows CertStore or other cacerts if needed."

exit 0