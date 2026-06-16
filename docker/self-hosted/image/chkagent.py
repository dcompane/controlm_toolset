#!/usr/bin/env python


# (c) 2020 - 2026 Daniel Companeetz, BMC Software, Inc.
# All rights reserved.

# BSD 3-Clause Licenses

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# SPDX-License-Identifier: BSD-3-Clause
# For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html

"""
This script sets up a Flask web server with two endpoints: 
    /chkagent and /ctmping. 
Each endpoint runs a specific command 
    (chkagent: shagent 
    ctmping: ctm config server:agent::ping dc01 dc01
    respectively) 
and returns the output in JSON format. 
The server uses HTTPS with a self-signed certificate, which must be generated before running the script. 
Invoke as insecure (curl -k) if you want to ignore the self-signed certificate warning.
The script also includes error handling to return appropriate HTTP status codes based on 
the command execution results.
200 if the command executes successfully (return code 0),
400+rc from the command if the command returns a non-zero code

"""

import os
import subprocess
import socket
from flask import Flask, jsonify

app = Flask(__name__)

# Define the static command to run
STATIC_COMMAND1 = ["shagent"]
STATIC_COMMAND2 = ["ctm", "config", "server:agent::ping", 
                    os.environ.get('CTM_SERVER'), os.environ.get('AGENT_NAME')]

@app.route("/chkagent", methods=["GET"])
def ping():
    """Run the shagent command and return its output in JSON format."""
    try:
        # Run the command and capture output
        result = subprocess.run(
            STATIC_COMMAND1,
            capture_output=True,
            text=True,
            check=False
        )

        # Prepare JSON response
        response_data = {
            "command": " ".join(STATIC_COMMAND1),
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "return_code": result.returncode
        }

        # Determine HTTP status code
        if result.returncode == 0:
            return jsonify(response_data), 200
        else:
            status_code = min(400 + result.returncode, 599)
            return jsonify(response_data), status_code

    except Exception as e:
        return jsonify({
            "error": str(e),
            "command": " ".join(STATIC_COMMAND2)
        }), 500

@app.route("/ctmping", methods=["GET"])
def ctmping():
    """Run the ctm config server:agent::ping command and return its output in JSON format."""
    try:
        # Run the command and capture output
        result = subprocess.run(
            STATIC_COMMAND2,
            capture_output=True,
            text=True,
            check=False
        )

        # Prepare JSON response
        response_data = {
            "command": " ".join(STATIC_COMMAND2),
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "return_code": result.returncode
        }

        # Determine HTTP status code
        if result.returncode == 0:
            return jsonify(response_data), 200
        else:
            status_code = min(400 + result.returncode, 599)
            return jsonify(response_data), status_code

    except Exception as e:
        return jsonify({
            "error": str(e),
            "command": " ".join(STATIC_COMMAND2)
        }), 500

if __name__ == "__main__":
    # Ensure cert and key exist
    CERT_FILE = "cert.pem"
    KEY_FILE = "key.pem"

    if not (os.path.exists(CERT_FILE) and os.path.exists(KEY_FILE)):
        print(f"❌ SSL certificate or key not found: {CERT_FILE}, {KEY_FILE}")
        print("Generate them with:")
        print(f"  openssl req -x509 -newkey rsa:4096 -keyout {KEY_FILE} -out {CERT_FILE} -days 365 -nodes")
        exit(1)

    # Run Flask with HTTPS
    # Change debug to False in production
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
        ssl_context=(CERT_FILE, KEY_FILE)
    )

