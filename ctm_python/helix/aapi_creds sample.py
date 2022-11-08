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
20221108      Daniel Companeetz     Initial commit

Usage: copy this file to aapi_creds.py
"""




# Tenant and credential
host_name = 'sandbox-aapi.us1.controlm.com'
# host_name = '<Enter your tenant AAPI endpoint>"
# Example: myhelixcontrol-m-aapi.us1.controlm.com'
aapi_token = 'DFJER9ZQOmNjZWQyNWUsxLTFhN2QtNGdzMihfucgj1hNGYwLTg4MjgxMDE3NWYgMDpNNklMci9jODdXd1d3Wi9FTU1vWUxhMmlObTR2ZityNFBFUlBQUkJ4d2FnPQ=='


assert __name__ != "__main__", "Do not call me directly... This is existentially impossible!"