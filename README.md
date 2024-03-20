# controlm_toolset

## [aapi_upgrade.ps1](aapi_upgrade.ps1)

- Purpose: Downloads and installs the AAPI release identified in the parameters
- Parameters: Version (default=9) Release (default=20) Fixpack (no default)
- Use: ./aapi_upgrade.ps1 -fixpack 225
- NOTE: If you install Powershell on Linux (!!) it can also be used in that OS! (tested and works!)
  
## [sndSMSviaATT.sh](misc_tools\sndSMSviaATT.sh)

- Purpose: as a control-M Shout, sends an SMS message via a REST request
- Parameters: standard shout parameters $2 is used as message and contains the phone and text message separated by "=="
- Use: as part of a Control-M shout to program

## [eventViaNotifDest.bat](misc_tools\eventViaNotifDest.bat)

- Purpose: Allows to send an event via the ctm cli to some other system using the notification (shout) destinations mechanism
- Parameters: standard shout parameters %2 is used as message and, separated by spaces, contains.
  - event
  - Date
    - formatted as MMDD
    - STAT, or
    - ODAT
  - Log (if Y, will write log files with the following name)
    - logfile=%currdir%%currdate%_%currtime%_%event%.txt
- Use: as part of a Control-M shout to program

## [SendAlarmToScript](sendAlarmToScript)

- Purpose: use Alarm to script configuration to send alerts to an ITSM system
- Check the [README](sendAlarmToScript/README.md) file for the project
- Two versions very similar in design
   - [Bash](sendAlarmToScript/Bash)
   - [Python](sendAlarmToScript/Python)
       - See an integration for Remedy ITSM at https://github.com/controlm/automation-api-community-solutions/tree/master/helix-control-m/2-external-monitoring-tools-examples/alerts-to-helix-itsm

## Docker examples

Please let me know of improvements you think would be useful

- Check README [here](docker/README.md)

### For future

- test the STOPSIGNAL dockerfile command and use it in the run_register to test for non-usual stop signals.

### Information about Kubernetes

For the Kubernetes best practice information see [here](https://github.com/controlm/automation-api-quickstart/tree/master/control-m/301-statefulset-agent-to-run-k8s-jobs-using-ai-job)

## ctm_python_client examples

- Purpose: show some code samples to help developing python client code.
- Two folders:
  - helix
  - self-hosted
- aapi_*conn.py: contains the connection and authentication code.
  - class SaaSConnection(object): for Helix
  - class CtmConnection(object): for self-hosted
- where to find:
  - The repo: [https://github.com/controlm/ctm-python-client](https://github.com/controlm/ctm-python-client)
  - The doc: [https://controlm.github.io/ctm-python-client/index.html](https://controlm.github.io/ctm-python-client/index.html)
- how to install:
  - pip install ctm_python_client
