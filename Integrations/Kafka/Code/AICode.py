"""
(c) 2020 - 2024 Daniel Companeetz, BMC Software, Inc.
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
20241029      Daniel Companeetz     Initial work

"""

from time import sleep, time
from os import path
from os import getenv
import sys
import json
from confluent_kafka import KafkaError, KafkaException

import controlm_py as ctm
from controlm_py.rest import ApiException
# from aapi_conn import SaaSConnection

#Import AAPI connection parameters
#from ctm_platform import ctmcli

def basic_consume_loop(consumer, topics, action="file", job_duration=10, cycle_time=5):
    '''
    basic loop for the consumer
    '''
        # Set start time
    start_time = time()
    print(f"Job duration is {{job_duration}} seconds")

    msg_number = 0
    running = True
    file_list=[]

    try:
        # Subscribe to the topic
        consumer.subscribe(topics)

        # loop on the messages
        while running:
            # if there are no messages timeout is 1 second
            msg = consumer.poll(timeout=1.0)
            # if no messages
            if msg is None:
                if get_out_time(start_time, job_duration):
                    # comment next shutdown line to read again (endless loop?)
                    #   or leave uncommented to exit the loop and the program
                    print(f'No messages available in topic {topics} . ' +
                                'Time limit exceeded. Exiting. rc=0')
                    running = shutdown()
                else:
                    sleep(cycle_time)

                continue

            # If there are errors
            if msg.error():
                # End of Partition message is ok. Just record it and continue
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    # End of partition event
                    #sys.stderr.write('%% %s [%d] reached end at offset %d\n' %
                    #                 (msg.topic(), msg.partition(), msg.offset()))
                    sys.stderr.write(f"% {msg.topic()} {msg.partition()} reached end at offset {msg.offset()}\n")
                elif msg.error():
                    # Unexpected error occured
                    raise KafkaException(msg.error())
            else:
                # there is at least one message
                msg_number += 1
                # print the message
                print(f"Message number {msg_number} received: {msg.value().decode('UTF-8')}")
                #decode msg from kafka object to string 
                # The message is a consumer object
                msg_decoded = msg.value().decode('UTF-8')

                # FILE procedure starts
                if action == "File":
                    # Write the message to a file
                    file_sent = msg_process(msg_number,msg_decoded)
                    file_list.append(file_sent)
                    print("File created")

                # READ procedure starts
                elif action == "Read":
                    if msg_decoded[0] == "{":
                        #if the first char is a "{",  it must be a dict
                        try:
                            msg_2_send = json.loads(msg_decoded)
                        except json.decoder.JSONDecodeError as e:
                            # Should never reach here!
                            print(f'Error with the event: {msg_decoded}. Event not sent to Control-M.')
                            print( '   The event must a json formatted string and start with a "{" at the beginning of the string.')
                            print(f'Error: {e}')
                    else:
                        #It's a string!
                        msg_2_send = msg_decoded

                    send_evt_2ctm(msg_2_send)
                    print("Event sent to CTM")

                # Topic procedure starts
                elif action == "Topic":



            if get_out_time(start_time, job_duration):
                print ("Max job duration reached. Exiting. rc=0")
                running=shutdown()

            continue

    finally:
        # Close down consumer to commit final offsets.
        consumer.close()
        if action == "File":
                 print("Files", *file_list, sep =': ')


def shutdown():
    '''
    if loop needs to exit, set to false
    '''
    shut = False
    return shut

def get_out_time(start_time, job_duration):
    '''
    docstring
    '''
    now_time = time()
    get_out = False
    if now_time > start_time + job_duration:
        #print (now_time, start_time + job_duration)
        get_out = True
    return get_out

def msg_process(number,message):
    # Write the message to a file
    # The message is a consumer object
    #message = message.value().decode('UTF-8')
    # The text encased in double { } are Control-M Application Integrator parameters. 
    directory = r'{{file_path}}'
    file_name = path.join(directory, f'{{file_name_prefix}}_{{file_name_body}}_{number}.{{file_extension}}')
    with open(file_name, 'w') as file:
        file.write(message)
        print(f'Message number {number} was written to {file_name}')
    file.close()

    return file_name

