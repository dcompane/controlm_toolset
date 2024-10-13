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

# Importing Control-M Python Client
from ctm_python_client.core.workflow import *
from ctm_python_client.core.comm import *
from ctm_python_client.core.monitoring import Monitor
from aapi import *

# Importing functions
from extalert_functions import args2dict
from extalert_functions import init_dbg_log
from extalert_functions import dbg_assign_var



# Set exit code for the procedure
exitrc = 0

config = {}

# Initialize logging
basedir = "C:\\Users\\dcomp\\OneDrive\\BMC\\controlm_toolset\\controlm_toolset\\sendAlarmToScript\\Python\\BHOM\\"
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
            "ctmOrderDate": status.statuses[item_no].order_date
             }


# Configure RITSM client

evt_headers = {
                'Authorization': f'apiKey {evt_apiKey}',
                'Content-Type': 'application/json'
            }

evt_endpoint = evt_url + evt_Path

response = requests.request(method="POST", url=evt_endpoint, headers=evt_headers,
             data=json.dumps([evt_payload]), verify=evt_verifySSL, timeout=(10,30)
              )


exit(0)

#Add comments to case worklog
updated_incident, status_code = itsm_client.add_worklog_to_incident(incident_id, evt_comments)

evt_provenance = f"Ticket sent from {getfqdn()}. Entry ID: {updated_incident['values']['Entry ID']}"

updated_incident, status_code = itsm_client.add_worklog_to_incident(incident_id, evt_provenance)


# Load AAPI variables and create workflow object if need to attach logs
#### Leaving the code in case we want to augment the alert with the log and output later.
##### Logic is not developed, but left behind from other effort
# if ctmattachlogs and alert_is_job and false:
#     log = dbg_assign_var(monitor.get_log(f"{alert[keywords_json['server']]}:{alert[keywords_json['runId']]}"), "Log of Job", dbg_logger, debug, alert_id)
#     job_log = (job_log + NL + log)


#     try:
#         output = dbg_assign_var(monitor.get_output(f"{alert[keywords_json['server']]}:{alert[keywords_json['runId']]}",
#             run_number=alert[keywords_json['runNo']]), "Output of job", dbg_logger, debug, alert_id)
#         if output == None:
#             output = f"*" * 70 + NL + "NO OUTPUT AVAILABLE FOR THIS JOB" + NL + f"*" * 70    
#     except:
#         output = f"*" * 70 + NL + "NO OUTPUT AVAILABLE FOR THIS JOB" + NL + f"*" * 70
#     finally:
#        dbg_logger.info(f'RunID: {alert[keywords_json["runId"]]} RunNo {alert[keywords_json["runNo"]]}')


#     job_output = (job_output + NL +  output)

#     tmpdir = tempfile.gettempdir()
#     file_log = f"log_{alert[keywords_json['runId']]}_{alert[keywords_json['runNo']]}_{alert_id}.txt"
#     file_output = f"output_{alert[keywords_json['runId']]}_{alert[keywords_json['runNo']]}_{alert_id}.txt"

#     # Write log
#     # Declare object to open temporary file for writing
#     file_name = dbg_assign_var(file_log, "Log Filename", dbg_logger, debug, alert_id)
#     content = job_log
#     try:
#         fh = open(tmpdir+os.sep+file_name,'w')
#         # Print message before writing
#         dbg_logger.debug(f'Write data to log file {tmpdir+os.sep+file_name}')
#         # Write data to the temporary file
#         fh.write(content)
#         # Close the file after writing
#         fh.close()
#         # Attach to Incident
#         updated_incident, status_code = itsm_client.attach_file_to_incident(incident_id, filepath=tmpdir, filename=file_name,
#                 details=f"{'Helix ' if ctm_is_helix else ''} Control-M Log file")
#     except Exception as ex:
#         message = f"Exception type {type(ex).__name__} occurred. Arguments:\n{str(ex.args)}"
#         dbg_logger.info(message)
#         exitrc = 30
#     finally:
#         # Print a message before reading
#         dbg_logger.debug("Log data section completed. Log may have been added to the ticket")

#     # Write output
#     # Declare object to open temporary file for writing
#     file_name = dbg_assign_var(file_output, "Output Filename", dbg_logger, debug, alert_id)
#     content = job_output
#     try:
#         fh = open(tmpdir+os.sep+file_name,'w')
#         # Print message before writing
#         dbg_logger.debug(f'Write data to output file {tmpdir+os.sep+file_name}')
#         # Write data to the temporary file
#         fh.write(content)
#         # Close the file after writing
#         fh.close()
#         # Attach to Incident
#         updated_incident, status_code = itsm_client.attach_file_to_incident(incident_id, filepath=tmpdir, filename=file_name,
#                 details=f"{'Helix ' if ctm_is_helix else ''} Control-M Output file")
#     except Exception as ex:
#         message = f"Exception type {type(ex).__name__} occurred. Arguments:\n{str(ex.args)}"
#         dbg_logger.info(message)
#         exitrc = 30
#     finally:
#         # Print a message before reading
#         dbg_logger.debug("Output data section completed. Output may have been added to the ticket")

# itsm_client.release_token()

# send_email = dbg_assign_var(config['pgmvars']['sendemail'], 'Send email',dbg_logger, debug)
# if send_email == "yes":
#     # Ticket variables from evtvars.json
#     smtp_url = dbg_assign_var(config['emailvars']['smtpurl'], 'SMTP URL',dbg_logger, debug)
#     smtp_port = dbg_assign_var(config['emailvars']['smtpport'], 'SMTP Port',dbg_logger, debug)
#     smtp_SSL = dbg_assign_var(config['emailvars']['smtpverifySSL'], 'SMTP SSL',dbg_logger, debug)
#     smtp_sender = dbg_assign_var(config['emailvars']['smtpsender'], 'SMTP Sender',dbg_logger, debug)
#     smtp_recipient = dbg_assign_var(config['emailvars']['smtprecipient'], 'SMTP Recipient',dbg_logger, debug)
#     smtp_username = dbg_assign_var(config['emailvars']['smtpuser'], 'SMTP User',dbg_logger, debug)
#     smtp_password = config['emailvars']['smtppasswd']

#     evt_work_notes = f"Email created automatically by {'Helix' if ctm_is_helix else ''} Control-M " + \
#              (f" for {alert[keywords_json['server']]}:{alert[keywords_json['runId']]}::{alert[keywords_json['runNo']]}"
#                      if alert_is_job else f"alert: {alert_id}")
#     evt_provenance = f"Email sent from {getfqdn()}. Entry ID: {updated_incident['values']['Entry ID']}"

#     evt_comments = evt_comments + NL * 2 + evt_work_notes + NL * 2 + evt_provenance

#     dbg_logger.info("Sending email")

#     send_mail(smtp_sender, [smtp_recipient], evt_short_description, evt_comments,
#                 files=[tmpdir+os.sep+file_log, tmpdir+os.sep+file_output],
#                 server=smtp_url, port=smtp_port, use_tls=smtp_SSL,
#                 username=smtp_username, password=smtp_password)

# if ctmattachlogs and alert_is_job:
#     try:
#         message = f"Removing files {file_log} and {file_output}"
#         dbg_logger.info(message)
#         os.remove(tmpdir+os.sep+file_log)
#         os.remove(tmpdir+os.sep+file_output)
#     except Exception as ex:
#         message = f"Exception type {type(ex).__name__} occurred. Arguments:\n{str(ex.args)}"
#         dbg_logger.info(message)
#         exitrc = 31

sys.exit(exitrc)