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

Input: No input. ensure to modify the alertIDs you want to modify
Output: printed confirmation from the response

Change Log
Date (YMD)    Name                  What
--------      ------------------    ------------------------
20210323      Daniel Companeetz     Initial commit
"""

import json
from sys import exit
#Control-M Python API can be found at https://github.com/dcompane/controlm_py
import controlm_py as ctm
from controlm_py.rest import ApiException
from aapi_conn import CtmConnection

host_name = 'vl-aus-ctm-em01.ctm.bmc.com'
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

run_instance = ctm.api.run_api.RunApi(api_client=aapi_client.api_client)

jobid = 'psctms:0c2gt' # str |  (optional)

api_response = run_instance.get_jobs_status_by_filter(jobid=jobid)

print("Print complete response")
print(api_response)

if( api_response != 0 ) {
    print("Print native AAPI returned objects")
    print("Job ID: " + api_response.statuses[0].job_id)
    print("Description: " + api_response.statuses[0].description)
    print("Job ID: " + api_response.statuses[1].job_id)
    print("Description: " + api_response.statuses[1].description)

    print()

    print("Print after converting to dict")
    result = {}
    result=api_response.to_dict()
    print("Job_id: " + result['statuses'][0]['job_id'])
    print("Description: " + result['statuses'][0]['description'])
    print("Job_id: " + result['statuses'][1]['job_id'])
    print("Description: " + result['statuses'][1]['description'])
} else {
    
}
aapi_client.logout()