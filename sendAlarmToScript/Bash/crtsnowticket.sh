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

#Change log
# 2018 10 03    dcompane, BMC   Initial release
# 2018 10 19    dcompane, BMC   Added AAPI ctm log and output retrieval and attachment to SNOW case
# 2019 01 16	dcompane, BMC	Adding license to enable distribution
# 2019 01 17	dcompane, BMC	Adding comments for future work


# script to take ctm alerts and send to ServiceNow via API
#Instructions and comments
#    Uses joboutput.pl ensure it is available in $JOBOUTLOG variable
#Invoke from CTM EM
#    Set appropriate EM Parameters
#    Expects the notes field, but can be empty.
#This is a shell script that uses Service Now REST APIs (Table, Attachment).
#    Script logs in to Service Now and creates and updates a ticket with log and output attachments
#    Does not allow for update of tickets after initial creation (future work).
#    Uses “curl” to submit requests.
#    The output is not parsed or cleaned up, other than replacing \n with CRLF for Windows viewing.
#
#OPTIONS
#    Parameters are passed per standard Control-M processes.
#
#DEFAULTS
#   TO BE DOCUMENTED
#
#FUTURE WORK
#    Remove request for log and output when alerts are not job related
#    Allow for update of tickets when closed or modified on the EM alerts.
#    Allow disabling of SNOW sumbission by setting a file from a job,
#        instead of changing EM parameters or modifying the script as below.
#            Log alerts as not submitted if submission is disabled.
#    Add description and other fieldsa
#        use ctm deploy jobs::get -s "ctm=psctm&folder=DCO_FTPGP"
#        and jq to get the right pieces
#        ctm deploy jobs::get -s "ctm=psctm&folder=DCO_FTPGP" | jq -r .DCO_FTPGP.DCO_FT_PGP.Description
#        ctm deploy jobs::get -s "ctm=<datacenter>&folder=<folder>" | jq -r .<folder>.<jobname>.Description
#        jq -r will provide the description without quotes
#
#NOTES FOR FUTURE WORK
# Update case or close when handled
#    It is easy to do close of change a ticket if the ticketing system API allows it, as it is the case with Service Now
#    To close a case in the case of service now,  something like the below would need to be sent
#    PUT https://devXXXX.service-now.com/api/now/table/incident/<TicketSysID>
#    Using a payload such as
#    Payload - {"close_code":"Closed/Resolved By Caller","state":"7","caller_id":"<CallerSysID>",
#        "close_notes":"API: Alert handled in Control-M by user $fromAlertLastUser with notes: $fromAlertNotes"}
#    The problem is how to retrieve the ticket sys id.
#    In the code, we can retrieve it from the log if we identify the proper alertid or orderid and runcount
#    Then, filter (grep) the log and select the appropriate entry.
#      (if multiple tickets were created for a job, they will all be in the same log).


####FUNCTIONS
#----------------------------
write_log_file () {

    # field names and values are sent via the Control-M/EM gateway
    #  and written to $LOG_FILE

    ####DC Maybe use a system timestamp instead of the ticket one to ensure we can see delays and such.
    tsmp=`echo "" | ts "%d@%H:%M:%.S"`

    log_line="echo [${tsmp:0:15}:] ===> ALERTSCRIPT: ${TIME_V},${ALERT_ID_V},${CONTROLM_V},${JOB_NAME_V},${MEMNAME_V},${APPLICATION_V},${GROUP_V},${NODE_ID_V},${ORDER_ID_V},${RUN_COUNT_V},${MESSAGE_V},${INC_ID},${SYS_ID}"

    if [ "$log_after_tkt" == "yes" ]; then
       $log_line >> $log_file
    fi

    # Always written to the CTM gateway log (comment if not desired)
    $log_line
}

#----------------------------
build_attach_url () {

    # $1 MUST be $SYS_ID (always expected)
    # $2 MUST be file to attach (always expected)

    SNOW_ATTACHFILE="${SNOW_ATTACHURL}&table_sys_id=$1&file_name=$2"

}


