"""
(c) 2020 - 2022 Daniel Companeetz, BMC Software, Inc.
All rights reserved.

BSD 3-Clause License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# SPDX-License-Identifier: BSD-3-Clause
For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html

Change Log
Date (YMD)    Name                  What
--------      ------------------    ------------------------
20241004      Daniel Companeetz     Initial work

"""

# Basic imports
import json
import sys
import logging
import os
from os import getcwd, path
from socket import getfqdn
import requests
import urllib.parse

# Importing Control-M Python Client
from ctm_python_client.core.workflow import *
from ctm_python_client.core.comm import *
from ctm_python_client.core.monitoring import Monitor
from aapi import *
from ctm_python_client.core.comm import SaasAAPIClient

# Old Style Control-M python package from Swagger-Codegen
# install with pip install git+https://github.com/dcompane/controlm_py.git
# from aapi_conn import SaaSConnection

# Importing functions
from extalert_functions import args2dict
from extalert_functions import init_dbg_log
from extalert_functions import dbg_assign_var

# Set exit code for the procedure
exitrc = 0

config = {}

# Initialize logging
basedir = "/home/ctmem/custom/BHOM/"
dbg_logger, config = init_dbg_log()

# debug = True if config['DEBUG'].lower() == 'true' else False
debug = True

try:
    dbg_logger.info('Opening field_names.json')
    with open(f'{basedir}field_names.json') as keyword_data:
        json_keywords = json.load(keyword_data)
        dbg_logger.debug(f'Fields file is {str(json_keywords)}')
        keywords = []
        keywords_json = {}
        for i in range(len(json_keywords['fields'])):
            element=[*json_keywords['fields'][i].values()]
            keywords.append(element[0]+':')
            keywords_json.update(json_keywords['fields'][i])
except FileNotFoundError as e:
    # Template file with fields not found
    # Assuming all fields will be passed in standard order
    dbg_logger.info('Failed opening field_names.json. Using default')
    # keywords_json = dbg_assign_var( { {'eventType': 'eventType'}, {'id': 'alert_id'}, {'server': 'server'},
    # On-Prem from test on dc01
    #call_type: U alert_id: 11 data_center: dc01 memname: order_id: 00009 severity: V status: Noticed send_time: 20241003133003 last_user: emuser last_time: 20241004134738 message: Ended not OK run_as: ctmem sub_application: DCO_Test application: DCO job_name: DCO_OS_Job host_id: dc01 alert_type: R closed_from_em: ticket_number: run_counter: 2 notes:
    pass

    debug = True

    keywords_json = { 'eventType': 'eventType', 'id': 'alert_id', 'server': 'server',
                    'fileName': 'fileName', 'runId': 'runId', 'severity': 'severity',
                    'status': 'status', 'time': 'time', 'user': 'user', 'updateTime': 'updateTime',
                    'message': 'message', 'runAs': 'runAs', 'subApplication': 'subApplication',
                    'application': 'application', 'jobName': 'jobName', 'host': 'host', 'type': 'type',
                    'closedByControlM': 'closedByControlM', 'ticketNumber': 'ticketNumber', 'runNo': 'runNo',
                    'notes': 'notes' }
    keywords = dbg_assign_var(['eventType:', 'id:', 'server:',  'fileName:',  'runId:',  'severity:', 
            'status:', 'time:',  'user:',  'updateTime:',  'message: ',  'runAs:',  'subApplication:',
            'application:', 'jobName:', 'host:', 'type:', 'closedByControlM:', 'ticketNumber:', 'runNo:',
            'notes:'], 'Default field names assigned.', dbg_logger, debug)

try:
    dbg_logger.info('Opening evtvars.json')
    with open(f'{basedir}evtvars_dc01.json') as config_data:
        config=json.load(config_data)
        dbg_logger.debug('Config file is ' + str(config_data))
except FileNotFoundError as e:
    dbg_logger.info('Failed opening evtvars.json')
    dbg_logger.info('Exception: No config file (evtvars.json) found.')
    dbg_logger.info(e)
    sys.exit(24)

if (config['pgmvars']['crtevents'] == 'no'):
    dbg_logger.info ('*' * 20 + ' Alert not sent to ticketing system.')
    exitrc = 12

#Set debug mode. It will be shown in the log. DO NOT POLLUTE!
if (config['pgmvars']['debug'] == 'yes'):
    debug = True
    dbg_logger.setLevel(logging.DEBUG)
    dbg_logger.debug('Startup logging level adjusted to debug by Config File')
