#! /bin/bash

set -x

sudo useradd -G ctm,wheel -m -s /bin/bash ctmag$1

sudo su - ctmag$1 -c '

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

function create_file {
    FILE_NAME=$1
    FILE_CONTENT=$2
    cat << EOF > $FILE_NAME
     $FILE_CONTENT
EOF
}

EM_SERVER=dc01
EM_PORT=8444
API_TOKEN="b25QcmVtOjMxMmY2NWZmLTI1MTEtNDY4ZC04NzdmLThmZTVlMjk2NDcwNQ=="
IMAGE_TO_INSTALL="Agent_22_050.Linux"
wget --no-check-certificate https://$EM_SERVER:$EM_PORT/automation-api/install_ctm_cli.py
python install_ctm_cli.py
rm install_ctm_cli.py
ctm env add dc01 https://$EM_SERVER:$EM_PORT/automation-api $API_TOKEN
ctm provision image $IMAGE_TO_INSTALL

#create_file ag_add.json "
#{
#   \"persistentConnection\": true
#}"

create_file agent-parameters.json "
{
    \"connectionInitiator\": \"AgentToServer\"
}"


CTM_SERVER=dc01
AGENT_NAME=$HOSTNAME-$USER
CTM_HOSTGROUP=DCO_RH_HOSTS
unused_port

ag_exists=$(ctm config server:agents::get $CTM_SERVER -s "agent=$AGENT_NAME" | jq -r .agents[0].nodeid)
ag_type=$(ctm config server:agents::get $CTM_SERVER -s "agent=$AGENT_NAME" | jq -r .agents[0].type)
ag_in_hg=$(ctm config server:agents::get $CTM_SERVER -s "agent=$AGENT_NAME" | jq -r .agents[0].hostgroups[0])

# assume the agent can now be deleted before being added if it exists
if [ $ag_exists == $AGENT_NAME ]; then
    # assume there is only one HG the agent belongs to
    if [ ! $ag_in_hg == null ]; then
        ctm config server:hostgroup:agent::delete $CTM_SERVER $CTM_HOSTGROUP $AGENT_NAME
    fi
    if [ ag_type == "Agentless Host" ]; then
        ctm config server:agentlesshost::delete $CTM_SERVER $AGENT_NAME
    else
        ctm config server:agent::delete $CTM_SERVER $AGENT_NAME
    fi
fi

#ctm config server:agent::add $CTM_SERVER $AGENT_NAME $CTM_AGENT_PORT -f ag_add.json
# Ensuring that agent is set. Since OS.dat is updated, it does not need agent restart
ctm provision setup $CTM_SERVER $AGENT_NAME $CTM_AGENT_PORT -f agent-parameters.json
if [ $? -ne 0 ]; then
    echo "Error registering agent $AGENT_NAME in Control-M/Server $CTM_SERVER"
        exit 1
fi
source .bashrc
set_agent_mode -u $USER -o 3 -r N
ctm config server:agent::update $CTM_SERVER $AGENT_NAME persistentConnection Y
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP $AGENT_NAME

# Run the SSL jobs
echo Creating deploy descriptor
create_file agt_logical_dd.json "
{
   \"DeployDescriptor\": [
      {
         \"Property\": \"\$.Variables[*].*\",
         \"Replace\": [
            {
              \"agent_not_set\": \"$AGENT_NAME\"
            },{
               \"user_not_set\": \"$USER)\"
            }
         ]
      },
      {
         \"Property\": \"Host\",
         \"Replace\": [
            {
               \"agent_not_set\": \"$AGENT_NAME\"
            }
         ]
      },
      {
         \"Property\": \"RunAs\",
         \"Replace\": [
            {
               \"user_not_set\": \"$USER\"
            }
         ]
      },
      {
         \"Comment\": \"Change Event naming based on the host - only for staging\",
         \"Property\": \"@[*].Events[*].Event\",
         \"Replace\": [
            {
              \"(.*)\": \"\$1-$CTM_AGENT_PORT\"
            }
         ]
      },
      {
         \"ApplyOn\"     :  {\"Type\": \"Job:SLAManagement\"},
         \"Property\" : \"ServiceName\",
         \"Replace\" : [ {\"DCO_SSL_Cert4_%%agt_logical\":\"DCO_SSL_Cert_4_$AGENT_NAME\"} ]
      },
      {
         \"ApplyOn\"     :  {\"Type\": \"Folder\"},
         \"Property\" : \"@\",
         \"Replace\" : [ {\"DCO_Set_SSL\":\"DCO_Set_SSL_4_$AGENT_NAME\"} ]
      }
   ]
}"

ctm run ondemand ~dcompane1/cert_jobs.json agt_logical_dd.json




#ctm config server:agent:param::set  $CTM_SERVER $AGENT_NAME JAVA_RH Y
'