#----------------------------
addjsonkey () {
# Adds a key to a json

    local key2chg=$1
    local newvalue=$2
    local json2chg=$3

    local jsonout=`jq ". + {\"${key2chg}\":${newvalue}}" <<< ${json2chg}`

    echo "${jsonout}"

}
####END OF FUNCTIONS


###### MAIN Program starts here

#**********************************************************
#**********************************************************
# THIS MUST BE SET FOR THE SPECIFIC INSTALLATION
#    EDIT THE FILE TO REFLECT THE ENVIRONMENT
#    USE A JSON FORMATTER TO ENSURE GOOD STYLE
#    DO NOT REPEAT TAGS ACROSS SETS.

scriptdir=`dirname $0`
CONFIG_FILE="${scriptdir}/tktvars.json"

#**********************************************************
#**********************************************************
# Use the CONFIG_FILE (see the variable below for location)
#    There will be an entry on the GTW log when this occurs.
#**********************************************************
crtticket=`jq -r .pgmvars.crttickets $CONFIG_FILE ` 
if [ "${crtticket}" == "no" ]; then
   echo "******************** Alert below not sent to ticketing system."
   echo $@
   exit 0
fi


#Set debug mode. It will be shown in the Gateway log. DO NOT POLLUTE!
debug=`jq -r .pgmvars.debug $CONFIG_FILE`
if [ "${debug}" == "yes" ]; then
    set -x
fi

## Log file variables
log_dir=`jq -r .pgmvars.log_dir $CONFIG_FILE`
# If directory does not exist, create it
log_file=`jq -r .pgmvars.log_file $CONFIG_FILE` 
log_file="${log_dir}/${log_file}"
capture_alerts=`jq -r .pgmvars.capturealerts $CONFIG_FILE`
alerts_file=`jq -r .pgmvars.capturealertsfile $CONFIG_FILE`
alerts_file="${log_dir}/${alerts_file}"
if [ "${capture_alerts}" == "yes" ]; then
    if [ ! -e "${log_dir}" ]; then
         mkdir -p ${log_dir}
    fi
    echo $@ >> ${alerts_file}
fi

#### PARAMETERS PASSED TO THIS PROGRAM
## This section will assign the arguments passed from Control-M/EM to
# human readable variables. These come in as command line arguments, not STDIN
#
# VAR_V is the Value for the associated Field Name
#  The odd numbered parameters are parameter names not needed for this program
# NOTE: The last data field is visible only if the SendAlertNotesSnmp parameter is set to 1

## This section checks if the alert being sent from Control-M/EM is
# for an update to an existing alert, and exits without action
# ex: if someone Handles or Notices an alert on the Alert Screen, we
# don't want another ticket sent
UPDATE_TYPE_F=${1}
UPDATE_TYPE_V=${2%% }
#Exit if alert is not original.
#    There will be an entry on the GTW log when this occurs.
if [ "${UPDATE_TYPE_V}" = "U" ]; then
  echo "******************** Updated alert. Not sent to SNOW."
  echo $@
  exit 0
fi

## Added All fields
# Only value fields are used
ALERT_ID_V=${4%% }
CONTROLM_V=${6%% }

#Stop processing if datacenter is excluded in config file.
#  spaces in the if around values are on purpose
excludedDC=`jq -r .pgmvars.excludedDC $CONFIG_FILE`
if [[ " ${excludedDC} " =~ " $CONTROLM_V " ]]; then
  echo "******************** Excluded CTM datacenter. Not sent to SNOW."
  echo $@
  exit 0
fi

# DO NOT CONTINUE  PROCESSING IF MORE THAN "allowedRuns" are in process.
#   The routine below does not work. Needs to allow to complete processing.
#allowedRuns=`jq -r .pgmvars.allowedRuns $CONFIG_FILE`
#pgmname=`basename $0`
#currentRuns=`ps -ef | grep $pgmname | wc -l`
#while [ $allowedRuns -le $currentRuns ]; do
#    sleep 2
#    currentRuns=`ps -ef | grep $pgmname | wc -l`
#done

