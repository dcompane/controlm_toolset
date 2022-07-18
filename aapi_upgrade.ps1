#! /bin/pwsh

# MIT License
# Copyright (c) 2021 Daniel Companeetz, BMC Software, Inc.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# SPDX-License-Identifier: MIT
# For information on SDPX, https://spdx.org/licenses/MIT.html

param ([int] $myversion=9, [int] $myrelease=20, [int] $fix)
#NOTE: Do not forget to change the versions

# Comment next line if no debug information is required
Set-PSDebug -Trace 1

#From <https://www.red-gate.com/simple-talk/sysadmin/powershell/how-to-use-parameters-in-powershell/>
param ([int] $myversion=9, [int] $myrelease=21, [int] $fixpack)

# This is to run as see if the user isLocalAdmin
If($isWindows) {
    $outpath = $env:TEMP+"\padev_current.exe"
    $thisOS = "Windows"
    $thisArch="windows_x86_64"
    $thisExt=".exe"
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if(-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        write-host "This needs to be executed by an administrator. Exiting (rc=99)."
        exit 99
    }
}

#No validation if Linux. Assumes it is the EM User
If($isLinux) {
    $outpath = "/tmp/padev_current.exe"
    $thisOS = "Unix"
    $thisArch="Linux-x86_64"
    $thisExt="_INSTALL.BIN"
}

if ($fixpack -eq $null) {
    write-host "Please enter a fix pack. Assuming $myversion.$myrelease. Exiting (rc=42)."
    exit 42
} else {
    $fixpack = $fix.PadLeft(3,'0')
    $file_to_download="PADEV.$myversion.0.$myrelease.$fixpack"+"_"+$thisArch+$thisExt
    $url = "https://controlm-appdev.s3-us-west-2.amazonaws.com/release/v"+$myversion+"."+$myrelease+"."+$fix+"/output/"+$thisOS+"/"+$file_to_download
        #https://controlm-appdev.s3-us-west-2.amazonaws.com/release/v9.21.5/output/Windows/PADEV.9.0.20.005_windows_x86_64.exe
    write-host "Downloading from $url"
    Invoke-WebRequest -Uri $url -OutFile $outpath -SkipCertificateCheck
    write-host "Downloaded from $url"
    chmod 755 $outpath
    write-host "Starting installation of $outpath"
    Start-Process -Wait -Filepath "$outpath" -ArgumentList "-s -v"
    write-host "Completed installation of $outpath"
}
# Debuggone
Set-PSDebug -Trace 0
exit 0
