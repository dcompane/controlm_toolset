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

# See https://documents.bmc.com/supportu/9.0.22/en-US/Documentation/ctmkeytool.htm#Create


if [ -z "${EM_HOME}" ]; then
  echo "Error: EM_HOME is not set. Run em $0 to start this script" >&2
  exit 1
fi

 set -x

ctm_cn="ctmem.dc01"
base_dir=`pwd`
base_dir="${base_dir}/.."


# This script is for the Enterprise Manager Zone 1
#   Execute this script as the EM Linux user
# See Note on Step 3 at https://documents.bmc.com/supportu/9.0.22/en-US/Documentation/Zone_1_SSL_configuration.htm#Generati2
#   Run: em tcsh
# and then run this script


# 1. Run the ctmkeytool to create the EM CSR

# 1.1 Define the csr_params.cfg

dir=${EM_HOME}/data/SSL

cd $dir

#cat <<EOF > config/csr_${ctm_cn}.cnf
cat <<EOF > config/csr_params.cfg
[ req ]
distinguished_name = dn
req_extensions = req_ext

# Advanced section - Default values are recommended
default_bits = 2048
prompt = no
default_md = sha256

[ dn ]
C = US
ST = CA
L = Oakland
O = DCO
OU = DCO CTM
CN = `hostname --fqdn`
emailAddress = ctmem@dc01

[ req_ext ]
#keyUsage = digitalSignature, keyEncipherment
#extendedKeyUsage = serverAuth, clientAuth
nsComment    = "OpenSSL Generated Control-M Zone 1 Server Certificate"
subjectAltName = @alt_names

[ alt_names ]
# FQDN
DNS.1 = `hostname --fqdn`
# Short name
DNS.2 = `hostname --short`
# Alias
DNS.3 = `hostname --alias`
# IP address. Remove in Dynamic address environments (DHCP or alike).
DNS.4 = `hostname --ip-address`

EOF

#2. Generate a private key for your certs
#2.1 Generate a random password
rm -f private_keys/.${ctm_cn}.key.passwd
openssl rand -base64 -out private_keys/.${ctm_cn}.key.passwd 16
chmod 400 private_keys/.${ctm_cn}.key.passwd
#2.2 generate the key private protected with the random password
rm -f private_keys/${ctm_cn}.pem
${EM_HOME}/bin/ctmkeytool -create_csr \
        -password $(cat private_keys/.${ctm_cn}.key.passwd) \
        -out ${ctm_cn}
#       -conf_file config/csr_params.cfg \
#       -conf_file ${dir}/config/csr_${ctm_cn}.cnf \

#Note that csr and pk and extensions have predefinded locations by the ctmkeytool
chmod 400 private_keys/${ctm_cn}.pem

#3. Read the CSR
## Using /bin since the CTM openssl does not verify the file properly.
LD_LIB=$LD_LIBRARY_PATH
LD_LIBRARY_PATH=/lib64
/bin/openssl req -verify -in $dir/certificate_requests/${ctm_cn}.csr \
        -text
LD_LIBRARY_PATH=$LD_LIB

#4. Sign the CSR with the intermediate certificate
#   This is normally done by the Security team or online.

IntCA_dir=$base_dir/intCA

#Revoke existing certificate
if [ -e "${IntCA_dir}/certs/${ctm_cn}.crt" ];then
    openssl ca -revoke ${IntCA_dir}/certs/${ctm_cn}.crt \
        -config ${IntCA_dir}/opensslintCA.cnf \
        -passin file:${IntCA_dir}/private/.ctmintCA.key.passwd
fi

#Sign the new cert
openssl ca -config ${IntCA_dir}/opensslintCA.cnf -extensions server_cert \
    -days 375 -notext -md sha256 \
    -in ${dir}/certificate_requests/${ctm_cn}.csr \
    -out ${IntCA_dir}/certs/${ctm_cn}.crt -batch \
    -passin file:${IntCA_dir}/private/.ctmintCA.key.passwd

#5 Verify the certificate

LD_LIB=$LD_LIBRARY_PATH
LD_LIBRARY_PATH=/lib64
openssl x509  -in ${IntCA_dir}/certs/${ctm_cn}.crt -text
openssl verify -untrusted ${IntCA_dir}/certs/ctmintCA.crt \
        -CAfile ${IntCA_dir}/../rootCA/certs/ctmrootCA.crt \
        ${IntCA_dir}/certs/${ctm_cn}.crt

# Compare private key vs. certificate. should be same checksum
openssl rsa -noout -modulus \
        -in ${EM_HOME}/data/SSL/private_keys/${ctm_cn}.pem \
        -passin file:${EM_HOME}/data/SSL/private_keys/.${ctm_cn}.key.passwd \
        | openssl md5
openssl x509 -noout -modulus -in ${IntCA_dir}/certs/${ctm_cn}.crt \
        | openssl md5


echo Zone 1 CSR located in $EM_HOME/data/SSL/certificate_requests
echo Zone 1 certificate private key located in $EM_HOME/data/SSL/private_keys
echo Zone 1 private key passphrase located in $EM_HOME/data/SSL/private_keys

exit
