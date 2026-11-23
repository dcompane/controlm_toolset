# Control-M Report Plugin

## Changes on this version

| When       | Version | What            |
| ---------- | ------- | --------------- |
| 2026-11-11 | v1      | Initial Release |
|            |         |                 |

## Contributions

| When       | Who               | What           |
| ---------- | ----------------- | -------------- |
| 2026-11-11 | Daniel Companeetz | nitial Release |
|            |                   |                |

## Prerequisites

* Control-M Version 9.22.000 (EM, Agent)
* SaaS or Self-Hosted
* Tested on Linux and Windows
* No languages dependencies (REST API for all AAPI calls and echo for OS commands)
  * May look funny in powershell! :-)

## Installation

1. Upload the attached file
2. Deploy the integration using Application Integrator or AAPI CLI

## Description

Run a job that creates a CTM report and downloads it to a file locally at the agent.

### Options:

* File can be named as the report, or custom name
* File can have the name appended with date/time
* Report can be csv (default), excel or pdf

### Limitations

NOTE: I suggest that you open or vote on existing ideas at the [Ideas Portal ](https://ideas.bmc.com)if you want to see this limitations resolved

* The download location is the agent (see note in the name field)
  * The download location can be changed by updating the EM parameter RF_SHARED_FILE_SYSTEM_BASE_PATH
    * See [Reporting documentation](https://documents.bmc.com/supportu/9.0.22/en-US/Documentation/Report_Management.htm#ConfiguringControlMReportsinaControlMEMDistributedEnvironment)
* The timestamp is a Application Integrator function and cannot be modified
  * The format is YYYYMMDD_HHMMSS (from memory...)

## Control-M

### Connection Profile

* Host: Enter the FQDN for the AAPI host name
  * Full host name without the https or the path
  * For example, in SaaS systems must include the "-aapi", but not "/automation-api"
* Port: listening port for the AAPI server
  * SaaS is 443, Self-Hosted is 8443 or similar
* AAPI token: token to execute the report
  * Report will follow the token permissions

### Define a job

Fields on the job are simple. Notes:

* Shared is required for reports not owned
  * They must be shared for ALL, since the token is not a user (but a role).

### Sample Reports

The following reports can be imported to the Reporting tool as samples

#### * History

* VAS-OH-Failure_Exception
* VAS-OH-RuntimeTrends

#### * SLA Management

* VAS-OH-SLA

#### * Definition

* VAS-OM-Cyclic
* VAS-Estate Visibility

#### * MFT

* DCO_VAS_MFT

### Sample Jobs

See the use of reference folders to schedule multiple different jobs across a single folder

* This reduces the need for maintaining multiple jobs that are re-used always in the same way.
* It does require some additional planning and thought (and testing) but there is a significant reduction in the jobs defined (not ordered!)
* Note some

Try it and let me know how it works!
