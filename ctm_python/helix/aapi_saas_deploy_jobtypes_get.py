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

import ctm_python_client as ctm
import  clients.ctm_saas_client as aapi
# from clients.ctm_saas_client.rest import ApiException
from clients.ctm_api_client.rest import ApiException
from aapi_saas_conn import SaaSConnection

from sys import exit

# Use the aapi_creds_sample.py and create an aapi_creds.py with the right values. 
from aapi_creds import host_name, aapi_token

# Create connection to the SaaS AAPI server
aapi_client = SaaSConnection(host=host_name,
                            aapi_token=aapi_token
                            )

deploy_instance = aapi.DeployApi(api_client=aapi_client.api_client)


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

