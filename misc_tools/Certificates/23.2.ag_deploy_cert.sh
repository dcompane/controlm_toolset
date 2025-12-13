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
# 20251212      Daniel Companeetz     Initial release

set -x

if [ x$1 == "x"  ] ; then
        echo need to provide an agent name
        echo "Usage: $0 <agent_name>"
        exit 13
fi


agent_logical=$1
agent_short="dc01"
agent_fqdn="dc01"
agent_alias="dc01-ctmagent"
agent_ip="192.168.4.35"
agent_ctms="dc01"

# This script is for the Control-M Agent Zone 3

ctm_cn=$agent_logical
base_dir=`pwd`
base_dir="${base_dir}/.."

IntCA_dir=${base_dir}/intCA

dir=${CONTROLM}

cd $dir

file_name=$agent_logical-$agent_ctms
crt_file=$IntCA_dir/certs/$file_name.crt

# This will use the AAPI method.


# see https://documents.bmc.com/supportu/API/Monthly/en-US/Documentation/API_Services_ConfigService_Agent.htm#config106
ctm config server:agent::update $agent_ctms $agent_logical persistentConnection Y
ctm config server:agent::update $agent_ctms $agent_logical allowAgentDisconnection N

ctm config server:agent:crt::deploy $agent_ctms $agent_logical $crt_file ${IntCA_dir}/certs/ctmchainCA.pem

ctm config server:agent::update $agent_ctms $agent_logical sslState Enabled

ctm config server:agent:crt:expiration::get $agent_ctms $agent_logical

# https://documents.bmc.com/supportu/API/Monthly/en-US/Documentation/API_Services_ConfigService_Agent.htm#config79
#ctm config item::recycle "CTMS:Agent:$agent_ctms:$agent_logical"

exit