else:
    debug = False
    dbg_logger.setLevel(logging.INFO)
    dbg_logger.debug('Logging level is INFO')

if config['pgmvars']['ctmattachlogs'] == 'yes':
    ctmattachlogs = True
    dbg_logger.info ('Log and output will be attached to the ticket.')
else:
    ctmattachlogs = False
    dbg_logger.info ('Log and output will NOT be attached to the ticket.')

if (config['pgmvars']['addevt2alert'] == 'yes'):
    addevt2alert = True
    dbg_logger.info ('Ticket ID will be added to the alert.')
else:
    addevt2alert = False
    dbg_logger.info ('Ticket ID will NOT be added to the alert.')

if (config['pgmvars']['ctmupdateevt'] == 'yes'):
    ctmupdateevt = True
    dbg_logger.info ('Updates will be sent to the system.')
else:
    ctmupdateevt = False
    dbg_logger.info ('Updates will NOT be sent to the system.')


# Ticket variables from evtvars.json
evt_url = dbg_assign_var(f"https://{config['evtvars']['evturl']}:{config['evtvars']['evtport']}", 'URL',dbg_logger, debug)
evt_url = dbg_assign_var(f"https://{config['evtvars']['evturl']}", 'URL',dbg_logger, debug)
evt_verifySSL = dbg_assign_var(True if (config['evtvars']['evtverifySSL']== "yes") else False,"Verify SSL", dbg_logger, debug)
evt_apiKey = config['evtvars']['evtAPIKey'] # do not show in logs
dbg_assign_var("Adding the API Key", 'API KEY',dbg_logger, debug)

# Load ctmvars
#   Set AAPI variables and create workflow object
host_name = config['ctmvars']['ctmaapi']
api_token = config['ctmvars']['ctmtoken']
ctm_is_helix = True if config['ctmvars']['ctmplatform'] == "Helix" else False
w = Workflow(Environment.create_saas(endpoint=f"https://{host_name}",api_key=api_token,))
monitor = Monitor(aapiclient=w.aapiclient)

#   Set host for web url
ctmweb=config['ctmvars']['ctmweb']

# Evaluate alert and convert args to list
args = ''.join(map(lambda x: str(x)+' ', sys.argv[1:]))
# Convert Alert to dict using keywords.
alert = args2dict(args, keywords)

#breakpoint()

#print (type(args), args)

#print (type(alert),alert)

alert_id = alert[keywords_json['id']]
dbg_logger.debug(f'params: {args}')
dbg_logger.debug(f'dict is  {str(alert)}')

# Exit if alert should not be sent.
if (ctmupdateevt and (alert[keywords_json['eventType']] == 'U')):
    dbg_logger.info(f"Exiting while processing Update of alert  {str(alert)}")
    exitrc = 24
    sys.exit(exitrc)


#### Build Ticket fields
# If the alert is about a job
alertIsJob = False

if alert[keywords_json['runId']] != '00000':
    alertIsJob = True

    evt_Class = dbg_assign_var(config['evtvars']['evtClassJob'],
            "BHOM Event Class", dbg_logger, debug)
    evt_Path =  dbg_assign_var(config['evtvars']['evtPathJob'],
            "BHOM Event Class", dbg_logger, debug)
    try:
        status = dbg_assign_var(monitor.get_statuses(
            filter={"jobid": f"{alert[keywords_json['server']]}:{alert[keywords_json['runId']]}"}),
            "Status of job", dbg_logger, debug, alert_id)
        # Read the results like below examples
        # folder = status.statuses[0].folder
        # order_date = status.statuses[0].order_date

    except TypeError as e:
            folder= "No status found to derive folder"
            order_date = "No status found to derive order date"

#Order date has been simplified for this example. The orderDate should be taken from the job and not the first status.
# https://stackoverflow.com/questions/7079241/python-get-a-dict-from-a-list-based-on-something-inside-the-dict


for item_no in range (0, status.returned):
    if ( not (status.statuses[item_no].type == 'Folder' or
            status.statuses[item_no].type == 'SubFolder')):
        break

radius = 3
direction = 3

evt_parms = {
            "name": alert[keywords_json['jobName']],
            "ctm": alert[keywords_json['server']],
            "odate": '',
            "direction": direction,
            "radius": radius,
            "orderId": alert[keywords_json['runId']],
            "mapView": "TileView"
            }

evt_qry = urllib.parse.urlencode(evt_parms)

