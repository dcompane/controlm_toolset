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
start_time=$(date +%s)
echo Started at $(date)


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

cd
pwd
env

# Setting sudo Mode. Comment next 2 lines if not needed
echo -e "\nSUDO_ENABLED  Y" >> ctm/data/OS.dat
echo "SUDO_ENABLED  Y"

# AAPI commands tailored for on-prem

# Register the agent on the server
echo Adding the Agent to the Control-M server.
cat << EOF > ag_add.json
{
   "persistentConnection": true
}
EOF
ctm config server:agent::add $CTM_SERVER $AGENT_NAME $CTM_AGENT_PORT -f ag_add.json

echo Server $AGENT_NAME added. Running SSL jobs

# Run the SSL jobs
echo Creating deploy descriptor
cat << EOF > agt_logical_dd.json
{
   "DeployDescriptor": [
      {
         "Property": "$.Variables[*].*",
         "Replace": [
            {
               "agent_not_set": "$AGENT_NAME"
            },{
               "user_not_set": "$(whoami)"
            }
         ]
      },
      {
         "Property": "Host",
         "Replace": [
            {
               "agent_not_set": "$AGENT_NAME"
            }
         ]
      },
      {
         "Property": "RunAs",
         "Replace": [
            {
               "user_not_set": "$(whoami)"
            }
         ]
      },
      {
         "Comment": "Add agent port to event name to avoid conflicts when multiple agents are set concurrently on same server",
         "Property": "@[*].Events[*].Event",
         "Replace": [
            {
              "(.*)": "\$1-$CTM_AGENT_PORT"
            }
         ]
      },
      {
         "ApplyOn"     :  {"Type": "Job:SLAManagement"},
         "Property" : "ServiceName",
         "Replace" : [ {"DCO_SSL_Cert_4_Agent":"DCO_SSL_Cert_4_$AGENT_NAME"} ]
      },
      {
         "ApplyOn"     :  {"Type": "Folder"},
         "Property" : "@",
         "Replace" : [ {"DCO_Set_SSL":"DCO_Set_SSL_4_$AGENT_NAME"} ]
      }
   ]
}
EOF

# Job is ordered as soon as the agent is created in CTMS to measure the complete setup time
## Use the folder start and end time for measurement.
echo Running SSL certificate jobs for agent $AGENT_NAME
echo see github.com/dcompane/controlm_toolset/misc_tools/Certificates/README.md for more info on SSL scripts
ctm run ondemand cert_jobs.json agt_logical_dd.json

echo Setting up and registering Control-M agent [$AGENT_NAME] with Control-M/Server [$CTM_SERVER]
echo Please wait for actions
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

# Agent is started. SSL jobs will trigger as soon as the server sees the agent available.

echo Testing utilities
echo ag_ping
ag_ping
echo shagent
shagent
echo ag_diag_comm
ag_diag_comm
echo aapi agent ping
# This ping also may set the agent as available on the server
## SSL jobs will trigger at this point if not earlier.
ctm config server:agent::ping $CTM_SERVER $AGENT_NAME


echo "Done setting up"
echo "Control-M Agent setup complete"
echo "Agent Name: $AGENT_NAME"

echo "Entering infinite loop..."
echo "Thanks for your patience!"
echo "To unregister the agent, stop and remove the container using SIGTERM or SIGUSR1 to properly terminate the agent."
echo "For example: docker --signal="SIGUSR1" <container_id>"
echo "  or use the script signal_docker_container.sh"

# loop forever until getout is different of 99
getout=99
set -     #removing the output for the loop
while [ $getout -eq 99  ]
do
   # Since the agent is set to allow to initiate connection, this will keep the agent available
   # ag_ping every 2 minutes 
   ag_ping > ~/loop_ag_ping.log
   # connect to container and check the timestamp and contents of the file to validate status
   for i in {1..12}
     do
       if [ $getout -ne 99  ]; then
         #if signal was received and getout changed,  exit the sleep loop
         break
       fi
       sleep 10
     done
done

# enabling the output for the log
set -x

echo finally getout = $getout

exit $getout
