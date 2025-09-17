# Control-M SAP IBP plugin

See note on the integrations page related to the Output Rules.

## Changes on this version

| Date       | Who               | What                                                                                         |
| ---------- | ----------------- | -------------------------------------------------------------------------------------------- |
| 2022-01-19 | Daniel Companeetz | First release                                                                                |
| 2022-02-03 | Daniel Companeetz | First upload with this changelog. Multiple changes since first release.                      |
| 2022-02-08 | Daniel Companeetz | README.md: Fixed wget for download                                                           |
| 2022-03-08 | Daniel Companeetz | 1. Change handling of SAPIBP url to add numbers `<br>` 2. Added StartJob script to GitHub. |
| 2022-03-16 | Daniel Companeetz | Minor updates to README                                                                      |
| 2022-06-14 | Daniel Companeetz | Minor updates to README                                                                      |

## Contributions

| Date       | Who           | What                                             |
| ---------- | ------------- | ------------------------------------------------ |
| 2022-04-08 | Philippe Lago | Noted IBP url may contain numbers (e.g. sapibp1) |

## Who is using it

| Date       | Who                                                                                     | See comments on                                                                                |
| ---------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| 2022-06-10 | [Clint Adams (JR Simplot Company)](https://community.bmc.com/s/profile/0051400000Byd1HAAR) | [AppInt Hub post](https://community.bmc.com/s/news/aA33n000000TWHhCAO/sap-ibp-job-type-linuxbash) |

## Short description

Control-M Integration plugin for SAP IBP.

> * For the latest SAP IBP information, refer to SAP Notes:
>   * 2503171 - Usage of External Job Scheduling solutions with SAP Integrated Business Planning
>   * 2789802 - IBP - Common JOB issues when using external scheduler

## Download

* [Click this to download a zip of the PlugIn jobtype](resources/AI_SAPIBP.zip)Click download and unzip the archive. Then, import the file into the Application Integrator designer.
* [Click this for the uncompressed raw AI_SAPIBP.ctmai file](resources/AI_SAPIBP.ctmai)This will allow you to retrieve the raw ctmai file as described in the repository [Readme](https://github.com/controlm/integrations-plugins-community-solutions#saving-application-integrator-files-for-use).
* Or use the following command:

  ```bash
  wget -O AI_SAPIBP.ctmai https://github.com/controlm/integrations-plugins-community-solutions/raw/master/104-erp-integrations/sapibp/resources/AI_SAPIBP.ctmai
  ```

## Pre requisites

### Control-M

* Helix Control-M
* Helix Control-M Agent v9.0.20.180+ **only on Linux**.
* Application pack v9.0.20.180+

> NOTE: It is likely compatible with Control-M on-premise systems, but it has not yet been tested with it.

### SAP IBP

Uses the published [SAP IBP API](resources/ExternalJobScheduling_Official.pdf) (see SAP Note [2503171 - Usage of External Job Scheduling solutions with SAP Integrated Business Planning - SAP for Me](https://me.sap.com/notes/2503171))

## Features

* Authentication: Uses Basic Authentication
* Connection Profile:
  * Enter the host, port, Communication User and Password. The Password will be obscured.
    > The jobtype does not check for User locked. This may return rc=14 (Unknown return code)
    > Hostname should include the "-api" section. (See rc=10 below)
    >
* Job Fields
  * Can be specified with a choice of the Template Name or the Template Text. Most users know the Template Text, but the API requires the Template Name to start the job.
  * Allows to specify the Maximum Duration (timeout) expected on each job.If the jobs surpasses the Maximum Duration, you can select to attempt to kill the SAP IBP job, or let it continue.In either case, you should validate, per the SAP IBP API manual, that all components have completed.See OData Call to Cancel / Unschedule a Job on the [API documentation](resources/ExternalJobScheduling_Official.pdf)
  * Includes a configurable cycle time to avoid overloading the SAP IBP platform with excessive verification requests (default=60 seconds)
* Return Codes
  * rc=0: IBP Reported completion successfully. JobStatus="F".
  * rc=10: URL for SAP IBP is malformed. Likely cause it is missing the "-api".
  * rc=11: The Template Text or Name specified could not be found.
  * rc=12: The execution in SAP IBP still continues after Control-M job ended. Likely a timeout without a request for termination. JobStatus="R".
  * rc=13: The execution in SAP IBP terminated with JobStatus=A. The job was cancelled in SAP IBP, or a timeout with termination occurred. JobStatus="A".
  * rc=14: There was an unknown return code (JobStatus different from A, F, or R)
  * rc=15: The job was manually killed from Control-M. An attempt to terminate the SAP IBP job was automatically sent.
  * rc=24: An attempt to run on a **Windows agent** made the job fail.

## Test information

### Sample CCP provided

* [See Connection Profile](resources/AI_Jobs_and_CCP/AI_SAP_IBP_CP.json)

### Test Jobs provided

* [See Sample JSON Test Jobs](resources/AI_Jobs_and_CCP/AI_SAP_IBP_Test_Jobs.json)

## Overall flow for the plugin

[Download Flow PDF](images/AppInt_Flow.pdf)
![SAP IBP Plugin flow](images/AppInt_Flow.png)

## Scripts

The following scripts were used in the AI Steps.

> NOTE: The scripts do not have names in the AI. They were given names to be saved here.

* [CTM_AI_StartJob.sh](resources\AI_Scripts\CTM_AI_StartJob.sh): This is the Abort operation of the Verification Step
* [CTM_Kill_job.sh](resources/AI_Scripts/CTM_Kill_Job.sh): This is the Abort operation of the Verification Step
* [CTM_IBP_Terminate.sh](resources/AI_Scripts/CTM_IBP_Terminate.sh): This is the IBP termination if Max Duration (Timeout) was exceeded
* [CTM_AI_PostProc.sh](resources/AI_Scripts/CTM_Kill_Job.sh): This is the Post Processing script
