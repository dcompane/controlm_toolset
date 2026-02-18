#! /bin/bash
# (c) 2020 - 2022 Daniel Companeetz, BMC Software, Inc.
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

# NOTE NOTE NOTE 
#This is the result of converting a PowerShell script to Bash using Copilot. 
# Some adaptations were needed, so the result may be cludgy and not very clean.
# Please review and test before using this working sample.


# Comment second line if no debug information is required

if [ x$1 == "xy" ]; then
    set -x
    debug=y
fi

host_name=`hostname -f`
host_port=8444


# Usage:
#   ./upgrade_padev.sh [y|n]
#   Pass "y" to enable debug tracing. Default: "n".

DEBUG="${1:-n}"

if [[ "$DEBUG" == "y" ]]; then
  set -x xtrace
fi

# --- Helpers ---

extract_semver() {
  # Extract first x.y.z pattern from a string; print empty if none
  local s="$1"
  if [[ "$s" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    printf "%s.%s%03d\n" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
  else
    printf "\n"
  fi
}

pad3() {
  printf "%03d" "$1"
}

# --- End of Helpers ---

HOSTNAME_VAL="$host_name"
HOSTPORT="$host_port"

# Fetch current build from local Automation API
#Control-M LD libraries are not compatible with curl, so we set to /lib64 temporarily
oldldlib=$LD_LIBRARY_PATH
LD_LIBRARY_PATH=/lib64
build_time_txt=$(curl -ks "https://${HOSTNAME_VAL}:${HOSTPORT}/automation-api/build_time.txt")

if [[ "$DEBUG" == "y" ]]; then
  echo "Raw build_time.txt content:"
  printf '%s\n' "$build_time_txt"
fi

# Extract version from build string
current_build_raw="${build_time_txt:17}"
current_build="$(extract_semver "$current_build_raw")"
#if [[ -z "$current_build" ]]; then
  current_build="$(extract_semver "$build_time_txt")"
fi
echo $current_build
if [[ "$DEBUG" == "y" ]]; then
  echo "Derived current build: $current_build"
fi
exit

# Fetch latest version from S3
latest_txt="$(curl -ks "https://controlm-appdev.s3.us-west-2.amazonaws.com/release/latest/version.txt")"
latest_version="$(extract_semver "$latest_txt")"

echo $latest_txt
echo $latest_version


if [[ "$DEBUG" == "y" ]]; then
  echo "Raw latest version content:"
  printf '%s\n' "$latest_txt"
  echo "Parsed latest version: $latest_version"
fi

if [[ -z "$current_build" || -z "$latest_version" ]]; then
  echo "Unable to determine current or latest version. Exiting (rc=42)." >&2
  exit 42
fi

# Compare versions
echo "Current version: $current_build_raw"
echo "Latest version:  $latest_txt"
if (( $(awk "BEGIN {print ($current_build > $latest_version)}") )); then
  echo "Nothing to do. Latest version less or equal to current. Exiting (rc=98)."
  exit 98
else
  echo "Upgrading. Latest version higher than current."
fi

# Split latest into semver components
IFS='.' read -r VERSION_MAJOR VERSION_MINOR VERSION_FIX <<< "$latest_txt"
echo $VERSION_MAJOR $VERSION_MINOR $VERSION_FIX

# OS / Arch selection (Unix path)
# PowerShell had separate Windows/Unix branches. Bash target = Unix/Linux.
THIS_OS="Unix"
THIS_ARCH="Linux-x86_64"
THIS_EXT="_INSTALL.BIN"
OUTPATH="/tmp/padev_current${THIS_EXT}"


echo "============================"
echo "============================"
echo "============================"

FIXPACK="$(pad3 "${VERSION_FIX}")"
FILE_TO_DOWNLOAD="PADEV.${VERSION_MAJOR}.0.${VERSION_MINOR}.${FIXPACK}_${THIS_ARCH}${THIS_EXT}"
URL="https://controlm-appdev.s3-us-west-2.amazonaws.com/release/v${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_FIX}/output/${THIS_OS}/${FILE_TO_DOWNLOAD}"

echo "Downloading from $URL"

curl -k -f -L -o "$OUTPATH" "$URL"
echo "Downloaded from $URL"

LD_LIBRARY_PATH=$oldldlib

chmod 755 "$OUTPATH"
echo "Starting installation of $OUTPATH"

OPTION=""
if [[ "$DEBUG" == "y" ]]; then
  OPTION="-v"
fi

# Run the installer silently (-s), optionally verbose (-v)
# Many Control-M installers accept '-s' for silent mode; adjust if needed for your package.
"$OUTPATH" -s $OPTION

echo "Completed installation of $OUTPATH"
