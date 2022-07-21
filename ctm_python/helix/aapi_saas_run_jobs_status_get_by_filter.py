"""
(c) 2020 Daniel Companeetz, BMC Software, Inc.
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
20220720      Daniel Companeetz     Initial commit
"""

import ctm_python_client as ctm
import  clients.ctm_saas_client as aapi
# from clients.ctm_saas_client.rest import ApiException
from clients.ctm_api_client.rest import ApiException
from aapi_saas_conn import SaaSConnection

# for the management of the order date
from datetime import date, timedelta

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


run_instance = aapi.RunApi(api_client=aapi_client.api_client)

limit = 2000

yesterday = date.today() - timedelta(days=1)
order_date = yesterday.strftime('%y%m%d')

api_response = run_instance.get_jobs_status_by_filter(limit=limit, order_date_from=order_date, order_date_to=order_date)

# api_response = run_instance.get_jobs_status_by_filter(limit=limit, jobname=jobname, 
#                 ctm=ctm, server=server, application=application, sub_application=sub_application, 
#                 host=host, status=status, folder=folder, description=description, 
#                 jobid=jobid, neighborhood=neighborhood, depth=depth, direction=direction, 
#                 order_date_from=order_date_from, order_date_to=order_date_to, from_time=from_time, 
#                 to_time=to_time, folder_library=folder_library, host_group=host_group, run_as=run_as, 
#                 command=command, file_path=file_path, file_name=file_name, workload_policy=workload_policy, 
#                 rule_based_calendar=rule_based_calendar, resource_mutex=resource_mutex, resource_semaphore=resource_semaphore, 
#                 resource_lock=resource_lock, resource_pool=resource_pool, held=held, folder_held=folder_held, cyclic=cyclic, deleted=deleted)

# Note that api_response returned is object, not dict!
# print(api_response.statuses)
#     But statuses is a list
# print (type (api_response.statuses))

for job in api_response.statuses:
    if (job.output_uri != 'Folder has no output' and job.number_of_runs != 0):
        print (job.job_id)
        status = run_instance.get_job_status(job.job_id)
        print (status)
        log = run_instance.get_job_log(job.job_id)
        print (log)
        if (job.output_uri != 'Folder has no output' and job.number_of_runs != 0):
            for run_no in range(job.number_of_runs):
                try:
                    output = run_instance.get_job_output(job_id=job.job_id, run_no=run_no)
                    print (output)
                except ApiException as e:
                    print("Exception when retrieving output. Likely no Output for the run", job.job_id,"run number", run_no)
        else:
            print("No output for job", job.job_id,"that run", job.number_of_runs, "times")

exit(0)