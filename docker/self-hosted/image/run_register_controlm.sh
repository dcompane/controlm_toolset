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

# enabling the output for the log 
set -x

function unused_port {
    local port=$(shuf -i 7000-8000 -n 1)
    netstat -lat | grep $port > /dev/null
    if [[ $? == 1 ]] ; then
        export CTM_AGENT_PORT=$port
    else
        # yes recursive, but works and easier than loop.
        # should get out in a couple of tries...
        unused_port
    fi
}

function sigtrapHandler() {
    # enabling the output for the log
    set -x
    getout=0
    echo '========================================================================'
    echo Received signal $signal at sigtrapHandler
    echo '========================================================================'
    echo remove agent [$AGENT_NAME] from hostgroup [$CTM_HOSTGROUP] 
    ctm config server:hostgroup:agent::delete $CTM_SERVER $CTM_HOSTGROUP $AGENT_NAME 
    if [ $? -ne 0 ]; then
        echo "Error deleting agent $AGENT_NAME from hostgroup $CTM_HOSTGROUP on $CTM_SERVER"
        echo "   Will not attempt to delete the agent. Exiting."
        getout=13
        
    else
        echo unregister controlm agent [$AGENT_NAME] from server IN01 
        ctm config server:agent::delete $CTM_SERVER $AGENT_NAME 
        if [ $? -ne 0 ]; then
            echo "Error deleting agent $AGENT_NAME from $CTM_SERVER"
            getout=14
        fi
    fi
    echo removed agent via $signal and getout set to $getout
    return $getout
}

############ Script starts here ############

# If CID does not work, use UNIQUE (and rename the variable CID)
# UNIQUE=$(head /dev/urandom | tr -dc A-Za-z | head -c 6 ; echo '')

# CID= Container ID
CID=$(cat /proc/1/cgroup | grep 'docker' | tail -1 | sed 's/^.*\///' | cut -c 1-12)
AGENT_NAME=$(hostname)-$CID
echo $AGENT_NAME

# This line only for on-prem
unused_port

# Adding some info to the docker log
#   sudo docker inspect -f '{{.LogPath}}' $container_id from outside the container
cd
pwd
env

# Setting sudo Mode. Comment next 2 lines if not needed
echo -e "\nSUDO_ENABLED  Y" >> ctm/data/OS.dat
echo "SUDO_ENABLED  Y"

# AAPI commands tailored for on-prem

echo Starting and registering Control-M agent [$AGENT_NAME] with Control-M/Server [$CTM_SERVER], using environment [$CTM_ENV] 
echo Please wait for actions
echo run and register controlm agent [$AGENT_NAME] with controlm [$CTM_SERVER], environment [$CTM_ENV]
ctm provision setup $CTM_SERVER $AGENT_NAME $CTM_AGENT_PORT -f agent-parameters.json
if [ $? -ne 0 ]; then
    echo "Error registering agent $AGENT_NAME in Control-M/Server $CTM_SERVER"
        exit 1
fi

echo 'setting traps for signals SIGTERM and SIGUSR1'
trap "signal='SIGUSR1';sigtrapHandler" SIGUSR1
trap "signal='SIGTERM';sigtrapHandler" SIGTERM

echo Sourcing the environment
source .bash_profile

# Ensuring that agent is set. Since OS.dat is updated, it does not need agent restart
set_agent_mode -u controlm -o 3

echo Adding or creating a Control-M hostgroup [$CTM_HOSTGROUP] with agent [$AGENT_NAME]
echo Please wait for actions
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP $AGENT_NAME 
if [ $? -ne 0 ]; then
    echo "Error adding agent $AGENT_NAME to agent host group $CTM_HOSTGROUP on $CTM_SERVER"
        exit 1
fi

echo Testing utilities
echo ag_ping
ag_ping
echo shagent
shagent
echo ag_diag_comm
ag_diag_comm
echo aapi agent ping
ctm config server:agent::ping $CTM_SERVER $AGENT_NAME

echo "Done setting up"
echo "Control-M Agent setup complete"
echo "Agent Name: $AGENT_NAME"
echo "---> May need to ping the agent from the server to have it become available<---"

# Setting up test jobs
# # # # UNCOMMENT AS NEEDED # # # # 
# # # # deploy jobs to test the agent
# sed -i "s/agent_name/$AGENT_NAME/" deploy_test_jobs.json
# ctm deploy deploy_test_jobs.json
# ctm run order $CTM_SERVER DCO_Docker DCO_Docker_Server2Agent_available > response.json
# cat response.json
# ctm run status $(cat response.json| grep runId | cut -d : -f2 | awk -F\" '{print $2}')
# echo run test job
# ctm run order $CTM_SERVER DCO_Docker DCO_Docker_Job > response.json
# cat response.json
# ctm run status $(cat response.json| grep runId | cut -d : -f2 | awk -F\" '{print $2}')
# echo "Validations ran."
echo "Entering infinite loop..."
echo "Thanks for your patience!"

# loop forever until getout is different of 99
getout=99
set -     #removing the output for the loop 
while [ $getout -eq 99  ]
do
  sleep 10
done

# enabling the output for the log 
set -x

echo finally getout = $getout

exit $getout

