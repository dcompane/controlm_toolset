# controlm_toolset

## aapi_upgrade.ps1
  - Purpose: Downloads and installs the AAPI release identified in the parameters
  - Parameters: Version (default=9) Release (default=20) Fixpack (no default)
  - Use: ./aapi_upgrade.ps1 -fixpack 225
  
## sndSMSviaATT.sh
  - Purpose: as a control-M Shout, sends an SMS message via a REST request
  - Parameters: standard shout parameters $2 is used as message and contains the phone and text message separated by "=="
  - Use: as part of a Control-M shout to program

## SendAlarmToScript
  - Purpose: use Alarm to script configuration to send alerts to an ITSM system
  - Check the [README](sendAlarmToScript\README.md) file for the project
  - Use: as part of a Control-M shout to program

## Docker examples
  - Purpose: create docker image to show possibility of agent running in docker
  - build_docker_image.sh: Builds the docker image
  - conn2_docker_container.sh: allows for connecting to the container for verifications
  - remove_docker_container.sh: 
  - clean_docker_container.sh
  - run_docker_container.sh
  - image
    - dockerfile
    - decommission_controlm.sh
    - run_register_controlm.sh
### Helix Control-M
  - [Find the files here](docker\helix)

### Self-Hosted (a.k.a. On-Premise)
  - [Find the files here](docker\self-hosted)