#https://dc01:8443/ControlM/Monitoring/Neighborhood/0002p_5_3?name=DCO_OS_Job%231&ctm=dc01&odate=&direction=3&radius=5&orderId=0002p&mapView=TileView
#https://dc01:8443/ControlM/Monitoring/Neighborhood/0002p_3_3?name=DCO_OS_Job#2&ctm=dc01&odate=&direction=3&radius=3&orderId=0002p&mapView=TileView
evt_weburl = f"https://{ctmweb}/ControlM/Monitoring/Neighborhood/{alert[keywords_json['runId']]}_{radius}_{direction}?{evt_qry}"

evt_payload = {
            "CLASS": evt_Class,
            # UNKNOWN, OK, INFO, WARNING, MINOR, MAJOR, CRITICAL
            "severity": 'MINOR' if alert[keywords_json['severity']] == 'R'    
                   else 'MAJOR' if alert[keywords_json['severity']] == 'U'    
                   else 'CRITICAL' if alert[keywords_json['severity']] == 'V' 
                   else 'UNKNOWN', 
            "msg": alert[keywords_json['message']],
            "details": f"{'Helix ' if ctm_is_helix else ''}Control-M Job " +
                       f"{alert[keywords_json['jobName']]} " +
                       f"{alert[keywords_json['message']]}. " +
                       f"Job ID: {alert[keywords_json['server']]}:{alert[keywords_json['runId']]}" +
                       f"::{alert[keywords_json['runNo']]}",
            "source_identifier": alert[keywords_json['server']],
            "source_hostname": alert[keywords_json['server']],
            "ctmAlertId": alert[keywords_json['id']],
            "ctmAlertType": alert[keywords_json['eventType']],
            "ctmApplication": alert[keywords_json['application']],
            "ctmClosedFromEM":alert[keywords_json['closedByControlM']],
            "ctmDataCenter": alert[keywords_json['server']],
            "ctmFolder": status.statuses[item_no].folder,
            "ctmFolderID": status.statuses[item_no].folder_id,
            "ctmJobCyclic": 'Yes' if status.statuses[item_no].cyclic else 'No',
            "ctmJobHeld": 'Yes' if status.statuses[item_no].held else 'No',
            "ctmJobID": status.statuses[item_no].job_id,
            "ctmJobName": alert[keywords_json['jobName']],
            "ctmJobType": status.statuses[item_no].type,
            # "ctmMemName": status.statuses[item_no].type,
            "ctmMessage": alert[keywords_json['message']],
            "ctmNodeid": alert[keywords_json['host']],
            "ctmNotes": alert[keywords_json['notes']],
            "ctmOrderId": alert[keywords_json['runId']],
            "ctmOwner": alert[keywords_json['runAs']],
            "ctmRunCounter": alert[keywords_json['runNo']],
            "ctmseverity": 'MINOR' if alert[keywords_json['severity']] == 'R'    
                   else 'MAJOR' if alert[keywords_json['severity']] == 'U'    
                   else 'CRITICAL' if alert[keywords_json['severity']] == 'V' 
                   else 'UNKNOWN',
            "ctmStatus": alert[keywords_json['status']],
            "ctmSubApplication": alert[keywords_json['subApplication']],
            "ctmTicketNumber": alert[keywords_json['ticketNumber']],
            "ctmTime": alert[keywords_json['time']],
            "ctmUpdateTime": alert[keywords_json['updateTime']],
            "ctmUpdateType": alert[keywords_json['eventType']],
            "ctmUser": alert[keywords_json['user']],
            "ctmLogUri": status.statuses[item_no].log_uri,
            "ctmOutputUri": status.statuses[item_no].output_uri,
            "ctmJobURL": evt_weburl,
            "ctmOrderDate": status.statuses[item_no].order_date,
            "ctmEvtProvenance": f"Event sent from {getfqdn()}"
             }


# Configure BHOM client

evt_headers = {
                'Authorization': f'apiKey {evt_apiKey}',
                'Content-Type': 'application/json'
            }

evt_endpoint = evt_url + evt_Path

response = dbg_assign_var(requests.request(method="POST", url=evt_endpoint, headers=evt_headers,
             data=json.dumps([evt_payload]), verify=evt_verifySSL, timeout=(10,30)
              ), 'Response from BHOM', dbg_logger, debug, alert[keywords_json['id']]
              )


dbg_logger.info(f"Response is: {str(response)}")
dbg_logger.info(f"Exiting program")
exit(exitrc)
