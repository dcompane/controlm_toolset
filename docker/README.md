# controlm_toolset

## Docker examples

Please let me know of improvements you think would be useful

### For future

- test the STOPSIGNAL dockerfile command and use it in the run_register to test for non-usual stop signals.

### Comments

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
    - Ensure you change the endpoint and token for the build process.
    - Check the variables to install plugins as required
    - Exit codes
      - 0 = exited normally. Agent deleted successfully
      - 13 = deletion of agent from hostgroup failed. Agent may still be registered and member of the hostgroup.
      - 14 = deletion of agent failed. Agent may still be registered.
  - signal_docker_container.sh: sends a signal for the container to process
    - Sends SIGUSR1 by default. Other signals (SIGTERM, SIGHUP, SIGKILL) can also be sent. SIGTERM is trapped in addition to SIGUSR1, but no others. SIGKILL will terminate the container immediatly. Others may be ignored.
    - images/dockerfile
    - images/run_register_controlm.sh: is the CMD that is being executed for the container work.
    - images/deploy_test_jobs.json: test jobs. Not required, but will need to change the dockerfile and the run_register_controlm.sh
    - Other files as needed

### Helix Control-M

- [Find the files here](docker/helix)
- There are two dockerfiles in the images directory
- Copy the dockerfile you need to "dockerfile" and run the build.

### Self-Hosted (a.k.a. On-Premise)

- [Find the files here](docker/self-hosted)
- There are two dockerfiles in the images directory
- Copy the dockerfile you need to "dockerfile" and run the build.

### Information about Kubernetes

For the Kubernetes best practice information see [here](https://github.com/controlm/automation-api-quickstart/tree/master/control-m/301-statefulset-agent-to-run-k8s-jobs-using-ai-job)
