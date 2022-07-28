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


Input: a file name
Output, a table with the names defined in the program, and the line numbers where they were used.

Change Log
Date (YMD)    Name                  What
--------      ------------------    ------------------------
20200620      Daniel Companeetz     Initial commit
"""

import json
from sys import exit
#Control-M Python API can be found at https://github.com/dcompane/controlm_py
import controlm_py as ctm
from controlm_py.rest import ApiException
from aapi_conn import CtmConnection
from pprint import pprint

host_name = 'yourhost.bmc.com'
host_port = '8443'
endpoint = r'/automation-api'
aapi_user = 'CTMAPI'
aapi_password = 'ctmtickets'
host_ssl = True          # server using https only
aapi_verify_ssl = False  # False if server using self-signed SSL certs

# Create connection to the AAPI server
aapi_client = CtmConnection(host=host_name,port=host_port, 
                            user=aapi_user,password=aapi_password,
                            ssl=host_ssl, verify_ssl=aapi_verify_ssl,
                            additional_login_header={'Accept': 'application/json'})

deploy_instance = ctm.api.deploy_api.DeployApi(api_client=aapi_client.api_client)


# Search criteria
jobTypeName = "" # str |  (optional)   
jobTypeId = "" # str |  (optional)   

try:
    # Get deployed jobs that match the search criteria.
    api_response = deploy_instance.get_deployed_ai_jobtypes() #(job_type_name=jobTypeName, job_type_id=jobTypeId)
        
except ApiException as e:
    print("Exception when calling DeployApi->get_deployed_folders_new: %s\n" % e)
except NameError as e:
    print("Exception: The API returned an error when calling DeployApi->get_deployed_folders_new: %s\n" % e)

for index in range(len(api_response.jobtypes)):
        print(api_response.jobtypes[index].job_type_id)

aapi_client.logout()
