#!/bin/bash
#

# (c) 2020 - 2022 Daniel Companeetz, BMC Software, Inc.
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

# SPDX-License-Identifier: BSD-3-Clause
# For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html

# Author  : David Fernandez 
# Version : 1.0 (08/06/2021)
#
# Usage : ctm_export_all.sh [ctm-environment]
# Notes : - requires Automation API CLI installed and Environments configured
#         - when passing no parameters, it uses the default Environment
#

# Assign Environment
if [ $# -eq 0 ] ; then ctmenv=`ctm env show | grep current | cut -d " " -f 3`
else ctmenv=$1
fi

# Check if Environment exists and is working
ctm config servers::get -e $ctmenv > /dev/null 2>&1
if [ $? -eq 0 ] ; then echo Exporting definitions from Control-M Environment = $ctmenv
else echo ERROR : Control-M Environment $ctmenv does not exist or is not accesible & exit 1
fi

# Create export directory
exportdate=`date +%Y%m%d`
exportdir="$ctmenv"_$exportdate
mkdir $exportdir > /dev/null 2>&1

check_status()
{
   if [ $1 -eq 0 ] ; then
      echo OK : export successful for $object
   else
      echo ERROR : export for $object failed - check output file for details
      mv $exportdir/$object.json $exportdir/$object.error
   fi
}

# Export Folders and Jobs
object=jobs
ctm deploy jobs::get -s "ctm=*&folder=*" -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Calendars
object=calendars
ctm deploy calendars::get -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Centralized Connection Profiles
object=CCPs
ctm deploy connectionprofiles:centralized::get -s "type=*&name=*" -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Resource Pools
object=resource-pools
ctm run resources::get -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Resource Pool definitions
mkdir $exportdir/$object > /dev/null 2>&1
list=`cat $exportdir/$object.json | grep \"name\" | cut -d "\"" -f4`
for i in $list ; do
   ctm run resources::get -s "name=$i" -e $ctmenv > $exportdir/$object/$i.json 2>&1
done
echo OK : export successful for resource-pool definitions

# Export User list
object=users
ctm config authorization:users::get -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export User definitions
mkdir $exportdir/$object > /dev/null 2>&1
list=`cat $exportdir/$object.json | grep \"name\" | cut -d "\"" -f4`
for i in $list ; do
   ctm config authorization:user::get $i -e $ctmenv > $exportdir/$object/$i.json 2>&1
done
echo OK : export successful for user definitions

# Export Role list
object=roles
ctm config authorization:roles::get -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Role definitions
mkdir $exportdir/$object > /dev/null 2>&1
list=`cat $exportdir/$object.json | grep \"name\" | cut -d "\"" -f4`
for i in $list ; do
   ctm config authorization:role::get $i -e $ctmenv > $exportdir/$object/$i.json 2>&1
done
echo OK : export successful for role definitions

# Export Agents
object=agents
ctm config server:agents::get IN01 -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Hostgroups
object=hostgroups
ctm config server:hostgroups::get IN01 -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Hostgroup definitions
mkdir $exportdir/$object > /dev/null 2>&1
list=`cat $exportdir/$object.json | grep \" | cut -d "\"" -f2`
for i in $list ; do
   ctm config server:hostgroup:agents::get IN01 $i -e $ctmenv > $exportdir/$object/$i.json 2>&1
done
echo OK : export successful for hostgroup definitions

# Export System Settings
object=system-settings
ctm config systemsettings::get -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

# Export Secrets list
object=secrets
ctm config secrets::get -e $ctmenv > $exportdir/$object.json 2>&1
check_status $?

echo "Done! >> check results in directory $exportdir"
