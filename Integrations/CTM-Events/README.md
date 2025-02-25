# Control-M (and SaaS) Add/Delete Events

## Changes on this version

| Date       | Who               | What            |
| ---------- | ----------------- | --------------- |
| 2025-02-13 | Daniel Companeetz | Initial release |
|            |                   |                 |

## Contributions

| Date       | Who             | What                                        |
| ---------- | --------------- | ------------------------------------------- |
| 2025-02-13 | Wendel Bordelon | Provided the base development of the plugin |
|            |                 |                                             |

## Short description

This integration allows to add and delete events from a Control-M (and SaaS) server

Download

* [Click this to download a zip of the PlugIn jobtype](Resources/DCO_CTMCOND.zip)

  * Click download and unzip the archive.
  * Then, import the file into the Application Integrator designer or use the AAPI (ctm deploy jobtype).
  * Last, publish to the agent (ctm deploy AI:jobtype)

## Pre requisites

### Control-M

* This plugin was **NOT** tested with
  * Helix Control-M, but should work
  * Windows but should work

## Features

- The plugin adds or delete events. The date is configurable as per the events syntax (STAT, ODAT, MMDD).
- If the event to add exists, or to delete does not, the resulting errors will be ignored.
  - NOTE: There is a message that indicates that the step will be ignore. then, ignore the message
    - see [this](Resources/DCO_CTMCOND.ignore.message.png)

### Authentication

Only allows for API Token authentication

1. Connection Profile:

* * Enter the host, port, and Token (will be obscured)

## Test information

### Sample CCP provided

* See zip file

### Test Jobs provided

* See zip file

## When to use it

* If you need to send events between Enterprise Managers (Prod to QA, for example)
* If you are performing a migration rom On-Premise to SaaS, and some applications' jobs will be on either side, but need to maintain their dependences.
* This is NOT a replacement for the intra-EM Global Conditions.
