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




# See https://openssl-ca.readthedocs.io/en/latest/create-the-intermediate-pair.html

if [ -z "${EM_HOME}" ]; then
  echo "Error: EM_HOME is not set. Run em $0 to start this script" >&2
  exit 1
fi


set -x

object="intCA"

## 1. Create a directory for your CA files:
base_dir=`pwd`
base_dir="${base_dir}/.."

echo The current directory is `pwd`

#Revoke existing certificate
if [ -e "${base_dir}/intCA/certs/ctm${object}.crt" ];then
    openssl ca -revoke ${base_dir}/intCA/certs/ctm${object}.crt \
        -config ${base_dir}/rootCA/opensslrootCA.cnf \
        -passin file:${base_dir}/rootCA/private/.ctmrootCA.key.passwd
fi

rm -rf  $base_dir/$object
mkdir -p $base_dir/$object
cd  $base_dir/$object

mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

dir="${base_dir}/$object"
cat <<EOF > openssl${object}.cnf
[ ca ]
default_ca = CA_LOC
copy_extensions = copy

[ CA_LOC ]
dir = $dir
certs = $dir/certs
crl_dir = $dir/crl
new_certs_dir = $dir/newcerts
database = $dir/index.txt
serial = $dir/serial
RANDFILE = $dir/private/.rand

# Root CA key and certificate
private_key = $dir/private/ctm${object}.key
certificate = $dir/certs/ctm${object}.crt

# CRL settings
crlnumber = $dir/crlnum
crl = $dir/crl/ctm${object}crl.pem
default_crl_days = 30

# General CA settings
default_md = sha256
name_opt = ca_default
cert_opt = ca_default
default_days = 375
preserve = no
policy = policy
copy_extensions  = copy

[ policy ]
# Required fields for certificate requests
commonName = supplied
stateOrProvinceName = supplied
countryName = supplied
emailAddress = supplied
organizationName = supplied
organizationalUnitName = supplied

[ req ]
default_bits = 4096
string_mask = utf8only
prompt = no
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
req_extensions = v3_req
days = 365

[ req_distinguished_name ]
commonName = DCO Intermediate CA
countryName = US
stateOrProvinceName = CA
localityName = Oakland
0.organizationName = DCO
organizationalUnitName = DCO Signers
emailAddress = dcompane@bmc.com

[ v3_ca ]
# Root CA certificate extensions
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
nsComment = "DCO Root CA Certificate for Control-M use"
basicConstraints = critical, CA:true, pathlen:1
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Intermediate CA certificate extensions
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
nsComment = "DCO Intermediate Signing Certificate for Control-M use"
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_req ]
# CSR extensions
basicConstraints = CA:false
extendedKeyUsage = serverAuth, clientAuth
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


[ usr_cert ]
# Client certificate extensions
basicConstraints = CA:FALSE
nsComment = "DCO Client Certificate for Control-M use"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Server certificate extensions
basicConstraints = CA:FALSE
nsComment = "DCO Server Certificate for Control-M use"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[ crl_ext ]
# CRL extension
authorityKeyIdentifier = keyid:always

[ ocsp ]
# OCSP signing certificate extension
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature


EOF

#2. Generate a private key for your Root CA:
#2.1 Generate a random password
openssl rand -base64 -out private/.ctm${object}.key.passwd 16
# chmod should be 400
chmod 400 private/.ctm${object}.key.passwd
#2.2 generate the key private protected with the random password
openssl genrsa -out private/ctm${object}.key -aes256 \
        -passout file:private/.ctm${object}.key.passwd -verbose 4096
# chmod should be 400
chmod 400 private/ctm${object}.key

echo The current directory is `pwd`

#3. Create an intermediate CSR
openssl req -config openssl${object}.cnf -new -sha256 \
        -key private/ctm${object}.key \
        -out csr/ctm${object}.csr \
        -passin file:private/.ctm${object}.key.passwd


#4. Sign the CSR with the Root CA
openssl ca -config ../rootCA/opensslrootCA.cnf -extensions v3_intermediate_ca \
    -days 1825 -notext -md sha256 -in csr/ctm${object}.csr \
    -passin file:../rootCA/private/.ctmrootCA.key.passwd \
    -out certs/ctm${object}.crt -batch

#4. Read the cert
openssl x509 -in certs/ctm${object}.crt -text
openssl verify -CAfile ../rootCA/certs/ctmrootCA.crt certs/ctm${object}.crt