MEMNAME_V=${8%% }
ORDER_ID_V=${10%% }
SEVERITY_V=${12%% }
STATUS_V=${14%% }
TIME_V=${16%% }
LASTUSER_V=${18%% }
LASTTIME_V=${20%% }
MESSAGE_V=${22%% }
OWNER_V=${24%% }
GROUP_V=${26%% }
APPLICATION_V=${28%% }
JOB_NAME_V=${30%% }
NODE_ID_V=${32%% }
ALERTTYPE_V=${34%% }
CLOSEDFROMEM_V=${36%% }
TICKET_V=${38%% }
RUN_COUNT_V=${40%% }
NOTES_V=${42%% }

#### PROGRAM VARIABLES

## Service Now API variables
SNOW_URL=`jq -r .tktvars.tkturl $CONFIG_FILE`
SNOW_INCTABLE="/api/now/table/incident"
SNOW_ATTACHURL="/api/now/attachment/file?table_name=incident"
SNOW_ATTACHFILE=""
SNOW_USER=`jq -r .tktvars.tktuser $CONFIG_FILE`
SNOW_PASS=`jq -r .tktvars.tktpasswd $CONFIG_FILE`
#NewLine for SNOW messages
NL="\\n";

##Program Variables
JOB_STATUS=""
DATE4URL=${TIME_V:2:6}
log_after_tkt=`jq -r .pgmvars.log_after $CONFIG_FILE`


## Control-M variables
#Not used when AAPI is used
ctmqrypgm=`jq -r .ctmvars.jobqrypgm $CONFIG_FILE`
ctmweb=`jq -r .ctmvars.ctmweb $CONFIG_FILE`
ctmtype=`jq -r .ctmservers.$CONTROLM_V $CONFIG_FILE`
ctmattachlogs=`jq -r .pgmvars.ctmattachlogs $CONFIG_FILE`
ctmaudit="-a subject=SNMP2SCRIPT_API&description=Generated_by_the_ticketing_script_sample"
addtkt2log=`jq -r .pgmvars.addtkt2log $CONFIG_FILE`
# Lines commented as ctm CLI is being used
#ctmaapi=`jq -r .ctmvars.ctmaapi $CONFIG_FILE`
#ctmuser=`jq -r .ctmvars.ctmuser $CONFIG_FILE`
#ctmpasswd=`jq -r .ctmvars.ctmpasswd $CONFIG_FILE`

#### Build Ticket fields
TKT_CALLER=`jq -r .tktvars.tktsysidcaller $CONFIG_FILE`
TKT_CATEGORY="Service Interruption"
TKT_URGENCY="1"
TKT_IMPACT="2"
TKT_WATCH_LIST="dcompane@hotmail.com"
TKT_WORK_LIST="dcompazrctm@hotmail.com"
TKT_ASSIGNED_GROUP="CTM GROUP"
TKT_SHORT_DESCRIPTION="${JOB_NAME_V} ${MESSAGE_V}"


## Get output and Log
#Log is needed to get job odate and build the proper SLS url

