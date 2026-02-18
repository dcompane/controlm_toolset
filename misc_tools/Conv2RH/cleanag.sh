#! /bin/bash

set -x

# Use single quotes to prevent variable expansion until the command is run as the agent user

sudo su - ctmag$1 -c 'shut-ag -p all -u $USER'

sudo su - ctmag$1 -c 'ctm config server:hostgroup:agent::delete dc01 DCO_RH_HOSTS $HOSTNAME-$USER'
sudo su - ctmag$1 -c 'ctm config server:agent::delete dc01 $HOSTNAME-$USER'

sudo userdel -rf ctmag$1
