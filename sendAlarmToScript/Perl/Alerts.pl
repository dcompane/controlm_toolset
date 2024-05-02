#!/usr/bin/perl
#----------------------------------------------
# File: /opt/BMC/emuser/Alerts/Alert.pl
# Date: 20050419
# Auth: Daniel Companeetz
# Desc: Receives an alert from BMC's Control-M and
#       sends a corresponding event to HP OVSD
#       using opcmsg.
#
# Gratitude: This program was developed with help from
#               Mike Rayburn, from Infospectrum
#
# Created for Control-M v6.2, Tivoli console 4 and Oracle 9
#----------------------------------------------
# C H A N G E   L O G
# 19 Apr 2005   Daniel Companeetz       Created
# 
#----------------------------------------------


########################################
# Oracle connection strings
# Implemented originally as a resource file (using "require <filename>")

$CM_USER = "controlm";
$CM_PASS = "XXX";
$CM_SID = "CTRLM";
$CTM_HOME = "/home/BMC/controlm";
$EM_HOME = "/home/BMC/emuser";
$CM_CONN = "$CM_USER/$CM_PASS\@$CM_SID";
$EM_USER = "emuser";
$EM_PASS = "xxx";
$EM_SID = "CTRLM";
$EM_CONN = "$EM_USER/$EM_PASS\@$EM_SID";


########################################
# Define Environmental variables needed for SQL

$ENV{"CONTROLM"} = "/home/BMC/controlm/ctm";
$ENV{"LD_LIBRARY_PATH"} = "/home/BMC/oracle/product/9.2.0.1/lib32:/home/BMC/controlm/ctm/exe_Solaris";

########################################
# Load variables with arguments passed.

$call_type      = spaces(@ARGV[1]);
$alert_id       = spaces(@ARGV[3]);
$data_center    = spaces(@ARGV[5]);
$memname        = spaces(@ARGV[7]);
$order_id       = spaces(@ARGV[9]);
$severity       = spaces(@ARGV[11]);
$status         = spaces(@ARGV[13]);
$last_user      = spaces(@ARGV[17]);
$message        = spaces(@ARGV[21]);
$owner          = spaces(@ARGV[23]);
$group          = spaces(@ARGV[25]);
$application    = spaces(@ARGV[27]);
$job_name       = spaces(@ARGV[29]);
$node_id        = spaces(@ARGV[31]);

# This are date time arguments.
$send_time      = datetime(@ARGV[15]);
$last_time      = datetime(@ARGV [19]);

$team="";
$msg_text="";
$msg_severity="";


########################################
# Default event Severity

$evt_severity = "normal";

# if the datacenters are production
if ($data_center =~ /proddist|prodMF/) {
        $evt_severity = "critical";
}

$class = "Submit";

########################################
# Default values for logging


$logfile = "$EM_HOME/log/Alerts.log";


# known bug: does not switch if no alerts on first day of month
# Switch on 1st day of month
$logswday = 1;
# Switch after NEWDAY at 6am
$logswtime = 6;

########################################
# Reassign some variables to define default values


$evt_msg = $message;
$dummy   = "";

########################################
# Check for date and rename log
# known bug: does not switch if no alerts on first day of month

