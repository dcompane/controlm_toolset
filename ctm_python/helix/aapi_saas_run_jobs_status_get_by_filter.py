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
# hostname = '<Enter your tenant AAPI endpoint>"
# Example: https://myhelixcontrol-m-aapi.us1.controlm.com'
# api_key = '<Enter your user API token>"
# Example api_key = 'DFJETU1vWUxhMmlObTR2ZityNFBFUlBQUkJ4d2FnPQ=='
hostname='se-sanb0x-aapi.us1.controlm.com'
api_key='UFJER0ZQOmNjZWQyNWUxLTFhN2QtNGYzMi1hNGYwLTg4MjgxMDE3NWY2MDpNNklMci9jODdXd1d3Wi9FTU1vWUxhMmlObTR2ZityNFBFUlBQUkJ4d2FnPQ=='

# Create connection to the SaaS AAPI server
aapi_client = SaaSConnection(host=hostname,
                            aapi_token=api_key
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
    status = run_instance.get_job_status(job.job_id)
    if (job.output_uri != 'Folder has no output' and job.number_of_runs != 0):
        for run_no in range(job.number_of_runs):
            print (job.job_id)
            print (status)
            log = run_instance.get_job_log(job.job_id)
            print (log)
            try:
                # If the output fails do not print the rest
                output = run_instance.get_job_output(job_id=job.job_id, run_no=run_no)
                print (f'===== OUTPUT for {job.job_id}:{run_no} =====')
                print (output,"\n\n\n\n")
            except ApiException as e:
                print("Exception when retrieving output. Likely no Output for the run", job.job_id,"run number", run_no)
                print ("No output\n\n\n\n")
    else:
        print("No output for job", job.job_id,"that run", job.number_of_runs, "times")

