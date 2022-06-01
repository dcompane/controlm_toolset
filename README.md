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
- Files
  - build_docker_image.sh: Builds the docker image
  - check_docker_container.sh: uses docker inspect to get the return code and log of the container execution.
  - clean_docker_container.sh: Clean orphan images
  - conn2_docker_container.sh: allows for connecting to the container for verifications
  - remove_docker_container.sh: use docker stop to stop the container
    - Sends SIGTERM and SIGKILL after timeout. 
    - Timeout changed to 60 secs to allow for orderly termination.
  - run_docker_container.sh: runs the container
  - signal_docker_container.sh: sends a signal for the container to process
    - Sends SIGUSR1 by default. Other signals (SIGTERM, SIGHUP, SIGKILL) can also be sent. SIGTERM is trapped in addition to SIGUSR1, but no others. SIGKILL will terminate the container immediatly. Others may be ignored.
    - images/dockerfile
    - images/run_register_controlm.sh: is the CMD that is being executed for the container work.
    - images/deploy_test_jobs.json: test jobs. Not required, but will need to change the dockerfile and the run_register_controlm.sh
    - Other files as needed

### Helix Control-M

- [Find the files here](docker/helix)

### Self-Hosted (a.k.a. On-Premise)

- [Find the files here](docker/self-hosted)

### Information about Kubernetes
For the Kubernetes best practice information see [here](https://github.com/controlm/automation-api-quickstart/tree/master/control-m/301-statefulset-agent-to-run-k8s-jobs-using-ai-job)