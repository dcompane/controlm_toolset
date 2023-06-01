#########################################
# Evaluating make Python dict from CTM Alerts
#########################################
import re
def args2dict(tosplit, keys):
    def getkey(ls):
        for i in ls:
            if i is not None:
                return i.strip().rstrip(':')

    pattern = '|'.join(['(' + i + ')' for i in keys])
    lst = re.split(pattern, tosplit)

    lk = len(keys)
    elts = [((lst[i: i+lk]), lst[i+lk]) for i in range(1, len(lst), lk+1)]
    result = {getkey(i): j.strip() for i,j in elts}
    return result

#########################################
# Parsing arguments
#########################################
import argparse
def parsing_args():
    parser = argparse.ArgumentParser()
    #parser.add_argument('--action', '-a', dest='action', help='Type of action to perform',
    #                    choices=['list', 'fetch'])
    #parser.add_argument('--month', '-m', dest='month', help='Month of the report',
    #                    choices=['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
    #                             'October', 'November', 'December'])
    #parser.add_argument('-y', '--year', dest='year', action='store', help='Year of report in the format of YYYY')
    #parser.add_argument('-v', '--verbose', help='Running with debug messages', action='store_true')
    #parser.add_argument('alert', metavar='N', type=str, nargs='+', help='fromScript')
    #params = parser.parse_args()
    #return params

#########################################
# Initialize logging for debug purposes
#########################################
# General logging settings
# next line is in case urllib3 (used with url calls) issues retry or other warnings.
def init_dbg_log():
    import logging
    from logging import handlers
    from os import path, getcwd
    from sys import stdout
    logging.captureWarnings(True)

    # Define dbg_logger
    global dbg_logger
    dbg_logger = logging.getLogger('__SendTickets__', )
    # Logging format string
    # dbg_format_str = '[%(asctime)s] - %(levelname)s - [%(filename)s:%(lineno)s - %(funcName)s()] %(message)s'
    dbg_format_str = '[%(asctime)s] - %(levelname)s - %(message)s'
    dbg_format = logging.Formatter(dbg_format_str)
    # logging to file settings
    base_dir = getcwd() + path.sep
    dbg_filename = base_dir + 'autoalert.log'
    dbg_file = logging.handlers.RotatingFileHandler(filename=dbg_filename, mode='a', maxBytes=1000000, backupCount=10,
                                                    encoding=None, delay=False)
    # dbg_file.setLevel(logging.INFO)
    dbg_file.setFormatter(dbg_format)

    # Logging to console settings
    dbg_console = logging.StreamHandler(stdout)
    # Debug to console is always INFO
    dbg_console.setLevel(logging.INFO)
    dbg_console.setFormatter(dbg_format)

    # General logging settings
    # dbg_logger.setLevel(logging.DEBUG)
    dbg_logger.addHandler(dbg_file)
    dbg_logger.addHandler(dbg_console)

    # Heading of new logging session
    # Default logging level
    dbg_logger.setLevel(logging.INFO)
    dbg_logger.info('*' * 50)
    dbg_logger.info('*' * 50)
    dbg_logger.info('Startup Log setting established')
    
    return dbg_logger

#########################################
# Write DBG info on assigning variable
#########################################
def dbg_assign_var(to_assign, what_is_this,logger):
    if config['DEBUG'] :
        logger.debug (f'{what_is_this}: {to_assign}') 

    return to_assign


#########################################
# Helix Control-M and AAPI  functions
#########################################
# Connect to the (Helix) Control-M AAPI
from ctm_python_client.core.workflow import *
from ctm_python_client.core.comm import *
from ctm_python_client.core.monitoring import Monitor
from aapi import *
def ctmConnAAPI(host_name, token, logger):
    logger.debug('Connecting to AAPI')
    w = Workflow(Environment.create_saas(endpoint=f"https://{host_name}",api_key=token))
    monitor = Monitor(aapiclient=w.aapiclient)
    return monitor
    
#########################################
# Retrieve output
def ctmOutputFile(monitor, job_name, server, run_id, run_no, logger):
    logger.debug("Retrieving output using AAPI")
    # Adding header for output file
    job_output = \
        f"*" * 70 + '\n' + \
        f"" + '\n'+ \
        f"Job output for {job_name} OrderID: {run_id}:{run_no}" + '\n'+ \
        f"" + '\n'+ \
        f"*" * 70 + '\n'

    # Retrieve output from the (Helix) Control-M environment
    output = dbg_assign_var(monitor.get_output(f"{server}:{run_id}", 
            run_no=run_no), "Output of job", logger)

    # If there is no output, say it
    if output is None :
        job_output = (job_output + '\n' +  
                    f"*" * 70 + '\n' + 
                    "NO OUTPUT AVAILABLE FOR THIS JOB" + '\n' + 
                    f"*" * 70 )
    else:
        # Add retrieved output to header
        job_output = (job_output + '\n' +  output)

    return job_output

#########################################
# Retrieve log
def ctmlogFile(monitor, job_name, server, run_id, run_no, logger):
    logger.debug("Retrieving log using AAPI")
    # Adding header for log file
    job_log = \
        f"*" * 70 + '\n' + \
        f"Job log for {job_name} OrderID: {run_id}" + '\n'+ \
        f"LOG includes all executions to this point (runcount: {run_no}" + '\n'+ \
        f"*" * 70 + '\n'
    # Retrieve log from the (Helix) Control-M environment
    log = dbg_assign_var(monitor.get_log(f"{server}:{run_id}"), "Log of Job", dbg_logger)

    # If there is no output, say it
    if log is None :
        job_log = (job_log + '\n' +  
                    f"*" * 70 + '\n' + 
                    "NO LOG AVAILABLE FOR THIS JOB" + '\n' + 
                    "INVESTIGATE. THIS IS NOT NORMAL." + '\n' + 
                    f"*" * 70 )
    else:
        # Add retrieved output to header
        job_log = (job_log + '\n' +  log)

    return job_log

#########################################
# Write file to disk for attachment to case
import os
import tempfile
def writeFile4Attach(file_name, content, directory, logger):
        if not os.path.exists(directory):
             directory=tempfile.gettempdir()
        file_2write =directory+os.sep+file_name
        fh = open(file_2write,'w')
        try:
            # Print message before writing
            logger.debug(f'Writing data to file {file_2write}')
            # Write data to the temporary file
            fh.write(content)
            # Close the file after writing
            fh.close()
        finally:
            # Print a message after writing
            logger.debug(f"File {file_2write} written")


#########################################
# MAIN STARTS HERE
#########################################
assert __name__ != '__main__', 'Do not call me directly... This is existentially impossible!'