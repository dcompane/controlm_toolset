# Readme File  

The purpose of this work is to be able to create tickets on a Service Now instance

* If the ticket is for a job  
  * The ticket will contain log for all executions up until that in case of repeated runs  
  * The ticket will contain output for the current execution only  
  * The ticket will contain a link to open the job neighborhood in Control-M Self Service
* If the ticket is not for a job related alert
  * It will contain basic information

## Relevant files  

* crtsnowticket.sh  
  * file that processes the alert and sends the incident to Service Now
  * tktvars.json  
    * file that contains variables per environment (script will not be much faster if they were hardcoded)  
    * directory for log file specified must be in tktvars.json
  * installjq.sh  
    * script to be run as root to install jq (json query tool)  
  * installAAPI.sh
    * script to be run as root to install the AAPI if not available  
  * Folder_DCO_SNow.xml  
    * Set of Control-M jobs to manage the ticketing  
  * README.md  
    * This file  

## Requirements

* Control-M EM parameters
  * check [EM docs](http://documents.bmc.com/supportu/9.0.19/help/Main_help/en-US/index.htm#45710.htm)
  * Search in the page below for SendAlarmToScript
    * [EM Parms](http://documents.bmc.com/supportu/9.0.19/help/Main_help/en-US/index.htm#2283.htm)
  * Ticketing application  
    * Must have a valid API user with proper permissions.  
    * Consult your Documentationor ask your Support team for proper permissions.  
  * Control-M AAPI CLI  
    * Ensure the proper environment is created under the user that will connect to the EM.  
    * If the user needs to retrieve from the mainframe, ensure that the proper equivalences are set.  
    * The DS API ID is assigned to the IOA user on the PARM(EMUSREQ) (or similar)
  * jq  
    * jq must be installed to process json objects. (see installjq.sh)
  * Modify crtsnowticket.sh to ensure tktvars.json is in the right location  
    * By default, the script expects the var file in the same directory. Change if needed.
  * Modify tktvars.json  
    * The file may contain unencrypted credentials.

## Future work

* Convert credentials to secrets  
  * use ctm config secrets to store the passwords
* next future work  
  * next line

## Service Now developer instance

* Sign up for a developer instance at [ServiceNow](https://developer.servicenow.com)
* Once the instance is available, you will be provided with a URL
  * Enter the URL in the json file
  * You will be assigned an admin user password.
* ONLY for the developer instance
  * at the admin console use the action to delete all demo data
  * The activity takes about 30 minutes.
* Create a user. Note the username and password to enter in the json file.
* Assign the following roles
  * rest_api_explorer
  * web_service_admin
* If desired, marked the user as "Web service access only"
  * create another user for regular access if you prefer not to use the admin user.
* Create a user called ctmuser for interactive access
   *assign password ctmpass
  * assign admin role
* There will be some limitation to the file sizes and file extensions that can be overwritten. The script does not violate those limitation, but modifications may.
  * The Attachment API respects any system limitations on uploaded files, such as maximum file size and allowed attachment types.
  * You can control these settings using the properties com.glide.attachment.max_size, 1024MB by default, and glide.attachment.extensions.
