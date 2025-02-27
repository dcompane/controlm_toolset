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
from typing import Union
from confluent_kafka.admin import AdminClient, NewTopic
from confluent_kafka import Producer, Consumer
from confluent_kafka import KafkaError, KafkaException

from consumer_platform import conf, conf_admin

import controlm_py as ctm
from controlm_py.rest import ApiException
from aapi_conn import SaaSConnection

#Import AAPI connection parameters
from ctm_platform import ctmcli

def basic_consume_loop(topics, action="file", job_duration=10, cycle_time=5):
    '''
    basic loop for the consumer
    '''
        # Set start time
    start_time = time()

    retcode = 0
    msg_number = 0
    running = True

    try:
        # Subscribe to the topic
        consumer = Consumer(conf)
        consumer.subscribe(topics)

        # loop on the messages
        while running:
            # if there are no messages timeout is 1 second
            msg = consumer.poll(timeout=1.0)
            # if no messages
            if msg is None:
                if get_out_time(start_time,job_duration):
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
                    print(f"INFO: Topic: {msg.topic()} Partition: {msg.partition()} reached end at offset {msg.offset()}")
                elif msg.error().code() == KafkaError.UNKNOWN_TOPIC_OR_PART:
                    # Topic is not available
                    retcode = 5
                    print(f"ERROR: Topic {msg.topic()} or partition {msg.partition()} is not available to read or does not exist.")
                    print(f"Extiting with rc={retcode}.")
                    running = shutdown()
                elif msg.error():
                    # Unexpected error occured
                    retcode=6
                    print(f"ERROR: Unexpected error {msg.error()} occurred.")
                    running = shutdown()
            else:
                # there is at least one message
                msg_number += 1
                # print the message
                print(f"Message number {msg_number} received: {msg.value().decode('UTF-8')}")
                #decode msg from kafka object to string 
                # The message is a consumer object
                msg_decoded = msg.value().decode('UTF-8')

                # Action to be performed
                # File: Write a message to a file
                if action == "File":
                    # Write the message to a file
                    msg_process(msg_number,msg_decoded)
                    print("File created")

                # Read: Read the topic and post anything that comes as an event
                elif action == "Read":
                    if msg_decoded[0] == "{":
                        #if the first char is a "{",  it must be a dict
                        try:
                            msg_2_send = json.loads(msg_decoded)
                        except json.decoder.JSONDecodeError as e:
                            # Should never reach here!
                            print(f'THISMESSAGE: Error with the event: {msg_decoded}. Event not sent to Control-M. Exiting.')
                            print( '   The event must a json formatted string that starts with a "{" at the beginning of the string.')
                            print(f'Error: {e}')
                            print('Error encountered: exiting')
                            running=shutdown()

                    else:
                        #It's a string!
                        msg_2_send = msg_decoded

                    send_evt_2ctm(msg_2_send)
                    print("Event sent to CTM")

            if get_out_time(start_time, job_duration):
                print ("Max job duration reached. Exiting. rc=0")
                running=shutdown()

    finally:
        # Close down consumer to commit final offsets.
        consumer.close()
    
    return retcode

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
    if now_time > (start_time + job_duration * 60):
        # print (now_time, start_time + job_duration)
        get_out = True
    return get_out

def msg_process(number,message):
    '''
    docstring
    '''
    # Write the message (already string) to a file
    directory = f"{getenv('USERPROFILE')}\\Downloads"
    file_name = path.join(directory, f'file_{number}.txt')
    with open(file_name, 'w', encoding="utf-8") as file:
        file.write(message)
        print(f'Message number {number} was written to {file_name}')
    file.close()

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

    aapi_client = SaaSConnection(host=ctmcli['ctmhost'], port=ctmcli['ctmport'], 
                            aapi_token=ctmcli['ctmtoken'], ssl=ctmcli['ctmssl'], verify_ssl=ctmcli['ctm_verify_ssl'],
                            additional_login_header={'Accept': 'application/json'})

    run = ctm.api.run_api.RunApi(api_client=aapi_client.api_client)
    run.add_event(body=body, server=server)
    
def loop_duration ():
    '''
    docstring
    '''
    #the job duration will be different for the 1st run
    duration = 0
    runcount = getenv('RUNCOUNT')
    if runcount is None or runcount != 0:
        #the environment variable does not exist (should not be ever the case)
        #if it is a re-run (not the first run)
        duration = 15 * 60 

    # max duration is 23:59
    if duration == 0:
        job_duration = (23 * 60 + 59) * 60 # 23:59 hours in seconds.
    else:
        job_duration = duration

    print(f'Job Duration is set to {job_duration}')

    return job_duration

def create_new_topics(names: Union[str, list], partitions: int = 1, replication: int = 1):
    retcode = 0
    if isinstance(names, str):
        names = names.split(',')
    new_topics = [NewTopic(name, partitions, replication) for name in names]
    
    # Accessing admin create_topics via admin client 
    client = AdminClient(conf_admin)
    
    fs = client.create_topics(new_topics, validate_only=False)

    for topic, f in fs.items():
        try:
            f.result()  # The result itself is None
            print(f"Topic {topic} created")
        except KafkaException as e:
            k_e = e.args[ 0 ]
            print(f"Failed to create topic {topic}: {e}")    
            retcode = 10
            if k_e.code() == KafkaError.TOPIC_ALREADY_EXISTS:
                print(f"Topic '{topic}' already exists, skipping creation.")
            elif k_e.code() == KafkaError.BROKER_NOT_AVAILABLE:
                print(f"Failed to create topic '{topic}' due to unavailable broker: {e}")
            
    return retcode


def write_messages(messages: Union[str, list], topic):
    """Produce messages to a Kafka topic."""
    def error_cb(err):
        """Error callback for Kafka producer."""
        print(f"Error: {err}")

    def delivery_report(err, msg):
        """Delivery report callback for Kafka producer."""
        if err is not None:
            print(f"Message delivery failed: {err}")
        else:
            print(f"Message {msg.value()} delivered to {msg.topic()} [{msg.partition()}] at offset {msg.offset()}")

    def topic_exists(admin_client, topic_name):
        """Checks if a Kafka topic exists."""
        cluster_metadata = admin_client.list_topics()
        return topic_name in cluster_metadata.topics

        
    admin_client = AdminClient(conf_admin)
    conf_admin["error_cb"] = error_cb  # Set the error callback
    producer = Producer(conf_admin)

    retcode = 0
    if isinstance(messages, str):
        messages = messages.split(',')

    if not topic_exists(admin_client, topic):
        retcode = 15
        print(f"Topic '{topic}' does not exist. Cannot produce messages. Exiting with error {retcode}.")
        print(f"Create the topic '{topic}' first using the 'create_new_topics' function or ensure it exists.")
    else:
        for message in messages:
            try:
                producer.produce(topic, value=message, callback=delivery_report)
                producer.poll(0)  # Trigger delivery reports and handle errors
            except KafkaError as e:
                retcode = 11
                print(f"Error producing message: {e}")

        producer.flush()  # Ensure all messages are delivered
            
    return retcode