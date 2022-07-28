#! /bin/bash

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

#Change log
# 2018 10 03    dcompane, BMC   Initial release
# 2019 01 17	dcompane, BMC	Adding license to enable distribution

# Run as root or sudo
 if [ "$USER" != "root" ]; then
   echo "User must be root. Running as ${USER}."
   exit 120
 fi


#**********************************************************
# THIS MUST BE SET FOR THE SPECIFIC INSTALLATION
#    EDIT THE FILE TO REFLECT THE ENVIRONMENT
#    USE A JSON FORMATTER TO ENSURE GOOD STYLE
#    DO NOT REPEAT TAGS ACROSS SETS.
scriptdir=`dirname $0`
CONFIG_FILE="${scriptdir}/tktvars.json"


# THIS MUST BE SET FOR THE SPECIFIC INSTALLATION
ctmaapi=`jq -r .ctmvars.ctmaapi $CONFIG_FILE`
AAPIurl="$ctmaapi/ctm-cli.tgz"

#install the AAPI
#  This will throw an error ( ctm: command not found) if ctm is not installed
which ctm >/dev/null
rc=$?
if [ $rc -ne 0 ]; then
  yum -y install wget
  yum -y install gcc-c++ make
  curl -sL https://rpm.nodesource.com/setup_8.x | sudo -E bash -
  yum -y install nodejs
  npm -g install npm@latest
  wget --no-check-certificate -P /tmp $AAPIurl
  npm -g install /tmp/ctm-cli.tgz
  ctm
fi

