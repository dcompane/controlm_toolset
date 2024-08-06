from ctm_python_client.core.comm import *
from ctm_python_client.core.workflow import *

from aapi import *
import attrs

# The JobType is decorated with @attrs.define, but the decoration is not just vanity! Decorator is mandatory!

@attrs.define
class AIJobDCOIBMiSSH(AIJob):   # We derive from AIJob, the name of the class can be any valid python class name
    _type = AIJob.type_field('AI DCOIBMiSSH')   # The argument for the AIJob method "type_field" must have the same jobtype name you would see in 
                                                #    the web interface in the Planning section

    # the argument for the AIJob method 'field' needs to match the one in the Web interface

    # note the AIJob method 'field_optional' for fields that are not required and will take default values from the jobtype design
    #    The ones below are just for testing at this time.

    usesbmjob = AIJob.field('Use SBMJOB?')
    command = AIJob.field('IBMi Command')
    jobname = AIJob.field('JOB NAME')
    jobowner = AIJob.field('JOB OWNER')
    jobd = AIJob.field_optional('JOBD')
    jobq = AIJob.field_optional('JOBQ')
    curlib = AIJob.field_optional('CURLIB')
    outq = AIJob.field_optional('OUTQ')
    vercycle= AIJob.field_optional('Verification cycle time')
    log = AIJob.field_optional('LOG')
    inllibl = AIJob.field_optional('INLLIBL')
    logclpgm= AIJob.field_optional('LOGCLPGM')
    ifkill = AIJob.field_optional('If Kill is needed')
    killdelay = AIJob.field_optional('Kill Delay')
    addparms = AIJob.field_optional('Additional Parameters')

assert __name__ != "__main__", "Do not call me directly... This is existentially impossible!"