#### Build CTM Output and CTM Log. oid is "00000" for non-jobs such as alert for agent unavailable
if [ "${ORDER_ID_V}" != "00000" ]; then


    # Get the log of the failed job via the AAPI implementation command.
    JOB_LOG="/tmp/${ORDER_ID_V}.${RUN_COUNT_V}.log.txt"
    echo "Job log for ${JOB_NAME_V} OrderID: ${ORDER_ID_V}"                    > $JOB_LOG
    echo "LOG includes all executions to this point (runcount: $RUN_COUNT_V)"  >>$JOB_LOG
    echo "NOTE: If ticket information is added to log, it is not shown here."  >>$JOB_LOG
    echo "*************************************************************"       >>$JOB_LOG
    # Next line assumes AAPI CLI is installed
    $ctmqrypgm run job:log::get $CONTROLM_V:$ORDER_ID_V $ctmaudit  2>>$JOB_LOG >>$JOB_LOG
    echo "*************************************************************"       >>$JOB_LOG
    # Convert LF to CRLF
    sed -i 's/$/\r/' $JOB_LOG
		


    # Get the output of the failed job via the AAPI implementation command.
    JOB_OUT="/tmp/${ORDER_ID_V}.${RUN_COUNT_V}.out.txt"
    echo "Job output for ${JOB_NAME_V} OrderID: ${ORDER_ID_V}"                 > $JOB_OUT
    echo "OUTPUT includes only this execution (runcount: $RUN_COUNT_V)"        >>$JOB_OUT
    echo "*************************************************************"       >>$JOB_OUT
    # Next line assumes AAPI CLI is installed. Needs runcount on distributed.
    $ctmqrypgm run job:output::get $CONTROLM_V:$ORDER_ID_V $RUN_COUNT_V $ctmaudit 2>>$JOB_OUT >>$JOB_OUT
    echo "*************************************************************"       >>$JOB_OUT
    # Convert LF to CRLF
    sed -i 's/$/\r/' $JOB_OUT


    #Odate taken from the first line of the job log
    if [ "$ctmtype" == "dist" ]; then
        #DIST: 00:15:06 13-Nov-2018  ORDERED JOB:14179; DAILY SYSTEM, ODATE 20181113                           5065
        # Odate is yyyymmdd on "dist" 
        DATE4URL=`grep "ORDERED JOB:" $JOB_LOG | awk -F"ODATE" '{print $2}' | awk '{print $1}'`
        DATE4URL=${DATE4URL:2:6}

    else
        #MF  : 16:26:33 20-Nov-2018  JOB DCOMFTST OID=020C4 ODATE 181120 TASK=RDWDXC  /BMCB/CTM9AS    - PLACED ON AJF -   GRO    DCO_MFTEST
        # Odate is yymmdd on "dist" 
        DATE4URL=`grep "JOB ${JOB_NAME_V} OID=${ORDER_ID_V} ODATE" $JOB_LOG | awk -F"ODATE" '{print $2}' | awk '{print $1}' | sort -u`

    fi

    #Getting the status to obtain the folder name.
    job_status=`$ctmqrypgm run job:status $CONTROLM_V:$ORDER_ID_V`
    folder=`echo $job_status|jq -r .folder`    

    ####THE TICKET WILL SHOW LIKE BELOW:
    #  Note: not all alerts are job related. The information below is only for jobs.
    #    Make the script as simple or complex as needed.

                    TKT_COMMENTS="Agent Name                  : ${NODE_ID_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Folder Name                 : ${folder} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Job Name                    : ${JOB_NAME_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Order ID                    : ${ORDER_ID_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Run number                  : ${RUN_COUNT_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Order Date                  : ${DATE4URL} ${NL} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Ticket Notes                : ${NOTES_V} ${NL} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Job Output and Log are attached  ${NL} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} The job can be seen on the Control-M Self Service site. Click the link below. ${NL}" 
    TKT_COMMENTS="${TKT_COMMENTS} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} ${ctmweb}/ControlM/#Neighborhood:id=${ORDER_ID_V}&ctm=${CONTROLM_V}&name=${JOB_NAME_V}"
    TKT_COMMENTS="${TKT_COMMENTS}&date=${DATE4URL}&direction=3&radius=3"
    TKT_COMMENTS="${TKT_COMMENTS} ${NL} ${NL}"

    TKT_WORK_NOTES="Ticket created automatically by Control-M for ${CONTROLM_V}:${ORDER_ID_V}::${RUN_COUNT_V}"

else
    ctmattachlogs="no"

    TKT_COMMENTS=""
    TKT_WORK_NOTES="Ticket created automatically by Control-M for ${CONTROLM_V}"
