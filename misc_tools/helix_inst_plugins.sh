#! /bin/bash

# (c) 2021 - 2022 Daniel Companeetz, BMC Software, Inc.
# All rights reserved.

# BSD 3-Clause License

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

# # SPDX-License-Identifier: BSD-3-Clause
# For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html


# Purpose: install BMC Helix Control-M Plugins
# Input: The prefix of the plugin name



# Change Log
# Date (YMD)    Name                  What
# --------      ------------------    ------------------------
# 20221102      Daniel Companeetz     Initial commit

#set -x # uncomment if debug is needed

option=$1
rc=42

if [ ! -z $option ]; then
    if [ $option != "all" ]; then
        ctm provision install "${option}_plugin.Linux"
        rc=$?
    fi

   if [ $option != "all" ]; then
        rc=0
        plugins=($(ctm provision images Linux|grep _plugin|sed -e s/\"//g|sed -e s/,//))
        #echo $plugins
        #lines=$(ctm provision images Linux|grep _plugin|sed -e s/\"//g|sed -e s/,//|wc -l)
        #echo $lines
        for (( line=0; line<${#plugins[@]}; line++ ))
        do
            echo Starting installation of ${plugins[$line]}
            if [[ ${plugins[$line]} =~ "MFT_plugin.Linux" ||
                    ${plugins[$line]} =~ "SAP_plugin.Linux" ||
                    ${plugins[$line]} =~ "Airflow_plugin.Linux"
                ]]; then
                sudo ~/ctm/scripts/rc.agent_user stop   > /dev/null
                ctm provision install ${plugins[$line]} > /dev/null
                rc=$?
                sudo ~/ctm/scripts/rc.agent_user start  > /dev/null
            else
                ctm provision install ${plugins[$line]} > /dev/null
            fi

            if [ $rc == 0 ]; then
                echo Installation of ${plugins[$line]} completed correctly.
            elif [ $rc == 6 ]; then
                echo Installation of ${plugins[$line]} not completed. Plugin was already installed.
                echo OR
            #else
                echo Installation of ${plugins[$line]} completed unsuccessfully with rc=${rc}.
                rc=24      #There was at least one non-zero return code
            fi
        done
    fi
fi

exit $rc