($sec, $min, $hr, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ();


if (($mday == $logswday) && ($hr >= $logswtime)) {

        $mon = $mon - 1;
        #if Month is -1, use last year's
        if ($mon == -1) {
                $mon = 11;
                $year = $year - 1;
        }

        #Year is number of year since 1900
        $x = $year+1900;
        #month starts with 0. substr to format with 2 digits.
        $filedate = $x.substr($mon+101,1,2);

        $oldfile = "$logfile.$filedate";
        rename $logfile, $oldfile if not -e $oldfile ;
}

########################################
#Open Log File
open(FILE1, ">>$logfile");

########################################
# Get the orderno and get the oscompstat from the db

#Convert the order_id to regular number
open(GETORD, "$CTM_HOME/ctm/exe_Solaris/p_36 $order_id|");
while($ordline = <GETORD>) {
        if($ordline =~ /result/) {
                $ORDNO = (split /=/,$ordline)[1];
                $ORDNO =~ s/^\s+//;
                $ORDNO =~ s/\s+$//;
                }
        }

close(GETORD);

# Read data from the database
$search = qx { sqlplus -s $CM_CONN <<EOF
                set heading off
                set wrap off
                set feedback off
                set linesize 500
                select oscompstat, ':::', descript, ':::', cmdline from CMR_AJF where ORDERNO = \'${ORDNO}\';
                exit
                EOF };

@LINE1 = split(/\n/,$search);

foreach $line (@LINE1) {
        $line =~ s/\s+//;
        $line =~ s/\s//;
        if($line =~ /:::/) {
                ($oscomp, $descript, $cmdline) = split /:::/, $line;
                $oscomp = spaces($oscomp);
                $descript = spaces ($descript);
                $cmdline = spaces ($cmdline);
                last;
        }
}

########################################
# Manage exceptions

#####
# If oscompstat is empty set default value=99
if (! $oscomp ) {
        $oscomp=99;
}


#####
# If nodeid is empty and job name starts with UG ignore alert
if ($node_id eq "" and substr($job_name,0,2) =~ "UG") {
        $class = "Ignore";
        $reason = " The alert refers to a Group, rather than to a Job";
}

#####
# If nodeid is empty and datacenter is prodMF change node_id
if ($node_id eq "" and $data_center =~ "prodMF") {
        $node_id = $data_center;
}


########################################
#Put the conditionals that will match the errors to the classes below this
#line.
#Class is class of event to be raised

# Alert shoud not be ignored unless...
if ( $class  !~ /Ignore/) {

        #Define attributes depending on messages
        if ($message =~ /Ended not OK/) {
                $class = "CTM_JobNOTOK";
                $evt_msg = "Job $job_name $message";
                $team = "Batch";

        } elsif ($message =~ (/AGENT PLATFORM \w+ CHANGED TO UNAVAILABLE/)) {
                $class = "CTM_AgentUnavailable";
                $node_id = $message;
                $team = "Batch";
                ($dummy,$dummy,$dummy,$dummy,$node_id) = split(" ",$node_id);

        } elsif ($message =~ (/AGENT PLATFORM \w+ CHANGED TO DISABLED/)) {
                $class = "CTM_AgentUnavailable";
                $node_id = $message;
                $team = "Batch";
                ($dummy,$dummy,$dummy,$dummy,$node_id) = split(" ",$node_id);

        } elsif ($message =~ (/ONE OR MORE JOBS IN DAILY \w+ WERE NOT ORDERED/)) {
                $class = "CTM_JobsNotOrdered";
                $node_id = $data_center;
                $team = "Scheduling";

        } elsif ($message =~ /DAILY \w+ FAILED TO ORDER JOBNAME/) {
                $class = "CTM_JobsNotOrdered";
                $node_id = $data_center;
                $team = "Scheduling";

        } elsif ($message =~ /Failed to order Job/) {
                $class = "CTM_JobsNotOrdered";
                $node_id = $data_center;
                $team = "Scheduling";

        } elsif ($message =~ /(Warning: DB tablespace is more than)|(Low on database space)/) {
                $class = "CTM_DBSpaceLow";
                $node_id = $data_center;
                $team = "Scheduling";

        } elsif ($message =~ (/DATA CENTER \w+ WAS DISCONNECTED/)) {
                $class = "CTM_ComponentDown";
                $node_id = $data_center;
                $team = "Batch";

        } elsif ($message =~ (/Job \w+ running/)) {
                $class = "CTM_JobTimeout";
                $node_id = $data_center;
                $team = "Batch";

	} elsif ($message =~ (/Job \w+ is late./)) {
                $class = "CTM_JobTimeout";
                $node_id = $data_center;
                $team = "Batch";

        } else {
                #Default Class
                $class = "CTM_Unknown";
                $evt_msg = "Unknown Alert received from Scheduler with msg=$message";
                $node_id = $data_center;
                $team = "Batch";
        }


        #If the Alert is Noticed or Handled
        if ($status !~ /Not_Noticed/) {

                $evt_severity = "warning";

                # Classes of events
                if ($status =~ /Handled/) {
                        $class = "CTM_AlertHandled";

                } elsif ($status =~ /Noticed/) {
                        $class = "CTM_AlertNoticed";
                }
        }
}

########################################
# Always log the data received

$logdate = logdates ();

print FILE1 "$logdate :: L1 :: $call_type :: $alert_id :: $data_center :: $memname :: $order_id :: $ORDNO :: $severity :: $status :: $send_time :: $last_user :: $last_time :: $message :: $owner :: $group :: $application :: $job_name :: $descript :: $cmdline :: $node_id :: $oscomp :: $class :: $evt_severity :: $evt_msg\n";


########################################
# Send the event and log result if must not be ignored


if ($class =~ /Ignore/) {

        $sendevtl= "This Alert will be ignored. Reason: $reason";
        print FILE1 "$logdate :: L2 :: $sendevtl \n";
        print FILE1 "$logdate :: L3 :: Event not sent\n";

} else {
        $evtsource = `uname -n`;
        chomp($evtsource);

    if ($call_type eq "I") {

        if ($severity eq "R") {
            $msg_severity="normal";
        } elsif ($severity eq "S") {
            $msg_severity="critical";
        } elsif ($severity eq "U") {
            $msg_severity="major";
        } else {
            $msg_severity="minor";
        }


        $msg_text="\"$evt_msg\" datacenter=$data_center send_time=\"$send_time\" orderid=$order_id ctm_severity=$severity jobname=$job_name memname=$memname  descrip=\"$descript\" cmdline=\"$cmdline\" application=$application group=$group hostname=$node_id nodeid=$node_id owner=$owner retcode=$oscomp alert_id=$alert_id ctm_status=$status lastuser=\"$last_user\" lasttime=\"$last_time\" $class $evtsource";

        $sendevtl= "/opt/OV/bin/opcmsg  msg_grp=Application application=ControlM object=$team severity=$msg_severity msg_text=\'\"$msg_text\"\' 2>&1";


        @sendevtr= qx/$sendevtl/;
        print FILE1 "$logdate :: L2 :: $sendevtl \n";
        print FILE1 "$logdate :: L3 :: Event sent with error code --> @sendevtr <-- (blank is success)\n";
    }
}
print FILE1 "$logdate :: L4 ::--------------------------------------------------------------------------------------\n";


close(FILE1);


#################################################################################################



########################################
# Eliminate leading and trailing spaces
# Eliminate quotes, ticks and backticks
# If date field is empty, but has // clears the field

sub spaces {

        # Return variable
         $x = $_[0];

        # Bye spaces
         $x =~ s/^\s+//;
         $x =~ s/\s+$//;

        # Bye quotes and such
         $x =~ s/\"//g;
         $x =~ s/\'//g;
         $x =~ s/\`//g;


        # Bye slash on empty dates
         if ($_[0] =~ /\/\//) {
                $x = "";
         }


        # And if it is still NULL, initialize
         if ( ! $_[0] ) {
                $x = "";
         }


        # I am so tired. End and return value
         return $x;
}

########################################
# Reformats date from Control-M format to human readable.

sub datetime {
# Received 20050120075858

     $y1 = substr($_[0],0,4);
     $m1 = substr($_[0],4,2);
     $d1 = substr($_[0],6,2);

     $t1 = substr($_[0],8,2);
     $t2 = substr($_[0],10,2);
     $t3 = substr($_[0],12,2);

     $x = spaces("${m1}/${d1}/${y1} ${t1}:${t2}:${t3}");

     return $x;

}


########################################
# Reverse sorting by the last 2 digits of the filename

sub sortlog {
        substr ($b,17,2) <=> substr ($a,17,2);
}


########################################
# Format log dates

sub logdates {

($sec, $min, $hr, $mday, $mon, $year, $wday, $yday, $isdst) = localtime ();

#Year is number of year since 1900
$x = $year+1900;

#month starts with 0. substr to format with 2 digits.
$x = $x.substr($mon+101,1,2).substr($mday+100,1,2).substr($hr+100,1,2).substr($min+100,1,2).substr($sec+100,1,2);

return $x;

}