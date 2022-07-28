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
20200319      Daniel Companeetz     Initial commit
"""

import json
from sys import exit
from urllib3 import disable_warnings
from urllib3.exceptions import NewConnectionError, MaxRetryError, InsecureRequestWarning
from pprint import pprint

# import ctm_python_client as controlm_client
import clients.ctm_api_client as controlm_client
# import controlm_py as controlm_client



class SaaSConnection(object):
    """
    Implements persistent connectivity for the Control-M Automation API
    :property api_client Implements the connection to the Control-M AAPI endpoint
    """
    logged_in = True

    def __init__(self, host='', port='443', endpoint='/automation-api',
                 aapi_token='', ssl=True, verify_ssl=False,
                 additional_login_header={'Accept': 'application/json'}):
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
        :param additionalLoginHeader: dict: login headers to be added to the AAPI headers (default={'Accept': 'application/json'})
        :return None
        """
        #
        configuration = controlm_client.Configuration()
        if ssl:
            configuration.host = 'https://'
            # Only use verify_ssl = False if the cert is self-signed.
            configuration.verify_ssl = verify_ssl
            if not verify_ssl:
                # This urllib3 function disables warnings when certs are self-signed
                disable_warnings(InsecureRequestWarning)
        else:
            configuration.host = 'http://'

        configuration.host = configuration.host + host + ':' + port + endpoint

        self.api_client = controlm_client.api_client.ApiClient(configuration=configuration)
        

        if additional_login_header is not None:
            for header in additional_login_header.keys():
                self.api_client.set_default_header(header, additional_login_header[header])

        try:
            self.api_client.default_headers.setdefault('x-api-key', aapi_token)
            self.logged_in = True
            #pprint( self.api_client)
            pass
        except (NewConnectionError, MaxRetryError, controlm_client.rest.ApiException) as aapi_error:
            print("Some connection error occurred: " + str(aapi_error))
            exit(42)


assert __name__ != "__main__", "Do not call me directly... This is existentially impossible!"