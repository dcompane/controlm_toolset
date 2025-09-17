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
20250327      Daniel Companeetz     Initial work

"""

import sys
import json
from pprint import pprint
import requests
from requests.exceptions import RequestException
from urllib3 import disable_warnings
from urllib3.exceptions import InsecureRequestWarning


class AAPIConnection(object):
    """
    Implements persistent connectivity for the Control-M Automation API
    :property api_client Implements the connection to the Control-M AAPI endpoint
    """
    logged_in = True

    def __init__(self, host='', port='', endpoint='/automation-api',
                 aapi_token='', ssl=True, verify_ssl=False,
                 additional_login_header={}):
        """
        Initializes the CtmConnection object and provides the Automation API client.

        :param host: str: Control-M web server host name (preferred fqdn) serving the Automation API.
                               Could be a load balancer or API Gateway
        :param port: str: Control-M web server port serving the Automation API.
        :param endpoint: str: The serving point for the AAPI (default='/automation-api')
        :param ssl: bool: If the web server uses https (default=True)
        :param user: str: Login user
        :param password: str: Password for the login user
        :param verify_ssl: bool: If the web server uses self signed certificates (default=False)
        :param additionalLoginHeader: dict: login headers to be added to the AAPI headers
        :return None
        """
        #
        rc = 0
        configuration = {}
        if ssl:
            self.configuration[host] = 'https://'
        else:
            self.configuration[host] = 'http://'

        self.configuration[host] += f'{host}:{port}{endpoint}'

        self.configuration[verify_ssl] = verify_ssl

        self.configuration[headers] = {
                'x-api-key': f'{aapi_token}',
                'Accept': 'application/json'
                }

        for key, value in additional_login_header.items():
            self.configuration[headers] = {key: value}

        # create an instance of the API class
        api_client = ctm.ApiClient(configuration)
        self.api_client = ctm.AutomationApi(api_client=api_client)

    def CallAAPI(self, method="GET", AAPIClient=None, service=None, body=None, headers=None):
        """
        Calls the Control-M Automation API
        :param method: str: The method to be called
        :param body: dict: The body of the request
        :param headers: dict: The headers of the request
        :return: dict: The response from the API
        """
        # create an instance of the API class
        api_instance = AAPIClient(self.api_client)
        try:
            if body is None:
                api_response, status_code, api_headers = getattr(api_instance, method)().to_dict()
            else:
                api_response, status_code, api_headers = getattr(api_instance, method)(body=body).to_dict()
        except ctm.rest.ApiException as e:
            print("Exception when calling AutomationApi->%s: %s\n" % (method, e))
            raise SystemExit(e) from e

        return api_response
        


if __name__ == "__main__":

    disable_warnings(InsecureRequestWarning)

    # Source parameters
    source_host = '<enter your source url. example: client-aapi.sandbox.us1.controlm.com>'
    source_port = '443'
    source_auth = '<enter your source system token>'
    source_server = '<logical name of your Control-M source. Example: IN01>'
    source_url_hg = f'https://{source_host}:{source_port}/automation-api/config/server/{source_server}/hostgroups'
    source_url_ag = f'https://{source_host}:{source_port}/automation-api/config/server/{source_server}/agents'

    #Destination parameters
    dest_host = '<enter your destination url. example: ctm.clients.com>'
    dest_port = '8443'
    dest_auth = '<enter your destination system token>'
    dest_server = '<logical name of your Control-M source. Example: IN01>'
    dest_HG_Prefix = '<prefix to be used for new hostgroups. example: dco>'
    dest_dummy_agent = '<destination agent name to be used in all groups>'
    dest_body = json.dumps({ "host": f"{dest_dummy_agent}",
                                "participationRules": [
                                {
                                    "ruleType": "EVENT",
                                    "event": {
                                        "name": f"{dest_HG_Prefix}-<destination event for all groups>",
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
        raise SystemExit(e) from e

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
