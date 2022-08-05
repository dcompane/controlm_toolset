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


from ctm_python_client.core.workflow import *
from ctm_python_client.core.comm import *
from ctm_python_client.core.monitoring import Monitor
from aapi import *

# for the management of the order date
from datetime import date, timedelta

yesterday = date.today() - timedelta(days=1)
order_date = yesterday.strftime('%y%m%d')

hostname='https://se-sanb0x-aapi.us1.controlm.com/automation-api'
api_key='UFJER0ZQOmNjZWQyNWUxLTFhN2QtNGYzMi1hNGYwLTg4MjgxMDE3NWY2MDpNNklMci9jODdXd1d3Wi9FTU1vWUxhMmlObTR2ZityNFBFUlBQUkJ4d2FnPQ=='

w = Workflow(Environment.create_saas(endpoint=hostname,api_key=api_key))

monitor = Monitor(w.aapiclient)
for status in monitor.get_statuses(filter={'order_date_from':order_date,'order_date_to':order_date}).statuses:
    print(f'Status for {status.name} - { status.job_id }:\n')
    print(f'{status}\n')
    if (status.type == 'Folder' or status.type == 'Sub-Table' ):
        print (f'{status.type} - skipping \n')
    else:    
        try:
            log = monitor.get_log(status.job_id)
            if log:
                print(f'Log for { status.name}:\n')
                print(log,'\n')

            
            output = monitor.get_output(status.job_id)
            if output:
                print(f'Output for { status.name}:\n')
                print(output,'\n')

        except Exception as e:
            print(f'Cannot get output for { status.name}')

        print('\n\n')        

exit(0)