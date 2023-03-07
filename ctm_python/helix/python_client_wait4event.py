from pprint import pprint
from sys import exit

from ctm_python_client.core.workflow import Workflow, WorkflowDefaults
from ctm_python_client.core.comm import Environment
from aapi.job import JobCommand
from aapi.condition import ConditionIn, ConditionOutDelete, ConditionOutAdd
from aapi import WaitForEvents, DeleteEvents, AddEvents, Folder

environment = 'https://se-sanb0x-aapi.us1.controlm.com/automation-api'
api_key = 'UFJER0ZQOjcyOTg0ZWUxLTYzZWQtNDA0My1iNjhlLTk0YjFlZmUwNzEyZDplVjNKbzZXZmJyQTlmU250VmY1OUpodVhKMjVldHRBekZDTHFwdEljVmw0PQ=='

my_environment = Environment.create_saas(endpoint=environment, api_key=api_key)

workflow = Workflow(my_environment, 
    WorkflowDefaults(
        run_as='someuser',
        application='DCO',
        sub_application='DCO_AAPI_Events'     # defining someuser as the user to run the jobs by default
    )   # run_as is required
)

# Create job with basic data
myJob = JobCommand('MyFirstJob', command='echo "Hello world!"', host='myHost')

# Add job to workflow
workflow.add(myJob, inpath='DCO_MyFirstFolder')

# Get folder object
myFolder = workflow.get('DCO_MyFirstFolder')

# Add an event to wait for on the folder
if not myFolder.wait_for_events_list:
    myFolder.wait_for_events_list.append(WaitForEvents('events_to_wait', events=[]))
myFolder.wait_for_events_list[-1].events.append(ConditionIn(event="FldrWait4Me", date="NoDate"))

# Delete an event when the folder ends on the folder
if not myFolder.delete_events_list:
    myFolder.delete_events_list.append(DeleteEvents('events_to_delete', events=[]))
myFolder.delete_events_list[-1].events.append(ConditionOutDelete(event="FldrWait4Me", date="NoDate"))

# Add an event when the folder exits on the folder
if not myFolder.add_events_list:
    myFolder.add_events_list.append(AddEvents('events_to_add', events=[]))
myFolder.add_events_list[-1].events.append(ConditionOutAdd(event="FldrSomeIsWaiting", date="NoDate"))


## Now work on the jobs

# Add an event to wait for 
if not myJob.wait_for_events_list:
    myJob.wait_for_events_list.append(WaitForEvents('events_to_wait', events=[]))
myJob.wait_for_events_list[-1].events.append(ConditionIn(event="JobWait4Me", date="NoDate"))

# Delete an event when the job ends
if not myJob.delete_events_list:
    myJob.delete_events_list.append(DeleteEvents('events_to_delete', events=[]))
myJob.delete_events_list[-1].events.append(ConditionOutDelete(event="JobWait4Me", date="NoDate"))

# Add an event when the job exits
if not myJob.add_events_list:
    myJob.add_events_list.append(AddEvents('events_to_add', events=[]))
myJob.add_events_list[-1].events.append(ConditionOutAdd(event="JobSomeIsWaiting", date="NoDate"))

# Run the build process (syntax check)
build=workflow.build()

if build.is_ok():
    print('The workflow is valid!')
    # If build is ok, deploy the folder (write to (Helix) Control-M)
    deploy=workflow.deploy()
    if deploy.is_ok():
        print('The workflow was deployed to Control-M!')
        rc=0
    else:
        # This was not tested as could not simulate a fail deploy with a successful build.
        print('The workflow was NOT deployed to Control-M, but built ok! (Really strange!)')
        pprint(deploy.errors)
        rc=2
else:
    print('The workflow is NOT valid!')
    pprint(build.errors)
    rc = 1

# set a breakpoint here to preserve variables for inspection if debugging... :-)
pass

exit(rc)
