"""
(c) 2020 - 2023 Daniel Companeetz, BMC Software, Inc.
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
20230307      Daniel Companeetz     Initial commit
"""

from pprint import pprint
from sys import exit

from ctm_python_client.core.workflow import Workflow, WorkflowDefaults
from ctm_python_client.core.comm import Environment
from aapi.job import JobCommand
from aapi.condition import ConditionIn, ConditionOutDelete, ConditionOutAdd
from aapi import WaitForEvents, DeleteEvents, AddEvents, Folder

# Use the aapi_creds_sample.py and create an aapi_creds.py with the right values. 
from aapi_creds import host_name, aapi_token

my_environment = Environment.create_saas(endpoint=host_name, api_key=aapi_token)

# Create workflow (folder) object
workflow = Workflow(my_environment, 
    WorkflowDefaults(
        run_as='someuser',
        application='DCO',
        sub_application='DCO_AAPI_Events'     # defining someuser as the user to run the jobs by default
    )   # run_as is required
)

# Create job object with basic data
myJob = JobCommand('MyFirstJob', command='echo "Hello world!"', host='myHost')

# Add job to workflow
workflow.add(myJob, inpath='DCO_MyFirstFolder')

# Get folder object
myFolder = workflow.get('DCO_MyFirstFolder')

# Add an event to wait for on the folder
if not myFolder.wait_for_events_list:
    myFolder.wait_for_events_list.append(WaitForEvents('events_to_wait', events=[]))
myFolder.wait_for_events_list[-1].events.append(ConditionIn(event="FldrWait4Me", date="NoDate"))

# Delete an event when the folder ends on the folder
if not myFolder.delete_events_list:
    myFolder.delete_events_list.append(DeleteEvents('events_to_delete', events=[]))
myFolder.delete_events_list[-1].events.append(ConditionOutDelete(event="FldrWait4Me", date="NoDate"))

# Add an event when the folder exits on the folder
if not myFolder.add_events_list:
    myFolder.add_events_list.append(AddEvents('events_to_add', events=[]))
myFolder.add_events_list[-1].events.append(ConditionOutAdd(event="FldrSomeIsWaiting", date="NoDate"))


## Now work on the jobs

# Add an event to wait for 
if not myJob.wait_for_events_list:
    myJob.wait_for_events_list.append(WaitForEvents('events_to_wait', events=[]))
myJob.wait_for_events_list[-1].events.append(ConditionIn(event="JobWait4Me", date="NoDate"))

# Delete an event when the job ends
if not myJob.delete_events_list:
    myJob.delete_events_list.append(DeleteEvents('events_to_delete', events=[]))
myJob.delete_events_list[-1].events.append(ConditionOutDelete(event="JobWait4Me", date="NoDate"))

# Add an event when the job exits
if not myJob.add_events_list:
    myJob.add_events_list.append(AddEvents('events_to_add', events=[]))
myJob.add_events_list[-1].events.append(ConditionOutAdd(event="JobSomeIsWaiting", date="NoDate"))

# Run the build process (syntax check)
build=workflow.build()

if build.is_ok():
    print('The workflow is valid!')
    # If build is ok, deploy the folder (write to (Helix) Control-M)
    deploy=workflow.deploy()
    if deploy.is_ok():
        print('The workflow was deployed to Control-M!')
        rc=0
    else:
        # This was not tested as could not simulate a fail deploy with a successful build.
        print('The workflow was NOT deployed to Control-M, but built ok! (Really strange!)')
        pprint(deploy.errors)
        rc=2
else:
    print('The workflow is NOT valid!')
    pprint(build.errors)
    rc = 1

# set a breakpoint here to preserve variables for inspection if debugging... :-)
pass

exit(rc)