def send_evt_2ctm(message):
    '''
    docstring
    '''
    # Send the message to CTM
    # The message is a consumer object and must be string or dict
    if isinstance(message, dict):
        evt = message["event"]
        odate = message["date"]
        server = message["server"]
    else: 
        #Must be strings
        evt, odate, server = message.split(':')
    
    body = {"name": f"{evt}","date": f"{odate}"}

    aapi_client = SaaSConnection(host=f'{{ControlMHost}}', port=f'{{ControlMPort}}', 
                            aapi_token=f'{{ControlMToken}}', ssl=True, verify_ssl=False,
                            additional_login_header={'Accept': 'application/json'})

    run = ctm.api.run_api.RunApi(api_client=aapi_client.api_client)
    print("Writing event to Control-M")
    run.add_event(body=body, server=server)
    
def Create_Topic(TopicName);


import json
from sys import exit
from urllib3 import disable_warnings
from urllib3.exceptions import NewConnectionError, MaxRetryError, InsecureRequestWarning
from pprint import pprint

#github.com/dcompane/control-py.git
import controlm_py as controlm_client

class SaaSConnection(object):
    """
    Implements persistent connectivity for the Control-M Automation API
    :property api_client Implements the connection to the Control-M AAPI endpoint
    """
    logged_in = True

    def __init__(self, host='', port='', endpoint='/automation-api',
                 aapi_token='', ssl=True, verify_ssl=False,
                 additional_login_header={}):
        """
        Initializes the CtmConnection object and provides the Automation API client.

        :param host: str: Control-M web server host name (preferred fqdn) serving the Automation API.
                               Could be a load balancer or API Gateway
        :param port: str: Control-M web server port serving the Automation API.
        :param endpoint: str: The serving point for the AAPI (default='/automation-api')
        :param ssl: bool: If the web server uses https (default=True)
        :param user: str: Login user
        :param password: str: Password for the login user
        :param verify_ssl: bool: If the web server uses self signed certificates (default=False)
        :param additionalLoginHeader: dict: login headers to be added to the AAPI headers
        :return None
        """
        #
        configuration = controlm_client.Configuration()
        if ssl:
            configuration.host = 'https://'
            # Only use verify_ssl = False if the cert is self-signed.
            configuration.verify_ssl = verify_ssl
            if not verify_ssl:
                # This urllib3 function disables warnings when certs are self-signed
                disable_warnings(InsecureRequestWarning)
        else:
            configuration.host = 'http://'

        configuration.host = configuration.host + host + ':' + port + endpoint

        self.api_client = controlm_client.api_client.ApiClient(configuration=configuration)
        # self.session_api = controlm_client.api.session_api.SessionApi(api_client=self.api_client)
        # credentials = controlm_client.models.LoginCredentials(username=user, password=password)

        if additional_login_header is not None:
            for header in additional_login_header.keys():
                self.api_client.set_default_header(header, additional_login_header[header])

        try:
            #api_token = self.session_api.do_login(body=credentials)
            self.api_client.default_headers.setdefault('x-api-key', aapi_token)
            print(f"Connected to Control-M {host}:{port}")
            self.logged_in = True
            pass
        except (NewConnectionError, MaxRetryError, controlm_client.rest.ApiException) as aapi_error:
            print("Some connection error occurred: " + str(aapi_error))
            exit(42)


########### M A I N  S T A R T S  H E R E ###########

from confluent_kafka import Consumer
# import consumer_cloud
# from consumer_platform import conf
# from consumer_loop_functions import basic_consume_loop

if __name__ == "__main__":
    #Initialize the consumer object

    conf = {'bootstrap.servers': '{{bootstrap_server}}:{{bootstrap_port}}',
        'group.id': '{{group_id}}',
        'auto.offset.reset': 'earliest'
        }

    consumer = Consumer(conf)

    #define the topics list
    topics = ["{{topic}}"]

    # invoke the consumer loop[]
    basic_consume_loop(consumer, topics, action="{{JobAction}}", job_duration={{job_duration}}, cycle_time=5)

    print("Event reading cycle completed successfully") 
