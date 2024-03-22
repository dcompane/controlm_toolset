#! /bin/bash
# (c) 2020 - 2024 Daniel Companeetz, BMC Software, Inc.
# All rights reserved.
#
# BSD 3-Clause License
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
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
#
# SPDX-License-Identifier: BSD-3-Clause
# For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html

# Change Log
# Date (YMD)    Name                  What
# --------      ------------------    ------------------------
# 20240318      Daniel Companeetz     Initial work

# ==================================
# Usage: use the notification destination
#        The message should be in two parts separated by space:
#        -->event DATE<--
#           where DATE is ODAT STAT MMDD

echo $*

export event=`echo $2|awk '{print $1}'`
export odat=`echo $2|awk '{print $2}'`
export log=`echo $2|awk '{print $3}'`

if [ ".$log" == ".Y" ]; then
   set -x
   currdir=`dirname $0`
   currdate=`date "+%Y%m%d"`
   currtime=`date "+%H%M%S"`
   logfile=$currdir\/$currdate-$currtime-$event.txt

   echo Current date: $currdate >> $logfile
   echo Current time: $currtime >> $logfile
   echo Parameters: $* >> $logfile
   ctm run event::add IN01 $event $odat >> $logfile 2>&1
   exit $?
else
   ctm run event::add IN01 $event $odat
fi
