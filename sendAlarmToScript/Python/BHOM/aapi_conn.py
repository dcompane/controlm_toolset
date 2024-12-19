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
20200319      Daniel Companeetz     Initial commit
"""

import json
from sys import exit
from urllib3 import disable_warnings
from urllib3.exceptions import NewConnectionError, MaxRetryError, InsecureRequestWarning
from pprint import pprint

try:
    #updated version
    import ctm_python_client as controlm_client
except:
    #github.com/dcompane/control-py.git
    import controlm_py

class CtmConnection(object):
    """
    Implements persistent connectivity for the Control-M Automation API
    :property api_client Implements the connection to the Control-M AAPI endpoint
    """
    logged_in = False

    def __init__(self, host='', port='', endpoint='/automation-api',
                 user='', password='',
                 ssl=True, verify_ssl=False,
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
        self.session_api = controlm_client.api.session_api.SessionApi(api_client=self.api_client)
        credentials = controlm_client.models.LoginCredentials(username=user, password=password)

        if additional_login_header is not None:
            for header in additional_login_header.keys():
                self.api_client.set_default_header(header, additional_login_header[header])

        try:
            api_token = self.session_api.do_login(body=credentials)
            self.api_client.default_headers.setdefault('Authorization', 'Bearer ' + api_token.token)
            self.logged_in = True
        except (NewConnectionError, MaxRetryError, controlm_client.rest.ApiException) as aapi_error:
            print("Some connection error occurred: " + str(aapi_error))
            exit(42)


    def __del__(self):
        if self.session_api is not None:
            try:
                self.logout()
            except ImportError:
                print('Network access for Logout unavailable due to python shutdown.')
                print(' Program termination occurred before deleting ApiClient object,')
                print(' which performs logout.')
                print('SECURITY RISK: Token will still be available to continue operations.')
                exit(50)

    def logout(self):
        if self.logged_in:
            try:
                self.session_api.do_logout()
                self.logged_in = False
            except controlm_client.rest.ApiException as e:
                raise("Exception when calling SessionApi->do_logout: %s\n" % e)

class SaaSConnection(object):
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
        # self.session_api = controlm_client.api.session_api.SessionApi(api_client=self.api_client)
        # credentials = controlm_client.models.LoginCredentials(username=user, password=password)

        if additional_login_header is not None:
            for header in additional_login_header.keys():
                self.api_client.set_default_header(header, additional_login_header[header])

        try:
            #api_token = self.session_api.do_login(body=credentials)
            self.api_client.default_headers.setdefault('x-api-key', aapi_token)
            self.logged_in = True
            pprint( self.api_client)
            pass
        except (NewConnectionError, MaxRetryError, controlm_client.rest.ApiException) as aapi_error:
            print("Some connection error occurred: " + str(aapi_error))
            exit(42)