fi

 ####THE TICKET HAVE THIS IN ALL ADDITIONAL COMMENTS
#  Note: not all alerts are job related. The information below is for non-jobs.
#    Make the script as simple or complex as needed.
TKT_COMMENTS="${TKT_COMMENTS} Control-M Server            : ${CONTROLM_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Date & Time                 : ${TIME_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Message                     : ${MESSAGE_V} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} Alert ID:                   : ${ALERT_ID_V} ${NL} ${NL}"
    TKT_COMMENTS="${TKT_COMMENTS} ${NL} ${NL}"


#### Watch List and Work Notes List:
#  For SNOW users registered on this instance,
#  do not use email addresses, but use the sys_id instead.
#  For nonSNOW users, (trading partners or external associates without a SNOW account) use email address.
#  watch or work notes list users with a SNOW ID, need the sys_id in order to see ticket,
#      else only get email.

## curl command to send formatted alert to SN
#reference https://docs.servicenow.com/bundle/london-application-development/page/integrate/inbound-rest/concept/c_TableAPI.html#r_TableAPI-POST
CURL_PAYLOAD="{'short_description':'${TKT_SHORT_DESCRIPTION}','assignment_group':'${TKT_ASSIGNED_GROUP}','urgency':'${TKT_URGENCY}','impact':'${TKT_IMPACT}','comments':'${TKT_COMMENTS}', 'watch_list':'${TKT_WATCH_LIST}', 'category':'${TKT_CATEGORY}', 'caller_id':'${TKT_CALLER}', 'work_notes': '${TKT_WORK_NOTES}', 'work_notes_list':'${TKT_WORK_LIST}'}"

CURL_RESPONSE=`curl -s  ${SNOW_URL}${SNOW_INCTABLE} \
   --user "${SNOW_USER}:${SNOW_PASS}" \
   --request POST \
   --header "Accept:application/json" \
   --header "Content-Type:application/json" \
   --data "${CURL_PAYLOAD}"`

#attachmet the job output log to the incident
#get the sys_id from the curl response

SYS_ID=`echo $CURL_RESPONSE | jq -r .result.sys_id`
INC_ID=`echo $CURL_RESPONSE | jq -r .result.number`


# write the alert to the autoticket.log file
write_log_file

#### Add an entry with the ticket and sysid to the job log after the fact.
# Assumes that there is an agent on the same server and that the em user has access to the ctmshout utility


if [ "${addtkt2log}" == "yes" ]; then
    shoutmssg="ServiceNow ticket created for ${CONTROLM_V}:${ORDER_ID_V}:${RUN_COUNT_V} (alert:${ALERT_ID_V}) is $INC_ID (sys_id:$SYS_ID)"
    outcmd=`sudo su - ctmagent -c "ctmshout -DEST IOALOG -ORDERID ${ORDER_ID_V} -MESSAGE \"${shoutmssg}\""`
fi

# If it was a job, attach output and log (runcount will be more than 0)
if [ "${ctmattachlogs}" == "yes" ]; then
    build_attach_url $SYS_ID $JOB_OUT
    CURL_RESPONSE=`curl -s ${SNOW_URL}${SNOW_ATTACHFILE} \
         --user "${SNOW_USER}:${SNOW_PASS}" \
         --request POST \
         --header "Accept: application/json" \
         --header "Content-Type:multipart/form-data" \
         --data-binary "@$JOB_OUT"`
 
    build_attach_url $SYS_ID $JOB_LOG
    CURL_RESPONSE=`curl -s ${SNOW_URL}${SNOW_ATTACHFILE} \
        --user "${SNOW_USER}:${SNOW_PASS}" \
        --request POST \
        --header "Accept: application/json" \
        --header "Content-Type:multipart/form-data" \
        --data-binary "@$JOB_LOG"`

    rm $JOB_OUT $JOB_LOG $JOB_STATUS
fi

exit 0
