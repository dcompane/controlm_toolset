# controlm_toolset

## [eventViaNotifDest.bat](misc_tools\NotificationDestinations\eventViaNotifDest.bat)

- Purpose: Allows to send an event via the ctm cli to some other system using the notification (shout) destinations mechanism
- Parameters: standard shout parameters %2 is used as message and, separated by spaces, contains.
  - event
  - Date
    - formatted as MMDD
    - STAT, or
    - ODAT
  - Log (if Y, will write log files with the following name)
    - logfile=%currdir%%currdate%_%currtime%_%event%.txt
- Use: as part of a Control-M shout to program
- Pre-requisites
  - The ctm cli must be configured to access by default the environment target.
  - If needed, a shout with the ctm env [saas::]add command may be needed to set the environment as required.

## [eventViaNotifDest.sh]([misc_tools\eventViaNotifDest.bat](eventViaNotifDest.sh))

- Purpose: Allows to send an event via the ctm cli to some other system using the notification (shout) destinations mechanism
- Parameters: standard shout parameters %2 is used as message and, separated by spaces, contains.
  - event
  - Date
    - formatted as MMDD
    - STAT, or
    - ODAT
  - Log (if Y, will write log files with the following name)
    - logfile=$currdir/$currdate-$currtime-$event.txt
- Use: as part of a Control-M shout to program
