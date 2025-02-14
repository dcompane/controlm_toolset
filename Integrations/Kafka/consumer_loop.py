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
20241029      Daniel Companeetz     Initial work

"""
from sys import exit

# Imports from Confluent Kafka
from confluent_kafka.admin import AdminClient, NewTopic
from confluent_kafka import Consumer, Producer
from confluent_kafka import KafkaError, KafkaException


# import consumer_cloud
from consumer_loop_functions import basic_consume_loop, create_new_topics, write_messages

if __name__ == "__main__":
   

   #define the topics list
   topics = ["test43456", "test42345"]
   action = "Read"
   #  action = "Topic"
   #  action = "Write"
   #  action = "Read"
   #  action = "File"

   if action == "Topic":
      # Topic: Create a new topic in the Kafka queue
      topics=['test1','test2']
      retcode = create_new_topics(topics)
      
   # Write: Write a message to the topic
   elif action == "Write":
      messages=["test1", "test2"]
      retcode = write_messages(messages=messages, topic="tet")

   # Read and File are loops
   elif action == "Read" or action == "File":
   
      # define the topics list
      topics = ["tent"]
      # invoke the consumer loop[]
      retcode = basic_consume_loop(topics, action=action)

      if retcode == 0:
         print("Event reading cycle completed successfully")

   else:
      retcode = 13
      print(f"Action: {action} - Invalid action. Exiting with error {retcode}.")

exit(retcode)
