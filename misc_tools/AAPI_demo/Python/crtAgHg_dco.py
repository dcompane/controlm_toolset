"""
(c) 2020 - 2024 Daniel Companeetz, BMC Software, Inc.
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

import sys
import json
import requests
from pprint import pprint
from requests.exceptions import RequestException
from urllib3 import disable_warnings
from urllib3.exceptions import NewConnectionError, MaxRetryError, InsecureRequestWarning


if __name__ == "__main__":

    disable_warnings(InsecureRequestWarning)

    # Source parameters
    source_host = 'se-dev-aapi.sandbox.us1.controlm.com'
    source_port = '443'
    source_auth = 'UFJEU0xDOjdlMjk0ZTExLTk1YjYtNGQ1Yi1iNDJmLWQ2YzMzMTkxYmViNTovMkdzWFZkMW5aS2d5NVUvU1JXVGxhcVZ4aVlVNElhWjZ4cWNyUXF2Q0RJPQ=='
    source_server = 'IN01'
    source_url_hg = f'https://{source_host}:{source_port}/automation-api/config/server/{source_server}/hostgroups'
    source_url_ag = f'https://{source_host}:{source_port}/automation-api/config/server/{source_server}/agents'

    #Destination parameters
    dest_host = 'dc01'
    dest_port = '8443'
    dest_auth = 'b25QcmVtOmJlNzA5MzExLTcxZmEtNDIzZi1iZTJjLTE4ZTdhZjg4YzhjMg=='
    dest_server = 'dc01'
    dest_HG_Prefix = 'lum'
    dest_dummy_agent = 'dc01-ctmagent'
    dest_body = json.dumps({ "host": f"{dest_dummy_agent}",
                                "participationRules": [
                                {
                                    "ruleType": "EVENT",
                                    "event": {
                                        "name": "DCO_Never_ADD",
                                        "runDate": "NoDate" }
                                } ]
                            } )

    payload = {}
    headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-api-key': f'{source_auth}'
    }

    try:
        api_response = requests.request("GET", source_url_hg, headers=headers, data=payload, timeout=10)
        source_result = json.loads(api_response.content)
    except RequestException as e:
        print(f"Error getting hostgroups: {e}")
        raise SystemExit(e) from e

    headers['x-api-key'] = dest_auth
    for hostgroup  in source_result:
        if hostgroup[0:3] != dest_HG_Prefix :
            print(f"{hostgroup} -> {dest_HG_Prefix}-{hostgroup}")
            dest_HG = f"{dest_HG_Prefix}-{hostgroup}"

            # add hostgroup
            dest_url = f'https://{dest_host}:{dest_port}/automation-api/config/server/{dest_server}/hostgroup/{dest_HG}/agent'
           
            try:
                api_response = requests.request("POST", dest_url, headers=headers, data=dest_body, verify=False, timeout=10)
                pprint(api_response)
                pprint(json.loads(api_response.content))
            except RequestException as e:
                print(f"Error adding hostgroup {dest_HG}: {e}")
                raise SystemExit(e) from e

    # And now do the hostgroups
    headers['x-api-key'] = source_auth
    try:
        api_response = requests.request("GET", source_url_ag, headers=headers, data=payload, timeout=10)
        source_result = json.loads(api_response.content)
    except RequestException as e:
        print(f"Error getting agents: {e}")
        raise SystemExit(e)  from e

    for agent in source_result['agents']:
        if (agent['nodeid'][0:3]) == 'dco':
            print(f"{agent['nodeid']} -> {dest_HG_Prefix}-{agent['nodeid']}")
            dest_HG = f"{dest_HG_Prefix}-{agent['nodeid']}"

             # add hostgroup
            dest_url = f'https://{dest_host}:{dest_port}/automation-api/config/server/{dest_server}/hostgroup/{dest_HG}/agent'
            headers['x-api-key'] = dest_auth
            try:
                api_response = requests.request("POST", dest_url, headers=headers, data=dest_body, verify=False, timeout=10)
                pprint(api_response)
                pprint(json.loads(api_response.content))
            except RequestException as e:
                print(f"Error adding hostgroup {dest_HG}: {e}")
                raise SystemExit(e) from e
