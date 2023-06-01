#!/bin/bash

# (c) 2020 - 2022 Daniel Companeetz, BMC Software, Inc.
# All rights reserved.

# BSD 3-Clause Licenses

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

# script to send SMS messages as a shout to a script destination
#Instructions and comments
#    See message formatting on the accompanying job definition
#Invoke from job Notification Actions
#    Set appropriate shout destination on the CCM or ctmsys
#This is a shell script that uses AT&T Developer API services.
#    Uses an account registered to dcompane with limitations.
#        Cannot send to non-AT&T phones
#        SMS charges may apply
#    Uses curl to submit requests.
#    Docs: https://developer.att.com/sms/docs
#
#OPTIONS
#    Parameters are passed per standard Control-M processes.
#    See job for details
#
#DEFAULTS
#   TO BE DOCUMENTED
#
# FUTURE WORK
#   None planned


#Used in dco_sndsmsATT shout destination, which is used in job DCO_TestSMSmsg
outdir=`dirname $0`
echo $@ >> $outdir/outfile.txt
 set -x
APP_KEY="6sutwhoisumbt0sfcszds8361n9kdm8sj4olsnl"
APP_SECRET="veggyqkgqv5qa5mlhq0jj3adr3sxatqa75fbu5w"

# Set up the scopes for requesting API access.
API_SCOPES="SMS"

# Fully qualified domain name for the API Gateway.
FQDN="https://api.att.com"

# Authentication parameter.

LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH

token=`curl "${FQDN}/oauth/v4/token" \
    --insecure \
    --header "Accept: application/json" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data "client_id=${APP_KEY}&client_secret=${APP_SECRET}&grant_type=client_credentials&scope=${API_SCOPES}"`


OAUTH_ACCESS_TOKEN=`jq -r .access_token <<<$token`

echo "Token obtained: $OAUTH_ACCESS_TOKEN"

# Enter telephone number to which the SMS message will be sent.
# For example: TEL="tel:+1234567890"
TEL=`echo $2|awk -F "==" '{print $1}'|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
TEL="tel:+1$TEL"
#echo "addr: $TEL"  >> $outdir/outfile.txt

# SMS message text body.
SMS_MSG_TEXT=`echo $2|awk -F "==" '{print $2}'|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`
SMS_MSG_TEXT="$SMS_MSG_TEXT"
#echo "msg: $SMS_MSG_TEXT"  >> $outdir/outfile.txt

#    --verbose  \
#    --trace-ascii  \
# Send the Send SMS method request to the API Gateway.
curl "${FQDN}/sms/v3/messaging/outbox" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${OAUTH_ACCESS_TOKEN}" \
    --data "{\"outboundSMSRequest\":{\"address\":\"${TEL}\",\"message\":\"${SMS_MSG_TEXT}\"}}" \
    --request POST
#    --request POST >> $outdir/outfile.txt 2>&1
