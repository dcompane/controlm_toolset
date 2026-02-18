#! /bin/bash

set -x

function create_file {
    FILE_NAME=$1
    FILE_CONTENT=$2
    cat << EOF > $FILE_NAME
     $FILE_CONTENT
EOF
}


if [ ! -f ~/installed-versions.txt ]; then
    echo "There is no Control-M agent installed in this account"
    exit 42
fi


AGENT_NAME=$HOSTNAME-$USER
ctm_server=dc01

echo 'Create the .ssh directory if it does not exist'
if [ ! -d .ssh ] ; then
    mkdir .ssh
    chmod 700  ~/.ssh
fi

echo 'Add the ssh public key to the authorized keys file'
ssh_pub_key='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAYEAgjNb0Etkkyv4gSptEk+QLww37lsTR7lg7Pa5GTi3XizJNkc548TsisDEZ/WQdVMcs+UskiWjl96G+/pbh9cilOlWx2fQbe7Z5+EB2eYZ2w9UtXKL++F25Etpcxd814Qg/SzZKEO139MuFbD5EUnfhW+NyQ6HmgWqR4XESo0YUI5eU1XnxmEgGyaC+tk2zOIhKjoBm4sHs1uWutpXhwd+RneuMVmj3fGyL9nTn9hI7hL816Qmaj1v6vHpNs9R3sNN09NppLgUW4I0dmigNzhGd8bZUmtUoaGtU7D/BMRMEqG6JSZhdch6yWMYH+HctcOFtywm4RTpdw31xQVBYI7aK+L5IXHpAsLv0BBTDw4/z83nkhSUFH5suDi1q1ZiBa3bYO5NXAT2+wowbAi6qiFOBILw3dACzcqS3izpyLelwrgsgQD8IsnuaZPIlS2dlJbiFars91BY2HV8u5EFL3EJg5RtPX17H93KkpZyZXGdnNm3QVHu19M8kmWQ1J/7YBLj dc01 AH key'

echo $ssh_pub_key > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# expect that there will be only one hostgroup this agent is a member of
hg_2_remove=$(ctm config server:agents::get $ctm_server -s "agent=$AGENT_NAME"|jq -r .agents[0].hostgroups[0])

ctm config server:hostgroup:agent::delete $ctm_server $hg_2_remove $AGENT_NAME

#ctm config server:agent::delete $ctm_server $AGENT_NAME

conf2json="conf2conv.json"

create_file $conf2json "
{
   \"remotehost\" : \"$AGENT_NAME\",
   \"port\" : 22,
   \"agents\": [\"dc03-ctmag2\", \"dc03-ctmag3\"],
   \"encryptAlgorithm\": \"AES\",
   \"compression\": \"false\",
   \"authorize\": \"true\",
   \"convertExistingAgent\": \"true\"
}
"

ctm config server:agentlesshost::add $ctm_server -f $conf2json

echo "Uninstall agent in account $USER"
shut-ag -p all -u $USER
~/BMCINSTALL/uninstall/DRFZ4.9.0.22.050/uninstall.sh -silent

wget --no-check-certificate https://dc01:8444/automation-api/install_ctm_cli.py
python install_ctm_cli.py
echo ~/.local/bin >.bash_profile
echo PATH=~/.local/bin >.bash_profile
source .bash_profile