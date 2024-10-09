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

# Basic imports
import json
from sys import exit

# Importing Control-M Python Client
from ctm_python_client.core.workflow import *
from ctm_python_client.core.comm import *
from ctm_python_client.core.monitoring import Monitor
from aapi import *

# Set exit code for the procedure
exitrc = 0

config = {}

try:
    with open(file='controlm_toolset\\sendAlarmToScript\\Python\\np_BHOM\\evtvars.json', mode='r', 
            encoding='ascii') as config_data:
        config=json.load(config_data)
except FileNotFoundError as e:
    print('Failed opening evtvars.json')
    print('Exception: No config file (evtvars.json) found.')
    print(e)
    sys.exit(24)


# Load ctmvars
#   Set AAPI variables and create workflow object
host_name = config['ctmvars']['ctmaapi']
api_token = config['ctmvars']['ctmtoken']
ctm_is_helix = True if config['ctmvars']['ctmplatform'] == "Helix" else False
w = Workflow(Environment.create_saas(endpoint=f"https://{host_name}",api_key=api_token,))
monitor = Monitor(aapiclient=w.aapiclient)

server=input('Enter server name: ')
orderid=input('Enter Order ID: ')
runcount=input('Enter run count: ')


try:
    status = monitor.get_statuses( 
        filter={"jobid": f"{server}:{orderid}"})
    folder = status.statuses[0].folder
    order_date = status.statuses[0].order_date
    jobstatus = order_date = status.statuses[0].order_date

except TypeError as e:
        folder= "No status found to derive folder"
        order_date = "No status found to derive order date"
        print(f'Error: {e}')
        exitrc=42

print(f"Folder: {folder}")
print(f"Status: {str(status)}")


exit(exitrc)