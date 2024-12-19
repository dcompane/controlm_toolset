#---------------------------------------
# Control-M/Agent docker container
# Edited by 
#       Daniel Companeetz - BMC Software
#---------------------------------------

# (c) 2020 - 2024 Daniel Companeetz, BMC Software, Inc.
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

###Tested with the following OSes
FROM almalinux:latest

ARG AAPI_ENDPOINT
ARG AAPI_TOKEN
ARG AAPI_ENVIRONMENT="endpoint"
ENV aapi_env=$AAPI_ENVIRONMENT

### install basic packages
#RUN  dnf -y install drpm

RUN  dnf -y update
RUN  dnf -y install unzip \
        && dnf -y install sudo \
        && dnf -y install net-tools \
        && dnf -y install which \
        && dnf -y install wget \
        && dnf -y install psmisc

# ENABLE STRACE IF NEEDED FOR TROUBLESHOOTING SIGNALING
# connect to container and use strace -p 1 to see signals arriving to process
RUN  dnf -y install strace

# install nodejs
#RUN dnf -y install curl dnf-plugins-core \
RUN dnf -y install dnf-plugins-core

# install nodejs
RUN dnf -y module install nodejs:22 \
        && node -v \
        && npm -v

# Prep for new AAPI 9.22.0
RUN dnf -y install python pip git

# install Java
RUN dnf -y install java-21-openjdk-headless \
        && java --version \
        && alternatives --list

# Install additiona dependencies
#  Provides libcrypt.so.1
RUN sudo dnf -y install libxcrypt-compat
# Provides ps
RUN sudo dnf -y install procps-ng
# Provides libnsl.so 
RUN  dnf -y install libnsl

# add controlm user and root to sudoers list
RUN  useradd -d /home/controlm -p controlm -m controlm \
        && echo 'root ALL=(ALL) ALL' >> /etc/sudoers \
        && echo 'controlm ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

     
# install ctm-automation-api kit
WORKDIR /root
RUN mkdir /root/ctm-automation-api \
        && cd /root/ctm-automation-api \
        # next 2 lines specific for on-prem
        && export LD_LIBRARY_PATH=/usr/lib64 \
        # next line specific for on-prem
        && curl --silent -k -O "https://$AAPI_ENDPOINT:8443/automation-api/ctm-cli.tgz" \
        && npm install -g ctm-cli.tgz \
        && rm ctm-cli.tgz \
        && ctm -v


# add controlm endpoint
USER controlm
WORKDIR /home/controlm

# next line specific for on-prem
RUN ctm env add endpoint https://$AAPI_ENDPOINT:8443/automation-api $AAPI_TOKEN \
        && ctm env set endpoint \
        && export AAPI_TOKEN=""

# provision controlm agent image after validating the agent descriptor name.
#  Could have patches installes as below, but the steps lower are more "generic"
# cat Agent.Linux.json
#{
#    "OS": "Linux-x86_64",
#    "Installers":
#    [
#      "DRFZ4.9.0.21.300_Linux-x86_64.tar.Z",
#      "PAAIT.9.0.21.301_Linux-x86_64_INSTALL.BIN",
#      "PAAIT.9.0.21.302_Linux-x86_64_INSTALL.BIN"
#    ]
#}

RUN cd \
        && ctm provision image Agent.Linux \
        ; exit 0

# Uncomment the images for the plugins needed after validating the plugin descriptor names.
RUN set +x \
         && source /home/controlm/.bash_profile \
         && ctm provision image GCP_Composer_plugin.Linux
#         && ctm provision image Databases_plugin.Linux
#         && ctm provision image MFT_plugin.Linux

# Keep the following SAP lines together. Uncomment if needed.
#RUN set +x \
#         && source /home/controlm/.bash_profile \
#         && ctm provision image SAP_plugin.Linux \
#COPY ./sapjco3.jar /home/controlm/ctm/cm/SAP/exe/sapjco
#RUN sudo chown controlm:controlm /home/controlm/ctm/cm/SAP/exe/sapjco/sapjco3.jar \
#        && sudo chmod 775 /home/controlm/ctm/cm/SAP/exe/sapjco/sapjco3.jar

# enable controlm agent utilities
RUN echo "source /home/controlm/.bash_profile" >> /home/controlm/.bashrc 

################ Specific for on-prem patches
# Add patches as needed.
COPY PAAIT.9.0.21.301_Linux-x86_64_INSTALL.BIN  /tmp
RUN sudo chmod 755 /tmp/PAAIT.9.0.21.301_Linux-x86_64_INSTALL.BIN 
COPY PAAIT.9.0.21.302_Linux-x86_64_INSTALL.BIN  /tmp
RUN sudo chmod 755 /tmp/PAAIT.9.0.21.302_Linux-x86_64_INSTALL.BIN 

RUN set +x \
         && source /home/controlm/.bash_profile \
         && /tmp/PAAIT.9.0.21.301_Linux-x86_64_INSTALL.BIN -s

RUN set +x \
         && source /home/controlm/.bash_profile \
         && /tmp/PAAIT.9.0.21.302_Linux-x86_64_INSTALL.BIN -s

RUN sudo rm -f /tmp/PAAIT* 

# Adding some Python packages to the local agent repository
#  This may need to be revised when v22 AAPI is released.
RUN pip install ctm-python-client confluent-kafka \
        && pip install git+https://github.com/dcompane/controlm_py,git

# Clean dnf cache to reduce image size
RUN sudo dnf clean all \
         && sudo rm -rf /var/cache/dnf

# Exposing Agent ports. Use range as not sure what will be used.
#    See run_register_controlm.sh to determine how that works
EXPOSE 7000-8000

# Use next line to force a re-copy of the scripts or parameter files
RUN echo Build almost done

### Keep these lines just before the end in case changes to the 
###    run and decomm scripts are needed, to avoid re-build.
# copy run and register controlm agent script to container
COPY ./run_register_controlm.sh /home/controlm
COPY ./agent-parameters.json /home/controlm
COPY ./deploy_test_jobs.json /home/controlm
# give execute permissions to start/shut scripts
RUN  sudo chown controlm:controlm /home/controlm/*controlm.sh \
        && sudo chmod 775 /home/controlm/*controlm.sh

# CMD in exec mode (using []) is needed for signaling to work
# Signaling will ensure stopping the container deregister the agent
# use 
#  docker kill -s {SIGUSR1|SIGTERM} $container_id 
#      NOTE: SIGKILL (untrappable) will terminate the agent and does not remove it from Control-M
#      docker stop generates SIGTERM before timeout (see below)
#  docker stop $container_id -t 60
#      timeout is needed to ensure AAPI has time to process HG and agent removal
#      docker stop default timeout is 10 sec and then a SIGKILL is sent.
CMD ["/home/controlm/run_register_controlm.sh", "endpoint"]
