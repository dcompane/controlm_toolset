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
20230201      Daniel Companeetz     Initial work
20230215      Daniel Companeetz     Misc. fixes

"""

### See send_mail function in extalert_functions

# Basic imports
import json
import sys
import logging
import smtplib
from pprint import pprint

# Importing Control-M Python Client
from ctm_python_client.core.workflow import *
from ctm_python_client.core.comm import *
from ctm_python_client.core.monitoring import Monitor
from aapi import *

# Importing functions
from extalert_snow_functions import args2dict
from extalert_snow_functions import init_dbg_log
from extalert_snow_functions import dbg_assign_var
from extalert_functions import send_mail

# To write the log and output to files for attaching.
import tempfile
import os
from os import getcwd, path
from socket import getfqdn


# To see if we need to set initial debug. If not, can be set at 'SNOWvars',
#    but logging will not be as throrugh in the beginning.
# need to pip install  python-dotenv
from dotenv import dotenv_values

# https://pysnow.readthedocs.io/en/latest/full_examples/create.html
from pysnow import Client as snow_cli


# Set exit code for the procedure
exitrc = 0

config = {}

# Initialize logging
dbg_logger, config = init_dbg_log()

pprint (config)

debug = True if config['DEBUG'].lower() == 'true' else False

try:
    dbg_logger.info('Opening field_names.json')
    with open('field_names.json') as keyword_data:
        json_keywords = json.load(keyword_data)
        dbg_logger.debug('Fields file is ' + str(json_keywords))
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
    keywords_json = dbg_assign_var( { {'eventType': 'eventType'}, {'id': 'alert_id'}, {'server': 'server'},
                    {'fileName': 'fileName'}, {'runId': 'runId'}, {'severity': 'severity'},
                    {'status': 'status'}, {'time': 'time'}, {'user': 'user'}, {'updateTime': 'updateTime'},
                    {'message': 'message'}, {'runAs': 'runAs'}, {'subApplication': 'subApplication'},
                    {'application': 'application'}, {'jobName': 'jobName'}, {'host': 'host'}, {'type': 'type'},
                    {'closedByControlM': 'closedByControlM'}, {'ticketNumber': 'ticketNumber'}, {'runNo': 'runNo'},
                    {'notes': 'notes'} }, "Default field names used internally", dbg_logger, debug)
    keywords = dbg_assign_var(['eventType:', 'id:', 'server:', 'fileName:', 'runId:', 'severity:', 'status:',
            'time:', 'user:' ,'updateTime:' ,'message: ' ,'runAs:' ,'subApplication:' ,'application:',
            'jobName:', 'host:', 'type:', 'closedByControlM:', 'ticketNumber:', 'runNo:', 'notes:'],
            'Default field names assigned.', dbg_logger, debug)

try:
    dbg_logger.info('Opening tktvars.json')
    with open('tktvars_dco.json') as config_data:
        config=json.load(config_data)
        dbg_logger.debug('Config file is ' + str(config_data))
except FileNotFoundError as e:
    dbg_logger.info('Failed opening tketvars.json')
    dbg_logger.info('Exception: No config file (tktvars.json) found.')
    dbg_logger.info(e)
    sys.exit(24)

if (config['pgmvars']['crttickets'] == 'no'):
    dbg_logger.info ('*' * 20 + ' Alert not sent to ticketing system.')
    dbg_logger.info()
    exitrc = 12
    sys.exit(exitrc)

#Set debug mode. It will be shown in the log. DO NOT POLLUTE!
if (config['pgmvars']['debug'] == 'yes'):
    debug = True
    dbg_logger.setLevel(logging.DEBUG)
    dbg_logger.debug('Startup logging level adjusted to debug by Config File')

if (config['pgmvars']['ctmattachlogs'] == 'yes'):
    ctmattachlogs = True
    dbg_logger.info ('Log and output will be attached to the ticket.')
else:
    ctmattachlogs = False
    dbg_logger.info ('Log and output will NOT be attached to the ticket.')

if (config['pgmvars']['addtkt2alert'] == 'yes'):
    addtkt2alert = True
    dbg_logger.info ('Ticket ID will be added to the alert.')
else:
    addtkt2alert = False
    dbg_logger.info ('Ticket ID will NOT be added to the alert.')

if (config['pgmvars']['ctmupdatetkt'] == 'yes'):
    ctmupdatetkt = True
    dbg_logger.info ('Updates will be sent to the system.')
else:
    ctmupdatetkt = False
    dbg_logger.info ('Updates will NOT be sent to the system.')


# Ticket variables from 'SNOWvars'.json
tktvars = 'SNOWvars'
tkt_url = dbg_assign_var(config[tktvars]['tkturl'], 'Ticketing URL',dbg_logger, debug)
tkt_rest_path = dbg_assign_var(config[tktvars]['tktpath'], 'Ticketing table path',dbg_logger, debug) # '/table/incident'
tkt_id_caller = config[tktvars]['tktsysidcaller']
tkt_attach_file=''
tkt_user = config[tktvars]['tktuser']
tkt_pass = config[tktvars]['tktpasswd']
#NewLine for SNOW messages
NL='\n';

# Configure SNow client
snow_client = snow_cli(instance=tkt_url, user=tkt_user, password=tkt_pass)
snow_incidents = snow_client.resource(api_path=tkt_rest_path)


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
dbg_logger.debug('params: ' + args)
dbg_logger.debug('dict is ' + str(alert))

# Exit if alert should not be sent.
if (ctmupdatetkt and alert[keywords_json['eventType']]):
    exitrc = 24
    sys.exit(exitrc)


#### Build Ticket fields
tkt_category=dbg_assign_var('Service Interruption', 'Ticket category', dbg_logger, debug)
tkt_urgency=dbg_assign_var('1', 'Ticket Urgency', dbg_logger, debug)
tkt_impact=dbg_assign_var('2', 'Ticket Impact', dbg_logger, debug)
tkt_watch_list=dbg_assign_var('dcompane@gmail.com', 'Ticket watchlist (SNow specific', dbg_logger, debug)
tkt_work_list=dbg_assign_var('dcompazrctm@gmail.com', 'Ticket worklist (SNow specific', dbg_logger, debug)
tkt_assigned_group=dbg_assign_var('CTM GROUP', 'Ticket assigned group (SNow specific)', dbg_logger, debug)
tkt_short_description=dbg_assign_var(f"{alert[keywords_json['jobName']]} {alert[keywords_json['message']]}",
                        'Ticket Short Description', dbg_logger, debug)

# Configure Helix Control-M AAPI client



# If the alert is about a job
alert_is_job = False
if(alert[keywords_json['runId']] != '00000'):
    alert_is_job = True
    job_log = \
        f"*" * 70 + NL + \
        f"Job log for {alert[keywords_json['jobName']]} OrderID: {alert[keywords_json['runId']]}" + NL+ \
        f"LOG includes all executions to this point (runcount: {alert[keywords_json['runNo']]}" + NL+ \
        f"NOTE: If ticket information is added to log, it is not shown here."+ NL+ \
        f"*" * 70 + NL

    job_output = \
        f"*" * 70 + NL + \
        f"" + NL+ \
        f"Job output for {alert[keywords_json['jobName']]} OrderID: {alert[keywords_json['runId']]}:" \
            f"{alert[keywords_json['runNo']]}" + NL+ \
        f"" + NL+ \
        f"*" * 70 + NL

    status = dbg_assign_var(monitor.get_statuses(
            filter={"jobid": f"{alert[keywords_json['server']]}:{alert[keywords_json['runId']]}"}), "Status of job", dbg_logger, debug)


#Order date has been simplified for this example. The orderDate should be taken from the job and not the first status.
# https://stackoverflow.com/questions/7079241/python-get-a-dict-from-a-list-based-on-something-inside-the-dict

radius = 3
direction = 3

tkt_comments =  \
            f"Agent Name                  : {alert[keywords_json['host']]} {NL}" + \
            f"Folder Name                 : {status.statuses[0].folder} {NL}" + \
            f"Job Name                    : {alert[keywords_json['jobName']]} {NL}" + \
            f"Order ID                    : {alert[keywords_json['runId']]} {NL}" + \
            f"Run number                  : {alert[keywords_json['runNo']]} {NL}" + \
            f"Order Date                  : {status.statuses[0].order_date} {NL} {NL}" + \
            f"Ticket Notes                : {alert[keywords_json['notes']]} {NL} {NL}" + \
            f"Job Output and Log are attached  {NL} {NL}" + \
            f"The job can be seen on the {'Helix' if ctm_is_helix else ''} " + \
            f"Control-M Self Service site. Click the link below. {NL}" + \
            f"{NL}" + \
            f"https://{ctmweb}/ControlM/Monitoring/Neighborhood/{alert[keywords_json['runId']]}_{radius}_{direction}?name={alert[keywords_json['jobName']]}"+ \
            f"&ctm={alert[keywords_json['server']]}&odate=&direction={direction}&radius={radius}&orderId={alert[keywords_json['runId']]}"+ \
            f"{NL}{NL}" if alert_is_job else "This alert is not job related"


tkt_work_notes = f"Ticket created automatically by {'Helix' if ctm_is_helix else ''} Control-M" + \
    (f" for {alert[keywords_json['server']]}:{alert[keywords_json['runId']]}::{alert[keywords_json['runNo']]}" if alert_is_job else "")

snow_payload= {'short_description': tkt_short_description,
    'assignment_group': tkt_assigned_group,
    'urgency': tkt_urgency,
    'impact': tkt_impact,
    'comments': tkt_comments,
    'watch_list': tkt_watch_list,
    'category': tkt_category,
    'caller_id': tkt_id_caller,
    'work_notes': tkt_work_notes,
    'work_notes_list': tkt_work_list
    }

    # Create a new incident record
result = snow_incidents.create(payload=snow_payload)

snow_sys_id = result.__getitem__('sys_id')
snow_incident_number =  result.__getitem__('number')

# Load AAPI variables and create workflow object if need to attach logs
if ctmattachlogs and alert_is_job:
    incident = snow_incidents.get(query={'number': snow_incident_number})
    log = dbg_assign_var(monitor.get_log(f"{alert[keywords_json['server']]}:{alert[keywords_json['runId']]}"), "Log of Job", dbg_logger, debug)

        # Change \n to CRLF on log and output
    #    Log will always exist but output may not
    job_log = (job_log + NL + log)

    try:
        # need to add code in case the output is not available
    #   Use status outputURI which should say there is no output.
        output = dbg_assign_var(monitor.get_output(f"{alert[keywords_json['server']]}:{alert[keywords_json['runId']]}",
            run_number=alert[keywords_json['runNo']]), "Output of job", dbg_logger, debug, alert_id)
        if output == None:
            output = f"*" * 70 + NL + "NO OUTPUT AVAILABLE FOR THIS JOB" + NL + f"*" * 70
    except:
        output = f"*" * 70 + NL + "NO OUTPUT AVAILABLE FOR THIS JOB" + NL + f"*" * 70
    finally:
       dbg_logger.info(f'RunID: {alert[keywords_json["runId"]]} RunNo {alert[keywords_json["runNo"]]}')


    job_output = (job_output + NL +  output)


    if output is None :
        output =f"*" * 70 + NL + "NO OUTPUT AVAILABLE FOR THIS JOB" + NL + f"*" * 70

    job_output = (job_output + NL +  output)

    file_log = f"log_{alert[keywords_json['runId']]}_{alert[keywords_json['runNo']]}.txt"
    file_output = f"output_{alert[keywords_json['runId']]}_{alert[keywords_json['runNo']]}.txt"

    # Write log
    # Declare object to open temporary file for writing
    tmpdir = tempfile.gettempdir()
    file_name =tmpdir+os.sep+file_log
    fh = open(file_name,'w')
    # content = job_log.replace('\n', '\r\n')
    content = job_log
    try:
        # Print message before writing
        dbg_logger.debug(f'Write data to log file {file_name}')
        # Write data to the temporary file
        fh.write(content)
        # Close the file after writing
        fh.close()
        # Attach to Incident
        incident.upload(file_path=file_name)
    finally:
        # Print a message before reading
        dbg_logger.debug("log data added to the ticket")

    os.remove(file_name)

    # Write output
    # Declare object to open temporary file for writing
    tmpdir = tempfile.gettempdir()
    file_name =tmpdir+os.sep+file_output
    fh = open(file_name,'w')
    # content = job_output.replace('\n', '\r\n')
    content = job_output
    try:
        # Print message before writing
        dbg_logger.debug(f'Write data to output file {file_name}')
        # Write data to the temporary file
        fh.write(content)
        # Close the file after writing
        fh.close()
        # Attach to Incident
        incident.upload(file_path=file_name)
    finally:
        # Print a message before reading
        dbg_logger.debug("output data added to the ticket")

    os.remove(file_name)

sys.exit(exitrc)
