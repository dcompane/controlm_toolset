"""
(c) 2020 Daniel Companeetz
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
https://opensource.org/licenses/MIT

# SPDX-License-Identifier: MIT
For information on SDPX, https://spdx.org/licenses/MIT.html

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

# Tenant and credential
host_name = 'se-sanb0x-aapi.us1.controlm.com'
# host_name = '<Enter your tenant AAPI endpoint>"
# Example: myhelixcontrol-m-aapi.us1.controlm.com'
aapi_token = 'UFJER0ZQOmNjZWQyNWUxLTFhN2QtNGYzMi1hNGYwLTg4MjgxMDE3NWY2MDpNNklMci9jODdXd1d3Wi9FTU1vWUxhMmlObTR2ZityNFBFUlBQUkJ4d2FnPQ=='
# aapi_token = 'DFJER9ZQOmNjZWQyNWUxLTFhN2QtNGdzMi1hNGYwLTg4MjgxMDE3NWYgMDpNNklMci9jODdXd1d3Wi9FTU1vWUxhMmlObTR2ZityNFBFUlBQUkJ4d2FnPQ=='

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

