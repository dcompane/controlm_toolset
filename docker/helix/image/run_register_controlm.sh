#!/bin/bash

# enabling the output for the log
set -x


function sigtrapHandler() {
    # enabling the output for the log
    set -x
    getout=0
    echo '========================================================================'
    echo Received signal $signal at sigtrapHandler
    echo '========================================================================'
    echo remove agent [$AGENT_NAME] from hostgroup [$CTM_HOSTGROUP] 
    ctm config server:hostgroup:agent::delete $CTM_SERVER $CTM_HOSTGROUP $AGENT_NAME -e $CTM_ENV
    if [ $? -ne 0 ]; then
        echo "Error deleting agent $AGENT_NAME from hostgroup $CTM_HOSTGROUP on $CTM_SERVER"
        echo "   Will not attempt to delete the agent. Exiting."
        getout=13
        
    else
        echo unregister controlm agent [$AGENT_NAME] from server IN01 
        ctm config server:agent::delete $CTM_SERVER $AGENT_NAME -e $CTM_ENV
        if [ $? -ne 0 ]; then
            echo "Error deleting agent $AGENT_NAME from $CTM_SERVER"
            getout=14
        fi
    fi
    echo removed agent via $signal and getout set to $getout
    return $getout
}

############ Script starts here ############
CTM_ENV=${aapi_env}         # Set in  dockerfile ENV
CTM_SERVER=IN01    # SaaS Specific

# If CID does not work, use UNIQUE (and rename the variable CID)
# UNIQUE=$(head /dev/urandom | tr -dc A-Za-z | head -c 6 ; echo '')

# CID= Container ID
CID=$(cat /proc/1/cgroup | grep 'docker' | tail -1 | sed 's/^.*\///' | cut -c 1-12)
AGENT_NAME=$(hostname)-$CID
echo $AGENT_NAME

cd
pwd
env

# Setting sudo Mode. Comment next 2 lines if not needed
echo -e "\nSUDO_ENABLED  Y" >> ctm/data/OS.dat
echo "SUDO_ENABLED  Y"

echo Starting and registering Helix Control-M agent [$AGENT_NAME/$AGENT_TAG] with Control-M/Server [$CTM_SERVER], using environment [$CTM_ENV] 
echo Please wait for actions
ctm provision saas:agent::setup $AGENT_TAG $AGENT_NAME -e $CTM_ENV
if [ $? -ne 0 ]; then
    echo "Error registering agent $AGENT_NAME (tag:$AGENT_TAG) in Control-M"
	exit 1
fi

### Need the sourcing after installing agent to run utilities
source ~/.bash_profile
# Run the following to show it is working
shagent
ag_diag_comm
# Ensuring that agent is set to sudo. Since OS.dat is updated, it should not need agent restart
set_agent_mode -u controlm -o 3

# Setting traps for agent removal when docker stop is run
#     docker stop must be given extra time to avoid SIGKILL after 10 seconds.
#     if in doubt, read https://www.ctl.io/developers/blog/post/gracefully-stopping-docker-containers/
echo 'setting traps for signals SIGTERM and SIGUSR1'
trap "signal='SIGUSR1';sigtrapHandler" SIGUSR1
trap "signal='SIGTERM';sigtrapHandler" SIGTERM

echo Adding or creating a Helix Control-M hostgroup [$CTM_HOSTGROUP] with agent [$AGENT_NAME]
echo Please wait for actions
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP $AGENT_NAME -e $CTM_ENV
if [ $? -ne 0 ]; then
    echo "Error adding agent $AGENT_NAME to agent host group $CTM_HOSTGROUP on $CTM_SERVER"
	exit 1
fi


echo "Done setting up"
echo "Control-M Agent Available"
echo "Agent Name: $AGENT_NAME"
ctm run deploy_test_jobs.json > response.json
cat response.json 
ctm run status $(cat response.json| grep runId | cut -d : -f2 | awk -F\" '{print $2}')
echo "validations ran. entering infinite loop..."
echo "thanks for your patience!"

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

