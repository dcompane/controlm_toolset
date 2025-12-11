#!/bin/perl
#use strict;

# BSD 3-Clause License

# Copyright (c) 2021, 2025, BMC Software, Inc.; Daniel Companeetz
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# SPDX-License-Identifier: BSD-3-Clause
# For information on SDPX, https://spdx.org/licenses/BSD-3-Clause.html


$emminer_version="2.14";                # used in verifying current version and in displays
$emminer_version_date="11 Dec 2025";
$emailcontact="nonegiven";  # email address for emminer.pl routine comments/issues
$thispgm="EMminer";                     # variable holds the name of this routine


print "\n\n";                                                   # when routine starts, just skip a couple of lines for readability
print "-----------------------------------------------------\n";
print "Routine: EMminer\n";
print "Author: Terry Cannon\n";
print "Current maintainer: Daniel Companeetz\n";
print "\n";
print "Version: $emminer_version\n";
print "Revision date: $emminer_version_date\n";
print "-----------------------------------------------------\n";
print "\n";

#===============================================================================
# program emminer.pl
#
# Author: Terry Cannon
#
# Purpose: Mine various available data from the Control-M EM DB and create an Excel Spreadsheet
#
# Tested on EM series 6**, 7**, 8**, 9**, and beyond Control-M Enterprise Manager
##
# Syntax:   emminer.pl          {invokes as interactive)
#           emminer.pl -d       (turns on debugging)
#           emminer.pl -silent  (uses previous input values and runs with no prompts)
#           emminer.pl -y 2010  ( uses 2010 as the year for checking for duplicate calendars instead of gettime() $year)
#           emminer.pl -ip      (turns off IP address lookup)
#                       emminer.pl -license (selects that only the license related measurements to be reported)
#
#           or with a fully qualified path to where perl is installed with Control-M, e.g.:
#       Win:
#           C:\Program Files\BMC Software\Control-M EM 7.0.00\Default\bmcperl\perl emminer.pl
#           C:\Program Files\BMC Software\Control-M EM 7.0.00\Default\bmcperl\perl emminer.pl -silent
#       Unix:
#           ~<control-m_user>/bmcperl/perl emminer.pl
#           ~<control-m_user>/bmcperl/perl emminer.pl -silent
#

# updates
# Dec 2025 v2.14
#           -   (dc) Added CCP tab
# Oct 2025 v2.13
#           -   (dc) Fix test for $temp directory existence (prior code tested for file existence (-e) rather than directory existence (-d))
# Oct 2025 v2.12
#           -   (dc) OSQL is deprecated in newer MS-SQLL after 2005. Replaced with SQLCMD and adapted labels
#           -   (dc) Agents tab would see failures on MS-SQL. Fixed.
# Sept 2025 v2.11
#           -   (dc) Moved Components tab after Datacenters
#           -   (dc) Moving temp files to the EM temp directory
#           -   (dc) Cleanup remaining temp files
#           -   (dc) Updated License to BSD-3-Clause (https://spdx.org/licenses/BSD-3-Clause.html)
# Aug 2025 v2.10
#           -   (dc) Adding Agent-App tab
#           -   (dc) Adding App-SubApp tab
#           -   (dc) removed the serialization of the password to the config file.
# Jun 2024 v2.09
#           -   (dc) Fixing an issue with Pauser(3355)
# Feb 2024 v2.08
#           -   (dc) added some additional character replacements (search for "# Character replacements") and generic line to remove any non-printable chars (ascii over 127) after the initial replacements
#                       -       (dc) added $nolock to reports query for standardization (although not really needed)
# Jan 2024 v2.07
#                       -(jc) Added Reports tab to the workbook which returns Report Name, Description, Last Used Time, Last Update Time and User who created the report.
# Jan 2024       v2.06
#                       -(jc) Change MSSQL string from "2005 or 2008" to "2005 or greater" (search for "2005 or" to see the line changes)
#           -(dc) Fixed issue with MSSQL non standard port request syntax (-S $server:$port to -S "$server,$port")
#
# Nov 2023       v2.05
#                       -(dc) changed password acceptance behavior to resolve double enter bug
#
# Feb 2023       v2.04
#                       -(jc) changed CAL by DC sheet to reflect CalType instead of Periodic
#                       - (jc) added comment to CalType in CAL by DC sheet to note that 0=Regular, 1=Periodic, 2=Rule Based Calendar
#
# aug 2020 v2.03
#
# apr 2020  v2.01
#               -       (tc) added feature that the DBO password doesn't display when being typed
# aug 2019      v2.0
#               -       (tc) general review of code.  Will comment major changes here.
#               -       (tc) will leave all previous "update" comments in this section.  If I remove a part of the actual code, I will
#                                not come back to the updates section to see if a previous change was made to that section which has now been removed
#               -       (tc) turned off (commented out) the call to ping each agents 1 time.  Simply takes to long for large sites
#                            if needed, it could be turned back on by uncommenting that line.
# sept    2018  1b.19
#               -       (phil)  Various changes supplied directly by PS
#               -                       Added report of # of work spaces (in misc tab)
#               -       (tc) changed default to be no IP ping to each agent.  sites with many agents saw long time as each was "pinged".
#               -   (tc) removed sheet that parced cmdline for strings
#               -       (tc) some general tidying up of comments and pruning of old code no longer used
#               -       (tc) turn back on and adjusted the testdb section of code.  may still need improvement as this was leading cause of phone calls
#               -       (tc) added prompt for v9.19 db name of emdb\n
#               -       (tc) additional reports of non-english characters causing the spreadsheet not to open
#               -                replaced   Á --> A
#                                                       É --> E
#                                                       Í --> I
#                                                       Ç --> C
#                                                       Ã --> A
#                                                       Õ --> O
#               -       (tc) Added list of all Add_on's and their status on the Misc tab
# jun 14, 2016  1a.30
#               - (ps) Updated approach to setting emdir (esp. if Full or Trial Install) and psql client search
#               - (ps) Hide password more consistently
#               - (ps) more consistent Unix support e.g. stderr & stdout redirection to a single file
# apr 28, 2016  1a.30
#               - (tc) adjusted to accept v9 as input
# dec 16, 2013 (1a.29)
#               - (tc) adjust for more debug on psql search
# Jan 3, 2013 (1a.28)
#               - (ps)  corrected safeday code if emminer is run on feb 29
# Jan 2, 2013 (1a.27)
#               - (tc)  Added to the Tbls per DC tab summary information at the bottom for how many total tables, how many smart tables, and percentage
#               - (tc)  Added a new tab with information about the Data Centers (tab name is Data Center)
#               - (tc)  Added advisory notes for # of version of job definitions to keep and # of old networks to keep
# dec 17, 2012 (1a.27)
#               - (ps)  Added to Misc and new 'SYM' worksheet - LIBMEMSYM/LIBSYM/MEMSYM usage
#               - (ps)  Added to Misc - # tables by workspace worksheet if >= v8
#               - (ps)  Added -old command line option to override new v8 terminology
#               - (ps)  Fixed Oracle date error - used to_date()
#               - (ps)  Fixed -y command line option was ignored
#               - (ps)  minor bug fixing. E.g. EMPARMS erroneous diff from defaults file
#               - (ps)  postgreSQL mynontupes should be 3 - corrects 'number of agents' count etc.
#               - (ps)  postgreSQL not postgress etc. corrected typos
#               - (ps)  probable fix for agent ping
#               - (ps)  initial version 8 support
#               - (ps)  Cal by DC fix on MSSQL - query failed
# aug 16, 2012 (1a.26)
#               - (tc)  when using the "- silent" option, there was an unneeded pause (hit enter to continue) at the end of the routine.  Now corrected.
# july 17, 2012 (1a.25)
#               - (tc)  corrected an "if $debub" that should have been "if $debug"
# jun 19, 2012  (1a.24)
#               - (tc)  took green fill out for count of highest days, style error
# may 30, 2012  (1a.23)
#               - (tc)  added green fill for the count of highest days job cell
# Feb 15, 2012  (1a.21)
#               - (tc)  turned Perlcritic loose on the code and made some adjustments per it's suggestions
# Feb 14, 2012  (1a.20)
#               - (tc)  adjusted to replace characters ï and ô
# Feb 3, 2012   (1a.19)
#               - (tc)  adjusted to replace spanish characters è, î, ï
# Dec 1, 2011   (1a.18)
#               - (tc)  removed (commented out) the individual calendar sheets since they are now all in a single sheet
#
# oct 4, 2011   (1a.17)
#               - (tc)  adjusted the text for mssql 2005 or 2008
#               -
# sept 27, 2011 (1a.16)
#               - (tc)  corrected a line (prompt for the password) which was commented out in error.
# aug 31, 2011 (1a.15)
#               - (tc)  added new item to show jobs that had not been run (no stats record) within some date in the past
# aug 29, 2011 (1a.14)
#               - (tc)  removed readkey usage.  had been inserted for input of invisible password but only works in windows.
# jun 9, 2011  (1a.13)
#               - (tc)  added spanish character replacement to all lines in the spreadsheet
# jun 8, 2011
#               - (tc)  added support for the ó character (changed to an o)
# mar 31, 2011
#               - (tc)   general cleanup.  update to some comments.  cleanup of some user on screen text
#                                added non-port user designation
#                                corrected ip ping bug
#                                ... misc ...
# mar 11, 2011
#               - (tc)   added self check for newer version
#
# mar 8, 2011
#               - (tc)   adding a new section to this routine so that the user can specify to produce the traditional spreadsheet which
#                                gives a summary look at usage of control-m, or a newer licensing version that focuses on job count information.
# feb, 2011 updates
#               - (tc)   considering adding an analysis of audited operations
#                select count(*), username, operation, timestamp from audit_activities group by username,operation,timestamp ORDER BY username, operation;
#               - (tc)   added an additional separation list of top 10 to the jobs hist by day so that it list across enterprise, only for zos, then only for dist
# oct, 2010 updates
#           - (tc)   When trying to detect the executable "psql.exe" to use for PostgreSQL installs, if it isn't found in the
#                                current path variable, look in <EM_HOME>\psgl\bin  directory for it.
#                                I realize that is could be that the Postgres DB exist beneath the Control-M Server directory or even some
#                            unrelated directory, but this seemed a logical first effort to improve locating it when not in the path.
#               - (tc)   Added a new spreadsheet tab if the EM version being used is 6.3 or above for the daily job info
# Sept, 2010 updates
#               -  (tc) Added the "Spinit" subroutine to give constant visual that the routine is working
#               -  (tc) Added parm for tempdir if the user wants to specify where the report is saved
#               -  (tc) Added some additional Alert analysis
#               -  (tc) Rearranged the order of some of the sheets so more interesting ones come first
#       -  (tc) corrected a totalling bug in the ajf sheet
# Jun, 2010 updates
#        - (TC) Rather than use the default sort order for several worksheets, added sorting to the spreadsheet
#        - (TC) Renamed the "SNMP" tab to be "EMPARMS".  Now show all parms, indicates default, indicates site changes, sort by changed parms
#        - (TC) At the suggestion of several clients, in addition to reporting analysis, this routine is now
#               beginning to incorporate comments relative to suggestions (i.e. don't overuse the max wait 99
#               without a complete understanding that you need to manually remove these jobs from the AJF when
#               they are no longer needed).
#               Will start with a few simple "best practices" or "guiding advice" comments and color the item
#               RED and BOLD to draw the users attention to the comment.  Will expand this advice to other fields later.
#               By default the cell comments are turned on as show always.
#        - (TC) Several clients from South America had spreadsheets that would not open because of special characters.
#               These are now replaced in the text as:
#                   ‡  --> null
#                   Æ  --> null
#                   “  --> null
#                   é  --> e
#                   á  --> a
#                   '  --> blank
#                   ç  --> c
#                   ã  --> a
#                   º  --> blank
#                   ú  --> u
#                   ê  --> e
#                   Ê  --> E
#                   ª  --> blank
#                   à  --> a
#                   õ  --> o
#                   Ç  --> C
#
#
#        - (TC) Also noted were failure to open spreadsheets with & in the calendar name if Oracle was the DB.  Adjusted SQL to allow for this
#        - (TC) Periodic Calendar with significant number of days marked using numeric values.
#               On certain periodic calendars which had only numbers for the values, this switched to the "Number" type format
#               for the generated xls file.
#               The files generated with that were failing to open.  Now all calendar values using String format.
# Jul, 2009 updates
#        - (TC) initialized value of $dosql_count to zero
#        - (TC) in subroutine "cleanup" added a test prior to eraseing a temp file
#        - (TC) added a couple more debug lines to identify a potential issue for RP
# Jun, 2009 updates
#        - (TC) added line $exceededtaskmsg="";  as an initial value (was generating a message related to uninitialized value in concatenation)
#        - (TC) added subroutine Pauser.  Usage during testing is that you call the subroutine like &Pauser(193); which causes the routine
#               to pause with a hit enter to continue msg.  If you also want to see what line number the pause was from use the syntax &Pauser(194);  for line number 1500.
#               once paused, you can also choose to quit by just entering a "q" at the prompt.
#        - (PS) parseprereq() fixed
# Feb, 2009 updates
#        - (PS)  changed $sep -> $sep01 etc. to overcome Sybase error if col name is duplicated
#        - (PS)  tested on Solaris 10/Sybase 12.5 (dedicated)/EM 6.2.01
# Nov, 2008 updates
#        - (PS) revamped code to allow the 'use warnings' syntax which helps in debugging.
#        - (PS) removed the requirement for Excel to be on the machine running emminer by using XML Spreadsheet 2003 format
#        - (PS) tested on Red Hat Linux EL 4.x with Oracle 10.1 (EM 6.3.01 dedicated install)
#        - (PS) added PostgreSQL support (tested on Windows EM 6.4.01 with a ctm 6.3.01 datacenter)
#    - (PS) added sheet for DO condition ODATEs
#    - (PS) added sheet for Force Job condition ODATES
#        - (PS) fixed commandline arguments -d and -silent then added -noip to skip agent ping (using Getopt::Long; gives -noip automatically when -ip is defined)
#        - (PS) agent ping puts the multi-line reply into the IP Address cell but you need to adjust the cell in Excel to see all the lines. The old method only worked in some cases
#        - (PS) added -y commandline argument to override calendar dup check year
#        - (PS) compute column width which can be overridden by editing override_colwidth()
#        - (PS) hide password but show its length during user input
#        - (PS) added .sql to sql command files to stop Oracle getting confused
#        - (PS) sorted the '3' sheet by popularity then alphabetically
# May, 2008 updates
#        - (PS) added Group Tags Weekly Days string
#        - (PS) added Group Tags Monthly Days string
# Mar, 2007 updates
#        - (TLC) added sheet for in condition ODATEs
#        - (TLC) added sheet for out condition ODATES
#        - (TLC) added sheet for prerequisite conditions table
# Jan, 2007 updates
#        - (TH) changed "quotes" used in the select of USERGROUP (worked for
#              sybase but needed single quotes for Oracle select, caused
#              invalid select when run against Oracle
#            - (TH) Added SILENT option which will take previous input values and
#          run without being prompted (in case you want to run as a batch job)
#        - (TH) Added the notification if your daily usage exceeds a Maximum number you give.
#          This is in case you know what your maximum number of daily task are
#          and you would like the routine to inform you if you exceed that number.
#        - (TLC) Deactivated the Sybase/MSDE query for DB Parms (sp_configure) as it has
#              not really been useful
#        - (TLC) Again I have turned off "nolock" in the selects against Oracle DBs.  I think
#              the issue is that the value nolock appears in a different place for oracle
#              selects than for sybase selects.  Someone even passed that info to me but I
#              have misplaced it for now.  When I confirm this I can make a quick adjustment
#              so it is in the correct place in the select statement for Oracle queries also.
#          It is still in place for non Oracle DB queries.
#        - (TLC) Added what version of EM was being used on the Misc sheet
#
# Nov, 2006 updates follow
#        - (PS) Various overall suggestions
#            - removed the scftp subroutine
#            - removed the ecsinstall subroutine
#            - removed the selfping subroutine
#            - removed the osdetail subroutine
#            - removed the getenv subtoutine
#            - removed the getreg subroutine
#        - removed the logspace subroutine
#            - removed duplicate "command strings" for ctmfw
#            - various small code changes for overall cleanup
#            - added option to run against MSDE db (via osql)
#            - added additional debug statements which are activated by
#              invoking with "emminer -d"
#            - moved the updconfig (new routine) to execute earlier so that
#              user input is captured and updated at the start of the routine
#              instead of at the end (so if it failed it was lost)
#            - activated the "with nolock" code (had been turned off before)
#            - added a testdb routine to validate access to the db
#        - added queries based on
#          - Days of the Month string
#          - Days of the Week string
#          - Showing which security group each user belongs to
#          - Doc lib usage
#          - Override lib usage
#
#
# future ideas:
#        - add back in the global prefix to/from dc. currently DB specific
#            - Had an issue with Oracle and the substr function.
#            - Need to substring because of field size
#===============================================================================

&Housekeeping;                                                  # setup initial environment for the routine
&osvars();                                                              # setup os specific (unix/windows) behaviors, variables, ...
&getconfig();                           # access previous saved values for the upcoming prompts

&initvars();

#--------------------------------------------------------------------------
# test to see if we are running "silent" so that we do not prompt for input
# we just use the values from the last run
#--------------------------------------------------------------------------

if ($silent)
    {
        print "Silent option specified, parms used:\n\n";
        print "       file prefix: $fpref\n";
        print "        em version: $emver\n";
        print "              user: $emuser\n";
        print "         db server: $server\n";
        print "              type: $dbtypename\n";
        print "              name: $dbname\n";
        print "        report dir: $rptdir\n\n\n";
    }
else
    {
        &getuser_input();               # get the id, password, db type and server from the user
        &osvars();                                              # may have made changes to values that require variables to be reset
        &initvars();
        &updconfig();                   # save user input (except password) for later runs
    }

&initdbclient();                                                # wait until we know dbclient before initialising
                                                                                # set up some initial variables
&excelheader();                         # open the EXCEL file and write the XML header section

&testdb;                                # this routine verifies access to the db
#print ("\n\n emminer.pl starting Data Mining ... \n\n");

print ("emminer.pl the data miner is collecting needed info ... \n\n");


&dbqueries;                             # run a series of selects against the EM db


&wrapup;                                        # final details
&Cleanup();                                     # close excel if needed and cleanup temp files

if (!$silent)
        {
                print "Hit enter ...";
                $nop=<STDIN>;
        }
exit 0;




#======================     dbqueries function   ===========================

sub dbqueries
        {
                if ($debug) {print " --- dbqueries routine\n";}
                print "   --> Now mining the EM DB for info\n\n";


                # The 'Misc' sheet is different but in general if you want to add a new sheet to the spread sheet
                # it is done in the dbqueries function in the following way:
                #      1) change the line of the form $querytot=<nn>; to reflect the new total number of queries
                #      2) add a minimum of a set of 4 lines to this subroutine. Use the existing sets as examples. E.g. 'Tbls per DC'
                #           i)   $current_sheet - this sets the name of the spreadsheet tab for this sheet. It is used in putsheet
                #                and may be used as a trigger for data enrichment. E.g. in override_colwidth().
                #           ii)  $sqlquery1 - the SQL of the query to execute against the EM database. The SQL column headers become the
                #                spreadsheet column headers. Avoid queries that generate headers longer than 30 characters
                #                to avoid Oracle errors. Assume all DB object are UPPER CASE unless you know better. e.g. "select name from sysobjects" in MSSQL.
                #                Use $mycountq1, $mycountq2 and $sep01 to avoid DB specific parsing problems - use existing sets as examples.
                #           iii) dosql(1) - does the DB query based on $sqlquery1 but making DB specific substitutions as required. Returns the number of rows of data
                #                excluding headers and footers. The query output is placed in $sqloutfile ready for putsheet().
                #                dosql(0) - same as dosql(1) except increments then outputs $querycnt
                #           iv)  optionally insert an enrichment or parsing function between the dosql(1) and the putsheet(). E.g. parsecmds()
                #           iv)  putsheet() - adds a new sheet to the spreadsheet using the data in $sqloutfile

                $querytot=45;                   # current total of queries (not always up to date as others are added


                print "\n         Exploring definitions\n\n"; # print headings to the screen so user can see whats occuring
                print "    query#          description\n";
                print "    ------     -----------------------------------\n\n";

# misc tab

            $current_sheet="Misc";              # start of Misc sheet
            #open (NEWFL,">$new") || die "Can't open temp file $new. Check file and directory permissions and ownership\n";
            &Openordie("NEWFL :: $new :: > :: Could not open file $testfile to access DB dump values");
            print NEWFL "$mypreheader";
            print NEWFL " Miscellaneous $sep Value\n";
            print NEWFL "-----------------\n";
            parsemisc(1, "job defs \@$server",
                       "select count(*) ${mycountq1}job defs \@$server$mycountq2 from DEF_JOB $nolock");
            parsemisc(0, "# Cyclic Jobs",
                       "select count(*) from DEF_JOB $nolock where CYCLIC=${myquote}1$myquote");
            parsemisc(0, "# Cyclic Jobs with $MaxWait{$v8term} NOT 0",
                       "select count(*) from DEF_JOB $nolock where CYCLIC=${myquote}1$myquote and MAX_WAIT != ${myquote}0${myquote}");
            parsemisc(0, "# Non Cyclic Jobs with $MaxWait{$v8term} 0",
                       "select count(*) from DEF_JOB $nolock where CYCLIC=${myquote}0$myquote and MAX_WAIT = ${myquote}0${myquote}");

            if ($emver ge "640")
                {
                    $lastyear=$year-1;
                    $tya=$year-2;
                    $thrya=$year-3;
                    $safeday = $mday; # use Feb 28 if today is Feb 29
                    if (($mday eq "29") && ($mon eq "02")) {$safeday = "28";}
                    $oneyearago="$lastyear-$mon-$safeday";
                    $twoyearago="$tya-$mon-$safeday";
                    $threeyearago="$thrya-$mon-$safeday";
                    #print " -- oneyearago=$oneyearago\n";
                    #print " -- 2yearago=$twoyearago\n";
                    #print " -- 3yearago=$threeyearago\n";

#        $lastyear=$year-1;
#        $tya=$year-2;
#        $thrya=$year-3;
#           $oneyearago="$lastyear-$mon-$mday";
#           $twoyearago="$tya-$mon-$mday";
#           $threeyearago="$thrya-$mon-$mday";
#
#           parsemisc(0, "# Jobs run within last year (since $oneyearago)",
#                      "select count(*) from avg_run_info $nolock where last_updated >${myquote}$oneyearago$myquote");
#           parsemisc(0, "# Jobs run within last 2 years (since $twoyearago)",
#                      "select count(*) from avg_run_info $nolock where last_updated >${myquote}$twoyearago$myquote");
#           parsemisc(0, "# Jobs run within last 3 years (since $threeyearago)",
#                      "select count(*) from avg_run_info $nolock where last_updated >${myquote}$threeyearago$myquote");

                    if ($dbtype eq "O")
                        {
                                parsemisc(0, "# Jobs run within last year (since $oneyearago)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED > to_date(${myquote}$oneyearago$myquote, 'YYYY-MM-DD')");
                                parsemisc(0, "# Jobs run within last 2 years (since $twoyearago)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED > to_date(${myquote}$twoyearago$myquote, 'YYYY-MM-DD')");
                                parsemisc(0, "# Jobs run within last 3 years (since $threeyearago)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED > to_date(${myquote}$threeyearago$myquote, 'YYYY-MM-DD')");
                                parsemisc(0, "# Jobs NOT run for 3 years ($threeyearago or older)",
                                #parsemisc(0, "# Jobs last run over 3 years ago ($threeyearago or older)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED <= to_date(${myquote}$threeyearago$myquote, 'YYYY-MM-DD')");
                        }
                    else
                        {
                                parsemisc(0, "# Jobs run within last year (since $oneyearago)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED > ${myquote}$oneyearago$myquote");
                                # select data_center, sched_table, job_mem_name,node_group, last_updated from avg_run_info where last_updated > '2011-08-30';
                                parsemisc(0, "# Jobs run within last 2 years (since $twoyearago)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED > ${myquote}$twoyearago$myquote");
                                parsemisc(0, "# Jobs run within last 3 years (since $threeyearago)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED > ${myquote}$threeyearago$myquote");
                                parsemisc(0, "# Jobs NOT run for 3 years ($threeyearago or older)",
                                   "select count(*) from AVG_RUN_INFO $nolock where LAST_UPDATED <= ${myquote}$threeyearago$myquote");
                        }
                }
            %BestPracticeOffset1 = (8 => 4, 7=> 4, 6.4 => 4, 6.3 => 0, 6.2 => 0, 6.1.3 => 0);
            $bpOff1 = $BestPracticeOffset1{$emver};

            # for autoedits use the count of jobs (not each job with its count)
            $sqlquery1 = "select count(*) ,TABLE_ID, JOB_ID from DEF_SETVAR $nolock ";
            $sqlquery1 .= "GROUP BY TABLE_ID,JOB_ID ORDER BY TABLE_ID,JOB_ID";
            $aejobs = dosql(0);
            print NEWFL "  # Jobs with $AutoEdit{$v8term}s$sep$aejobs\n";

            $sqlquery1 = "select count(*) ,TABLE_ID, JOB_ID from DEF_SETVAR $nolock ";
            $sqlquery1 .= " where NAME=${myquote}%%LIBMEMSYM$myquote ";
            $sqlquery1 .= "    or NAME=${myquote}%%LIBSYM$myquote ";
            $sqlquery1 .= "    or NAME=${myquote}%%MEMSYM$myquote ";
            $sqlquery1 .= "GROUP BY TABLE_ID,JOB_ID ORDER BY TABLE_ID,JOB_ID";

            $aejobs = dosql(0);
            if ($aejobs eq -1) {$aejobs=0;}
            print NEWFL "  # Jobs with LIBMEMSYM etc $AutoEdit{$v8term}s$sep$aejobs\n";

            parsemisc(0, "# Critical Jobs",
                       "select count(*) from DEF_JOB $nolock where CRITICAL=${myquote}1$myquote");
            parsemisc(0, "# Confirm Jobs",
                       "select count(*) from DEF_JOB $nolock where CONFIRM_FLAG=${myquote}1$myquote");
            parsemisc(0, "# Multi-Agent Jobs",
                       "select count(*) from DEF_JOB $nolock where MULTY_AGENT=${myquote}Y$myquote");
            parsemisc(0, "Active in Future",
                       "select count(*) from DEF_JOB $nolock where ACTIVE_FROM > ${myquote}$today$myquote");
            parsemisc(0, "Active Until has Past",
                       "select count(*) from DEF_JOB $nolock where ACTIVE_TILL < ${myquote}$today$myquote and ACTIVE_TILL > ${myquote}00000000$myquote");
            parsemisc(0, "Using PRE or POST CMD",
                       "select count(*) ${mycountq1}# Using PRE or POST CMD$mycountq2 from DEF_SETVAR $nolock where NAME=$myquote%%PRECMD$myquote or NAME=$myquote%%POSTCMD$myquote ");

                parsemisc(0, "# with Retro",
                       "select count(*) from DEF_JOB $nolock where RETRO=${myquote}1$myquote");

            if ($emver ge "8")
                {
                    # workspaces check-in/check-out replace on-line off-line
                    parsemisc(0, "# Workspaces", "select count(*) from DEF_WS $nolock");
                    parsemisc(0, "# Workspace Folders", "select count(*) from DEF_WS_TABLES $nolock");
                    parsemisc(0, "# Workspace Jobs", "select count(*) from DEF_WS_JOBS $nolock");
                }
            %BestPracticeOffset2 = (8 => 3, 7=> 0, 6.4 => 0, 6.3 => 0, 6.2 => 0, 6.1.3 => 0);
            $bpOff2 = $BestPracticeOffset2{$emver} + $bpOff1;

                if ($emver =>9)
                        {
                                $sqlquery1 = "select NAME, \',\', STATUS, \',\', ENABLED from ADD_ONS $nolock";
                                dosql(0);

                                &Openordie("INCONF :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                                $someaddons=0;
                                while (<INCONF>)
                                        {
                                                if ($debug) {print "  -- add_on  $_";}
                                                if (index($_,"enabled") > -1) {next;}
                                                if (length($_) < 10) {next;}
                                                if (index($_,"\-\-\-\-\-\-") > -1) {next;}
                                                if ($someaddons == 0)
                                                        {
                                                            $someaddons=1;
                                                                print NEWFL "Control-M Solutions\n";
                                                        }
                                                chomp;
                                                @addons = split(/,/,"$_");
                                                @addons[0] =~ s/^\s+//;        #remove leading & trailing blanks from application
                                                @addons[0] =~ s/\s+$//;
                                                @addons[1] =~ s/^\s+//;        #remove leading & trailing blanks from application
                                                @addons[1] =~ s/\s+$//;
                                                @addons[2] =~ s/^\s+//;        #remove leading & trailing blanks from application
                                                @addons[2] =~ s/\s+$//;


                                                if ($debug) {print  " -- $sep $sep @addons[0]  @addon[2]  @addon[4] \n"; }
                                                print  NEWFL " $sep $sep @addons[0] $sep Status=@addons[1] $sep Enabled=@addons[2] \n";
                                        }
                                close INCONF;
                        }

            # put some final data details on the MISC tab

            print NEWFL "  $sep \n";
            print NEWFL "  $sep \n";
            print NEWFL " DB Type  $sep $dbtypename\n";
            print NEWFL " EM Version  $sep "."v$emver\n";
            print NEWFL " User  $sep $emuser\n";
            print NEWFL " DB Server  $sep $server\n";
            print NEWFL " emminer version $sep "."v$emminer_version\n";
            print NEWFL " emminer release date $sep "."$emminer_version_date\n";
            print NEWFL " run on $sep "."$emminer_host\n";
            print NEWFL "  $sep \n";
            print NEWFL " Starttime  $sep $emminer_starttime\n";
            &gettime();                    # reaccess the ending time of this routine and put it on the spreadsheet
            $emminer_endtime="$hour:$min:$sec";
            if ($debug) { print "end $today $emminer_endtime";}
            print NEWFL "   Endtime  $sep $emminer_endtime\n";
            print NEWFL "$myfooter";
            close NEWFL;
            system "$oscopy $new $sqloutfile > $bitbucket";
                if ($debug)
                        {
                                print "\n -- Here is the sql result file that will be pasted into the excell sheet.\n";
                                system "$ostype $sqloutfile";
                                print "\n -- That marks the end of the sql result file being processed.\n";
                        }
            putsheet();

            #deactivated TLC Jan, 2007   $current_sheet="DB Parms"; # create sql to capture DB parms from Sybase
            #deactivated TLC Jan, 2007   if (($dbtype eq "M") || ($dbtype eq "S") || ($dbtype eq "E"))      # this query is done only for non-Oracle DB right now
            #deactivated TLC Jan, 2007     {
            #deactivated TLC Jan, 2007       $sqlquery1 = "sp_configure";
            #deactivated TLC Jan, 2007     }
            #deactivated TLC Jan, 2007   else
            #deactivated TLC Jan, 2007     {
            #deactivated TLC Jan, 2007       $sqlquery1 = "show all";
            #deactivated TLC Jan, 2007     }
            #deactivated TLC Jan, 2007   dosql(1);              # call generic SQL runner subroutine
            #deactivated TLC Jan, 2007   putsheet();                # call generic parsing routine to put values into excel cells

# Data Centers

            $current_sheet="Data Centers";
            $sqlquery1 = "select DATA_CENTER,$sep01,PLATFORM,$sep02,CONTROL_M_VER,$sep03,TIME_ZONE,$sep04,CTM_DAILY_TIME,";
            $sqlquery1 .= "$sep05,CTM_ODATE,$sep06,CTM_HOST_NAME,$sep07,PROTOCOL,$sep08,CTM_PORT_NUMBER,$sep09,DESCRIPTION from COMM";
            $sqlquery1 .= " $nolock where ENABLED = ${myquote}1$myquote ";
            dosql(1);                                                                           # execute the sql selects
            putsheet();                                                                         # create the excel tab

# Components

            $current_sheet="Components";
            $sqlquery1 = "select CURRENT_STATE ${mycountq1}Current$mycountq2,$sep01,DESIRED_STATE ${mycountq1}Desired$mycountq2,$sep02,";
            #$sqlquery1 .= "$mysubstr(PROCESS_NAME,1,25) ${mycountq1}Process$mycountq2,$sep03,$mysubstr(MACHINE_NAME,1,25) ${mycountq1}Machine$mycountq2,$sep04,";
            $sqlquery1 .= "$mysubstr(MACHINE_NAME,1,25) ${mycountq1}Machine$mycountq2,$sep04,";
            $sqlquery1 .= "$mysubstr(PROCESS_COMMAND,1,80) ${mycountq1}Command$mycountq2,$sep05,";
            $sqlquery1 .= "$mysubstr(ADDITIONAL_PARAMS,1,25) ${mycountq1}Additional parms$mycountq2,$sep06,MACHINE_TYPE from CONFREG $nolock";
            dosql(1);
            putsheet();

# Jobs in Archive AJF

            $current_sheet="Jobs in $Archive{$v8term} AJF";
            if ($dbtype eq "O")                              # DB specific search for A%JOB tables to find Archive AJFs - oldest first. E.g. PostgreSQL is lower case
               {
                 $sqlquery1 = "select TABLE_NAME from CAT $nolock where TABLE_NAME like ${myquote}A${mypat}JOB$myquote and TABLE_TYPE='TABLE' order by TABLE_NAME desc";
               }
            elsif ($dbtype eq "P")
               {
                 $sqlquery1 = "select RELNAME from PG_CLASS $nolock where RELNAME like ${myquote}a${mypat}job$myquote order by RELNAME desc  ";
               }
            else
               {
                 $sqlquery1 = "select $mysubstr(name,1,20) ${mycountq1}name $mycountq2 from sysobjects $nolock where name like ${myquote}A${mypat}JOB$myquote order by name desc  ";
               }
            dosql(1);                                                                           # execute the sql selects
            parsejobcount();                                                            # parce the returned information
            putsheet();                                                                         # create the excel tab


# Job Hist by Day

            if ($emver gt "6.2")                                                        # these metrics only existed starting with version 6.3
                        {
                                $current_sheet="Job Hist by Day";
                                $sqlquery1 = "select NET_DATE ${mycountq1}Date$mycountq2,$sep01,DATA_CENTER ${mycountq1}Data Center$mycountq2,$sep02,PLATFORM,$sep03,CTM_HOST_NAME,$sep04,JOBS,$sep05,EXECUTIONS,$sep06,SCHED_GROUPS ${mycountq1}SchedGrp\/SmartTbl\/Folder$mycountq2 from NET_REPORT ORDER BY NET_DATE";
                                #$sqlquery1 = "select count(*) ${mycountq1}Jobs  per Task Type$mycountq2,$sep01,TASK_TYPE from DEF_JOB $nolock GROUP BY TASK_TYPE";
                                dosql(1);               # execute the sql selects
                                putsheet();             # create the excel tab
                        }

# Agent-Jobs

            $current_sheet="Agent-Jobs";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per agent       $mycountq2,$sep01,NODE_ID from DEF_JOB $nolock GROUP BY NODE_ID ORDER BY NODE_ID";
            $tot_agt_count = dosql(1);                  # execute the sql and capture total number of agents
            #commented out the IP resolution.  If someone wanted it, it could be turned back on
            #if ($resolveip) { parseagping();}  # optionally enrich each row to show the results of a ping
            putsheet();                         # create the excel tab

# Agents

            $current_sheet="Agents";
            $sqlquery1  = "select a.NODE_ID Agent, $sep01, a.APPLICATION App, $sep02, a.GROUP_NAME SubApp, $sep03, ".
                          "(case when a.NODE_ID = c.NODEID then c.DATA_CENTER else b.DATA_CENTER end) ctm_server, $sep04, ".
                          "(case when b.GRPNAME = a.NODE_ID then b.APPLTYPE else '' end) NodeGrpApp " .
                          "from DEF_JOB a ".
                          "left join NODE_GROUP b on a.NODE_ID = b.GRPNAME ".
                          "left join NODE_ID c on a.NODE_ID = c.NODEID ".
                          "where a.NODE_ID is not NULL ".
                          "GROUP BY NODE_ID, a.APPLICATION, a.GROUP_NAME, c.NODEID, b.DATA_CENTER, ".
                          "c.DATA_CENTER, b.GRPNAME, b.APPLTYPE ORDER BY NODE_ID, b.GRPNAME";

            $tot_agt_count = dosql(1);  # execute the sql and capture total number of agents
            putsheet();                         # create the excel tab

# CCP

            $current_sheet="CCP";
            $sqlquery1  = "SELECT distinct a.name, $sep01, a.type, $sep02, a.sub_type, $sep03, ".
                          "case when a.sub_type = b.appl_type ".
		          "then (select count(*) from public.def_job where appl_type = a.sub_type) ".
                          "else 0 end as Used ".
                          "FROM public.def_conf_items a left join public.def_job b on a.sub_type=b.appl_type ".
                          "ORDER BY a.name ASC";
            dosql(1);               # execute the sql selects
            putsheet();                         # create the excel tab
# EM Users
            $current_sheet="EM Users";
            if ($emver ne "6.1.3")                                                      # this query for versions > 6.1.3
                   {
                          $sqlquery1 = "select $mysubstr(USERNAME,1,20) ${mycountq1}EM Users$mycountq2,$sep01,$mysubstr(USERFULLNAME,1,30) ${mycountq1}Name$mycountq2,$sep02,";
                          $sqlquery1 .= "ISGROUP ${mycountq1}GROUP 1=yes$mycountq2,$sep03,PASSEXPIREDAYS ${mycountq1}Pswd Exp days $mycountq2,$sep04,";
                          $sqlquery1 .= "PASSEXPIREDATE ${mycountq1}Pswd Exp dt$mycountq2,$sep05,ISPASSEXPIRENEXTLOGON ${mycountq1}Exp Next Log$mycountq2,$sep06,";
                          $sqlquery1 .= "ISACCOUNTLOCKED ${mycountq1}Locked$mycountq2,$sep07,ACCOUNTLOCKDATE ${mycountq1}Locked Dt $mycountq2,$sep08,";
                          $sqlquery1 .= "ACCOUNTLOCKORIGINATOR ${mycountq1}Lockedby $mycountq2 from GENERALAUTHORIZATIONS $nolock ORDER BY USERNAME";
                   }
            else                                                                                        # this query if version is 6.1.3
              {
                          $sqlquery1 = "select $mysubstr(USERNAME,1,20) ${mycountq1}EM Users$mycountq2,$sep01,$mysubstr(USERFULLNAME,1,30) ${mycountq1}Name$mycountq2,$sep02,";
                          $sqlquery1 .= "ISGROUP ${mycountq1}GROUP 1=yes$mycountq2 from GENERALAUTHORIZATIONS $nolock ORDER BY USERNAME";
              }

            dosql(1);
            &parseusers();
            putsheet();

# Tasktype

            $current_sheet="Tasktype";
            $sqlquery1 = "select count(*) ${mycountq1}Jobs  per Task Type$mycountq2,$sep01,TASK_TYPE from DEF_JOB $nolock GROUP BY TASK_TYPE";
            dosql(1);
            putsheet();

# App Type

            $current_sheet="App Type";
            $sqlquery1 = "select count(*) ${mycountq1}# Jobs by Application type$mycountq2,$sep01,APPL_TYPE from DEF_JOB $nolock GROUP BY APPL_TYPE ORDER BY APPL_TYPE  ";
            dosql(1);
            putsheet();

# Reports

            $current_sheet="Reports";
            $sqlquery1 = "select NAME, $sep01, DESCRIPTION, $sep02, LAST_USED_TIME, $sep03, UPDATE_TIME, $sep04, USERNAME from RF_USERS_REPORTS $nolock";
            dosql(1);
            putsheet();

# Cal by DC

            $current_sheet="Cal by DC";           # also signals code which adds highest year for that calendar to the spreadsheet
            if ($emver lt "7")
               {
                          $sqlquery1 = "select DATA_CENTER,$sep01,CALENDAR,$sep02,CALTYPE from  DF_CALENDAR $nolock ";
                          $sqlquery1 .= "GROUP BY DATA_CENTER,CALENDAR,CAL ORDER BY DATA_CENTER,CALENDAR  ";
                   }
            else
                   {
                          $sqlquery1 = "select DATA_CENTER,$sep01,CALENDAR,$sep02,TYPE ${mycountq1}CALTYPE$mycountq2 from  DF_CALENDAR $nolock ";
                          $sqlquery1 .= "GROUP BY DATA_CENTER,CALENDAR,TYPE ORDER BY DATA_CENTER,CALENDAR  ";
                   }
            #$sqlquery1 .= "GROUP BY DATA_CENTER,CALENDAR,CALTYPE ORDER BY DATA_CENTER,CALENDAR  ";
            $tot_cal_count = dosql(1);
            $progress=0; # initialised prior to spinner usage
            $tot_Done=0; # initialised prior to spinner usage
            $upd_interval=0;
            if ($tot_cal_count > 0) {$upd_interval=$tot_cal_count/10;}

            parsecalbydc();
            putsheet();

# EMPARMS

            $current_sheet="EMPARMS";
            # initial section of this area is to individually collect the parms that we find most interesting.
            # we will grab those and save them, then grab "all" parms, then eliminate those we grabbed first from the "all" list.
            # the purpose of this is to have the final set of data have those we find interesting at the top of the list so you
            # see them first in the spreadsheet.

            $sqlquery1 = "select $mysubstr(PNAME,1,80) ${mycountq1}PName$mycountq2,$sep01,$mysubstr(FAMILY,1,80) ${mycountq1}Family$mycountq2,";
            $sqlquery1 .= "$sep02,PVALUE ${mycountq1}Value$mycountq2   from PARAMS $nolock ";
            #$sqlquery1 .= "$sep02,$mysubstr(PVALUE,1,80) ${mycountq1}Value$mycountq2   from PARAMS $nolock "; substr truncates value so compare with default is problematic
            $sqlquery1 .= " where PNAME=${myquote}ControlM_EM_Version$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}UserAuditOn$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}UserAuditAnnotationOn$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}AuditHistoryDays$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}ApplyAnnotationForAuditContext$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}MaxOldDay$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}MaxOldTotal$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}SendSnmp$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}SnmpHost$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}SnmpSendActive$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}SendAlarmToScript$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}HandleAlertsOnRerun$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}DirectoryServiceType$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}VMVersionsNumberToKeep$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}LogHistoryDays$myquote ";
            $sqlquery1 .= "    or PNAME=${myquote}MaxDaysAlertRetained$myquote ";



            dosql(0);
            @holdtopparms=();
            #open (TEMP,"<$sqloutfile") || die "Can't open temp file $sqloutfile to retrieve specific EMPARM values. \n";
            &Openordie("TEMP :: $sqloutfile :: < :: Cannot open temp file $sqloutfile to retrieve specific EMPARM values.");
            while (<TEMP>)
              {
                #print " --input:$_";
                push(@holdtopparms,"$_");
              }
            close TEMP;

            $sqlquery1 = "select $mysubstr(PNAME,1,80) ${mycountq1}PName    $mycountq2,$sep01,$mysubstr(FAMILY,1,80) ${mycountq1}Family$mycountq2,";
            $sqlquery1 .= "$sep02,PVALUE ${mycountq1}Value$mycountq2   from PARAMS $nolock ";
            #$sqlquery1 .= "$sep02,$mysubstr(PVALUE,1,80) ${mycountq1}Value$mycountq2   from PARAMS $nolock "; substr truncates value so compare with default is problematic

            dosql(1);
            system ("$oscopy $sqloutfile $sqloutfileb > $bitbucket"); #save the full parmlist sql results
            #open (TEMPB,"<$sqloutfileb") || die "Can't open temp file $sqloutfileb to reread in EMPARM values.\n";
            &Openordie("TEMPB :: $sqloutfileb :: < :: Cannot open ttemp file $sqloutfileb to reread in EMPARM values.");
            #open (TEMP,">$sqloutfile") || die "Can't open temp file $sqloutfile to retrieve specific EMPARM values. \n";
            &Openordie("TEMP :: $sqloutfile :: > :: Cannot open temp file $sqloutfile to retrieve specific EMPARM values.");
            foreach my $x(@holdtopparms)
                {
                        print TEMP "$x";    # that should place the header line and the top parms into our working file
                }

            while (<TEMPB>)
                {
                      if (index($_,"PName   ") > -1)
                          {
                                  if ($debug) {print " -- skipping assumed header line with value PName\n";}
                                  next;
                              }
                          if (index($_,"------") > -1)
                          {
                                  if ($debug) {print " -- skipping assumed header line with value ------\n";}
                                  next;
                              }

                          if (index($_,"ControlM_EM_Version") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"UserAuditOn") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"UserAuditAnnotationOn") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"AuditHistoryDays") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"ApplyAnnotationForAuditContext") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"MaxOldDay") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"MaxOldTotal") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if ((index($_,"SendSnmp") > -1) & (index($_,"XSendSnmp") == -1)) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if ((index($_,"SnmpHost") > -1) & (index($_,"XSnmpHost") == -1)) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if ((index($_,"SnmpSendActive") > -1)) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if ((index($_,"SendAlarmToScript") > -1)) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"HandleAlertsOnRerun") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"DirectoryServiceType") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"VMVersionsNumberToKeep") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"LogHistoryDays") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if (index($_,"MaxDaysAlertRetained") > -1) {if ($debug) {print " -- skipping previously captured line: $_";}next;}
                          if ($debug) {print " -- passing into work file: $_";}
                          print TEMP "$_";
                          $|++;                                   # causes the perl print buffer to immediately flush
               }
            close TEMP;
            close TEMPB;

            putsheet();

# App

            $current_sheet="App";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per Application$mycountq2,$sep01,APPLICATION from DEF_JOB $nolock GROUP BY APPLICATION ORDER BY APPLICATION";
            #$sqlquery1 = "select count(*) ${mycountq1}#Jobs per Application$mycountq2,$sep01,APPLICATION from DEF_JOB $nolock GROUP BY APPLICATION ORDER BY ${mycountq1}#Jobs per Application$mycountq2 DESC";
            dosql(1);
            putsheet();

# Grp
            $current_sheet="$Group{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per $Group{$v8term}$mycountq2,$sep01,";
            $sqlquery1 .= "GROUP_NAME ${mycountq1}$Group{$v8term} name$mycountq2 from DEF_JOB $nolock GROUP BY GROUP_NAME ORDER BY GROUP_NAME";
            #$sqlquery1 = "select count(*) ${mycountq1}#Jobs per Group$mycountq2,$sep01,GROUP_NAME from DEF_JOB $nolock GROUP BY GROUP_NAME ORDER BY ${mycountq1}#Jobs per Group$mycountq2 DESC";
            dosql(1);
            putsheet();


# App-SubApp
            $current_sheet="App-SubApp";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per $Group{$v8term}$mycountq2,$sep01,";
            $sqlquery1 .= "APPLICATION,$sep01,GROUP_NAME ${mycountq1}$Group{$v8term} name$mycountq2 from DEF_JOB $nolock GROUP BY APPLICATION,GROUP_NAME ORDER BY APPLICATION,GROUP_NAME";
            dosql(1);
            putsheet();


# Alerts
            #print " -- mycountq1=${mycountq1}\n";
            #print " -- mycountq2=${mycountq2}\n";
            $s1="$myquote:-:$myquote ${mycountq1}:-01:${mycountq2}";
            #print " -- s1=$s1\n";
            $s2="$myquote:-:$myquote ${mycountq1}:-02:${mycountq2}";
            $s3="$myquote:-:$myquote ${mycountq1}:-03:${mycountq2}";
            $s4="$myquote:-:$myquote ${mycountq1}:-04:${mycountq2}";
            $s5="$myquote:-:$myquote ${mycountq1}:-05:${mycountq2}";
            $s6="$myquote:-:$myquote ${mycountq1}:-06:${mycountq2}";
            $s7="$myquote:-:$myquote ${mycountq1}:-07:${mycountq2}";
            $s8="$myquote:-:$myquote ${mycountq1}:-08:${mycountq2}";
            $s9="$myquote:-:$myquote ${mycountq1}:-09:${mycountq2}";
            $s10="$myquote:-:$myquote ${mycountq1}:-10:${mycountq2}";
            $s11="$myquote:-:$myquote ${mycountq1}:-11:${mycountq2}";
            $s12="$myquote:-:$myquote ${mycountq1}:-12:${mycountq2}";
            $s13="$myquote:-:$myquote ${mycountq1}:-13:${mycountq2}";
            $s14="$myquote:-:$myquote ${mycountq1}:-14:${mycountq2}";
            $s15="$myquote:-:$myquote ${mycountq1}:-15:${mycountq2}";
            $s16="$myquote:-:$myquote ${mycountq1}:-16:${mycountq2}";
            $s17="$myquote:-:$myquote ${mycountq1}:-17:${mycountq2}";
            $s18="$myquote:-:$myquote ${mycountq1}:-18:${mycountq2}";
            $s19="$myquote:-:$myquote ${mycountq1}:-19:${mycountq2}";
            $current_sheet="Alerts";
            $sqlquery1 = "select count(*) ${mycountq1}#Alerts by Handled status$mycountq2,$sep01,HANDLED from ALARM $nolock GROUP BY HANDLED ORDER BY HANDLED   ";
            dosql(1);
            #putsheet();
            system ("$oscopy $sqloutfile $sqloutfileb > $bitbucket"); #save the sql results as we will append to them in a few pico seconds

            $sqlquery1 = "select MEMNAME,$s1,APPLICATION,$s2,GROUP_NAME,$s3,MESSAGE,$s4,HANDLED,$s5,JOB_NAME,$s6,SEVERITY,$s7,ORDER_ID,$s8,USER_ID,$s9,NODE_ID,$s10,HOST_TIME,$s11,CHANGED_BY,$s12,UPD_TIME,$s13,NOTES,$s14,DATA_CENTER,$s15,SERIAL,$s16,TYPE,$s17,CLOSED_FROM_EM,$s18,TICKET_NUMBER,$s19,RUN_COUNTER from ALARM $nolock";
            #print " -- sqlquery1=$sqlquery1\n";

            dosql(0);

            #open (TEMP,"<$sqloutfile") || die "Can't open temp file $sqloutfile to analyse ALARM records. \n";
            &Openordie("TEMP :: $sqloutfile :: < :: Cannot open temp file $sqloutfile to analyse ALARM records.");

            if ($debug) {print "\n -- initializing all alert tally variables\n";}
            @alerttype_agstatus=0;      # STATUS OF AGENT
            @alerttype_notok=0;                 # "ENDED NOTOK" or "FAILED"
            @alerttype_restart=0;       # RESTART
            @alerttype_long=0;                  # LONG or "RUNNING MORE" or "OVER AVERAGE" or "EXCEEDED"
            @alerttype_late=0;                  # LATE
            @alerttype_notstarted=0;    # "NOT STARTED"
            @alerttype_notsub=0;                # "NOT SUBMITTED"
            @alerttype_ok=0;                    # COMPLETED or OK (tested after other types in fall thru logic)
            @alerttype_system=0;        # things from control-M
            @alerttype_sla=0;           # "SLA Warning"
            @alerttype_other=0;         # everything else
            @alerttype_bim=0;           # everything else

            @appname=();
            @appalerts=();
            @job10ormore=();
            @nodestatsus=();

            while (<TEMP>)
              {
                          if ($debug) {print "\nalertinput: $_";}
                          if ((index($_,":-01:") > -1) || (index($_,"--------------------------------------")>-1))
                             {
                                     if ($debug) {print "\n -- tossing out header line from alarm table list\n";}
                                     next;
                             }
                          chomp;
                          @alarmarray = split(/:-:/,"$_");
                  if ($debug)
                     {
                             print "\n --- alert record ---\n";
                             print "     f0  = $alarmarray[0]\n";
                             print "     f1  = $alarmarray[1]\n";       # application
                             print "     f2  = $alarmarray[2]\n";  # group
                             print "     f3  = $alarmarray[3]\n";       # message
                             print "     f4  = $alarmarray[4]\n";
                             print "     f5  = $alarmarray[5]\n";
                             print "     f6  = $alarmarray[6]\n";
                             print "     f7  = $alarmarray[7]\n";
                             print "     f8  = $alarmarray[8]\n";
                             print "     f9  = $alarmarray[9]\n";
                             print "     f10  = $alarmarray[10]\n";
                             print "     f11  = $alarmarray[11]\n";
                             print "     f12  = $alarmarray[12]\n";
                             print "     f13  = $alarmarray[13]\n";
                             print "     f14  = $alarmarray[14]\n";
                             print "     f15  = $alarmarray[15]\n";
                             print "     f16  = $alarmarray[16]\n";
                             print "     f17  = $alarmarray[17]\n";
                             print "     f18  = $alarmarray[18]\n";
                     }

                  # typically a blank application field represents an alert which came from Control-M so setting the application to Control-M here for those lines
                  $alarmarray[1] =~ s/^\s+//;        #remove leading & trailing blanks from application
                  $alarmarray[1] =~ s/\s+$//;
                  if ($alarmarray[1] eq "") {$alarmarray[1]="Control-M";}
                  if ($debug) {print "\n -- alerts application=$alarmarray[1].\n";}
                  $app_ind=-1;
                  foreach my $a (@appname)
                       {
                               $app_ind++;
                               if ($a eq $alarmarray[1])
                                    {
                                            if ($debug) {print "   matched previously seen application\n";}
                                            $appalerts[$app_ind]++;                     # increment how many alerts this application has had
                                            if ($debug) {print " -- non initial assignment of a new app into the appname array, pre determine alerttype_system[$app_ind]=@alerttype_system[$app_ind]\n";}

                                            &determinealerttype;
                                            if ($debug) {print " -- non initial assignment of a new app into the appname array, post determine alerttype_system[$app_ind]=@alerttype_system[$app_ind]\n";}
                                            goto nxtalarmrec;
                                    }


                       }
newapp:
                          $app_ind++;
                          $appname[$app_ind]="$alarmarray[1]";                                  # move newly seen application name into appname array
                      $appalerts[$app_ind]=1;                                                           # initial alert for this application
                      if ($debug) {print " -- initial assignment of a new app into the appname array, pre determine alerttype_system[$app_ind]=@alerttype_system[$app_ind]\n";}
                      &determinealerttype;
                      if ($debug) {print " -- initial assignment of a new app into the appname array, post determine alerttype_system[$app_ind]=@alerttype_system[$app_ind]\n";}

                          #&Pauser(884);
nxtalarmrec:
              }

            close TEMP;
            #open (TEMP,">>$sqloutfileb") || die "Can't open temp file $sqloutfile to add alarm analysis. \n";
             &Openordie("TEMP :: $sqloutfileb :: >> :: Cannot open temp file $sqloutfile to add alarm analysis. ");


                $dat_ind=-1;
                print TEMP ".      \n";
                print TEMP ".      \n";
                print TEMP ".__________________________________________________________________________________________________________________________________________     \n";
                print TEMP ".      \n";

                print TEMP ".application$sep"." ag $sep"."     $sep"."res-$sep"."     $sep"."     $sep"."     $sep"."     $sep"."     $sep"."      $sep"."not  $sep"."not $sep"."    $sep"."    \n";
                print TEMP ".           $sep"."stat$sep"."notok$sep"."tart$sep"." sys $sep"."other$sep"." sla $sep"."late $sep"." bim $sep"."  OK  $sep"."submt$sep"."strt$sep"."long$sep"."rest\n";
                print TEMP ".      \n";
                foreach my $da (@appname)
                     {
                              $dat_ind++;
                              if (@alerttype_agstatus[$dat_ind] eq "") {@alerttype_agstatus[$dat_ind]=0;}
                                  if (@alerttype_notok[$dat_ind] eq "") {@alerttype_notok[$dat_ind]=0;}
                                  if (@alerttype_restart[$dat_ind] eq "") {@alerttype_restart[$dat_ind]=0;}
                                  if (@alerttype_long[$dat_ind] eq "") {@alerttype_long[$dat_ind]=0;}
                                  if (@alerttype_late[$dat_ind] eq "") {@alerttype_late[$dat_ind]=0;}
                                  if (@alerttype_notstarted[$dat_ind] eq "") {@alerttype_notstarted[$dat_ind]=0;}
                                  if (@alerttype_notsub[$dat_ind] eq "") {@alerttype_notsub[$dat_ind]=0;}
                                  if (@alerttype_ok[$dat_ind] eq "") {@alerttype_ok[$dat_ind]=0;}
                                  if (@alerttype_system[$dat_ind] eq "") {@alerttype_system[$dat_ind]=0;}
                                  if (@alerttype_sla[$dat_ind] eq "") {@alerttype_sla[$dat_ind]=0;}
                                  if (@alerttype_other[$dat_ind] eq "") {@alerttype_other[$dat_ind]=0;}
                                  if (@alerttype_bim[$dat_ind] eq "") {@alerttype_bim[$dat_ind]=0;}
                              print TEMP ".$da$sep$alerttype_agstatus[$dat_ind]$sep$alerttype_notok[$dat_ind]$sep$alerttype_restart[$dat_ind]$sep$alerttype_system[$dat_ind]$sep$alerttype_other[$dat_ind]$sep$alerttype_sla[$dat_ind]$sep$alerttype_late[$dat_ind]$sep$alerttype_bim[$dat_ind]$sep$alerttype_ok[$dat_ind]$sep$alerttype_notsub[$dat_ind]$sep$alerttype_notstarted[$dat_ind]$sep$alerttype_long[$dat_ind]$sep$alerttype_restart[$dat_ind]\n";
                        }
                close TEMP;
            system ("$oscopy $sqloutfileb $sqloutfile > $bitbucket"); # move completed analysis file back to sqloutfile for putsheet processing.
                putsheet();

# Jobs-Tbls_DCs

            $current_sheet="Jobs-$Tbl{$v8term}s-DCs";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per $table{$v8term} by DC$mycountq2,$sep01,DEF_TABLES.SCHED_TABLE,$sep02,DEF_TABLES.DATA_CENTER ";
            $sqlquery1 .= "from DEF_JOB,DEF_TABLES $nolock where DEF_JOB.TABLE_ID=DEF_TABLES.TABLE_ID GROUP BY DEF_TABLES.DATA_CENTER,";
            $sqlquery1 .= "DEF_TABLES.SCHED_TABLE ORDER BY DEF_TABLES.DATA_CENTER,DEF_TABLES.SCHED_TABLE";  # 1 select over 3 lines

            #$sqlquery1 = "select count(*) ${mycountq1}#Jobs per table by DC$mycountq2,$sep01,DEF_TABLES.SCHED_TABLE,$sep02,DEF_TABLES.DATA_CENTER ";
            #$sqlquery1 .= "from DEF_JOB,DEF_TABLES $nolock where DEF_JOB.TABLE_ID=DEF_TABLES.TABLE_ID GROUP BY DEF_TABLES.DATA_CENTER,";
            #$sqlquery1 .= "DEF_TABLES.SCHED_TABLE ORDER BY ${mycountq1}#Jobs per table by DC$mycountq2 DESC";  # 1 select over 3 lines

            dosql(1);
            putsheet();

# Tbls Per DC

            $current_sheet="$Tbl{$v8term}s per DC";
            $sqlquery1 = "select count(*) ${mycountq1}# Sched $table{$v8term}s per DC$mycountq2,$sep01,DATA_CENTER from DEF_TABLES $nolock GROUP BY DATA_CENTER";
            dosql(1);

            system ("$oscopy $sqloutfile $sqloutfileb > $bitbucket"); #save the original info of tables per dc,  now going to add more info.

            &Openordie("TEMPB :: $sqloutfileb :: >> :: Cannot open ttemp file $sqloutfileb to write additional table information stats.");
            $sqlquery1 = "select count(*) ${mycountq1}count$mycountq2 from DEF_TABLES $nolock";
            dosql(0);

            &Openordie("outfile :: $sqloutfile :: < :: Cannot open file $sqloutfile to read # of total tables.");

            while(<outfile>)
                {
                        if (index("$_","count")> -1) {next;}
                        if (index("$_","\-\-\-")> -1) {next;}
                        chomp;
                        if ($_ eq "") {next;}
                        $value1=$_;
                        print TEMPB "\n";
                        print TEMPB "\n";
                        print TEMPB "Total # of Tables $value1\n";    # total number of tables
                }
            close outfile;

            $sqlquery1 = "select count(*) ${mycountq1}count$mycountq2 from DEF_TABLES $nolock where TABLE_TYPE=2";
            dosql(0);
            &Openordie("outfile :: $sqloutfile :: < :: Cannot open file $sqloutfile to read # of smart tables.");
            $pst=0;
            while(<outfile>)
                {
                        if (index("$_","count")> -1) {next;}
                        if (index("$_","\-\-\-")> -1) {next;}
                        chomp;
                        if ($_ eq "") {next;}
                        $value2=$_;
                        if (($value1 > 0) && ($value2 > 0)) {$pst=$value2/$value1*100;}
                        #print "--------hello2-------\n";
                        #$pst=printf ("  %5d2",$pst);
                        #print "--------hello3-------\n";
                        print TEMPB "\n";
                        print TEMPB "\n";
                        #print TEMPB "      # of Smart Tables $value2     ($pst%)";    # total smart tables and percentage
                        printf TEMPB ("      # of Smart Tables %6d       (%6d%%)",$value2,$pst);
                }
            close outfile;
            close TEMPB;
            system ("$oscopy $sqloutfileb $sqloutfile > $bitbucket"); #save the completed info of tables per dc and counts and process.
            #system ("type $sqloutfile");

            putsheet();



# Tbls Per Workspace

            if ($emver ge "8")          # these metrics only existed starting with version 8
                {
                        $current_sheet="$Tbl{$v8term}s per WS";
                        $sqlquery1 = "select count(*) ${mycountq1}# Folders per Workspace$mycountq2,$sep01,NAME,$sep02,OWNER,$sep03,STATE ";
                        $sqlquery1 .= "from DEF_WS,DEF_WS_TABLES $nolock where DEF_WS.WID=DEF_WS_TABLES.WID GROUP BY NAME, OWNER, STATE ";
                        $sqlquery1 .= "order by NAME, OWNER";
                        dosql(1);
                        putsheet();
                }

# Def cond Out Odates

            $current_sheet="Def cond Out Odates";
            $sqlquery1 = "select count(*) ${mycountq1}# ODATEs in Out conditions$mycountq2,$sep01,ODATE from DEF_LNKO_P $nolock GROUP BY ODATE ORDER BY ODATE  ";
            dosql(1);
            putsheet();

# Def cond In Odates

            $current_sheet="Def cond In Odates";
            $sqlquery1 = "select count(*) ${mycountq1}# ODATEs in In conditions$mycountq2,$sep01,ODATE from DEF_LNKI_P $nolock GROUP BY ODATE ORDER BY ODATE  ";
            dosql(1);
            putsheet();

# Def cond ForceJ Odates
            $current_sheet="Def cond ForceJ Odates";
            $sqlquery1 = "select count(*) ${mycountq1}# ODATEs in Force Job conds$mycountq2,$sep01,ODATE from DEF_DO_FORCEJ $nolock GROUP BY ODATE ORDER BY ODATE  ";
            dosql(1);
            putsheet();

# With Holiday cal

#           $current_sheet="With Holiday cal";
#           $sqlquery1 = "select count(*) ${mycountq1}#with Holiday Cal$mycountq2,$sep01,CONF_CAL from DEF_JOB $nolock GROUP BY CONF_CAL ORDER BY CONF_CAL ";
#           dosql(1);
#           putsheet();

# With Weekly cal

#           $current_sheet="With Weekly cal";
#           $sqlquery1 = "select count(*) ${mycountq1}#with Weekly Cal$mycountq2,$sep01,WEEKS_CAL from DEF_JOB $nolock GROUP BY WEEKS_CAL ORDER BY WEEKS_CAL  ";
#           dosql(1);
#           putsheet();

# With Monthly cal

#           $current_sheet="With Monthly cal";
#           $sqlquery1 = "select count(*) ${mycountq1}#Jobs with Monthly Cal$mycountq2,$sep01,DAYS_CAL from DEF_JOB $nolock GROUP BY DAYS_CAL  ";
#           dosql(1);
#           putsheet();


# Days str

            $current_sheet="Days str";
            $sqlquery1 = "select count(*) ${mycountq1}#Monthly days strings$mycountq2,$sep01,DAY_STR from DEF_JOB $nolock GROUP BY DAY_STR  ";
            dosql(1);
            putsheet();

# WDays str

            $current_sheet="WDays str";
            $sqlquery1 = "select count(*) ${mycountq1}#Weekly days strings$mycountq2,$sep01,W_DAY_STR from DEF_JOB $nolock GROUP BY W_DAY_STR  ";
            dosql(1);
            putsheet();

# On Stmt

            $current_sheet="On Stmt";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs On Statement$mycountq2,$sep01,$mysubstr(STMT,1,25) ";
            $sqlquery1 .= "${mycountq1}Statement$mycountq2 from DEF_ON $nolock GROUP BY STMT ORDER BY STMT";
            dosql(1);
            putsheet();

# DO Action

            $current_sheet="DO Action";
            $sqlquery1 = "select count(*) ${mycountq1}#DO actions$mycountq2,$sep01,ACTION from DEF_DO $nolock GROUP BY ACTION ORDER BY ACTION";
            dosql(1);
            putsheet();

# CMDLine

            #$current_sheet="CMDLine";
            #$sqlquery1 = "select CMD_LINE from DEF_JOB $nolock where TASK_TYPE=${myquote}Command$myquote";
            #print "\b\b\b\b\b\b\b\b\b\b          \n                 --- You control what is scanned for in tab CMDline by\n";
            #print "                     editing $cmdstrings\n\n";
            #dosql(1);
            #parsecmds();
            #putsheet();

# Shouts

            $current_sheet="Shouts";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs with Shout$mycountq2,$sep01,WHEN_COND from DEF_SHOUT $nolock GROUP BY WHEN_COND ORDER BY WHEN_COND  ";
            dosql(1);
            putsheet();

# Jobs w Globals

            $current_sheet="Jobs w Globals";
            $sqlquery1 = "select $mysubstr(PREFIX,1,25) ${mycountq1}Global prefixes$mycountq2 from GLOBAL_COND $nolock ORDER BY PREFIX";
            $jg_count = dosql(1);

            if ($jg_count > 0)
                 {
                         #               $jg_count++; # seemed to always be 1 less than the actual number
                      parsejobglobals();
                 }
            putsheet();                 #puts the sheet for jobs with in or out that were global conditions

# Globals

            $current_sheet="Globals";
            if ($dbtype eq "S")                 # this sheet was misaligned greatly due to SQL errors on the latest sybase versions. So for now, it only shows the global prefixes.
              {                                 # it appears that you cannot execute a substring against a field which has an underscore in it like TO_DC or FROM_DC.
                $sqlquery1 = "select $mysubstr(PREFIX,1,25) ${mycountq1}Global prefixes$mycountq2 from GLOBAL_COND $nolock ORDER BY PREFIX";
              }
            else
              {                                 # this original query for prefixes also lists to and from data centers
                $sqlquery1 = "select $mysubstr(PREFIX,1,25) ${mycountq1}Global prefixes$mycountq2,$sep01,FROM_DC ${mycountq1}From Data Center$mycountq2,$sep02,";
                $sqlquery1 .= "TO_DC ${mycountq1}To Data Center$mycountq2 from GLOBAL_COND $nolock ORDER BY PREFIX";
              }
            dosql(1);
            putsheet();

# GrpTag Days str

            $current_sheet="RulesBasedCal MDays";
            $sqlquery1 = "select count(*) ${mycountq1}#RulesBasedCal monthly days$mycountq2,$sep01,DAY_STR from DEF_TAGS $nolock GROUP BY DAY_STR";
            dosql(1);
            putsheet();

# GrpTag WDays str

            $current_sheet="RulesBaesdCal WDays";
            $sqlquery1 = "select count(*) ${mycountq1}#RulesBasedCal weekly days$mycountq2,$sep01,W_DAY_STR from DEF_TAGS $nolock GROUP BY W_DAY_STR";
            dosql(1);
            putsheet();

# FromTime

            $current_sheet="FromTime";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs by From Time$mycountq2,$sep01,FROM_TIME from DEF_JOB $nolock GROUP BY FROM_TIME ORDER BY FROM_TIME";
            dosql(1);
            putsheet();

# ToTime

            $current_sheet="ToTime";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs by To Time$mycountq2,$sep01,TO_TIME from DEF_JOB $nolock GROUP BY TO_TIME ORDER BY TO_TIME";
            dosql(1);
            putsheet();

# Max Wait

            $current_sheet="$MaxWait{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#by $MaxWait{$v8term}$mycountq2,$sep01,MAX_WAIT from DEF_JOB $nolock GROUP BY MAX_WAIT ORDER BY MAX_WAIT";
            dosql(1);
            putsheet();

# TimeZone

            $current_sheet="TimeZone";
            $sqlquery1 = "select count(*) ${mycountq1}# of Jobs$mycountq2,$sep01,TIME_ZONE from DEF_JOB $nolock group by TIME_ZONE order by TIME_ZONE ";
            dosql(1);
            putsheet();

# Priority

            $current_sheet="Priority";
            $sqlquery1 = "select count(*) ${mycountq1}# of Jobs$mycountq2,$sep01,PRIORITY from DEF_JOB $nolock group by PRIORITY order by PRIORITY";
            dosql(1);
            putsheet();

# Intervals

            $current_sheet="Intervals";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per Interval$mycountq2,$sep01,INTERVAL from DEF_JOB $nolock where CYCLIC=${myquote}1$myquote";
            $sqlquery1 .=  "GROUP BY INTERVAL ORDER BY INTERVAL";
            dosql(1);
            putsheet();

# Author

            $current_sheet="$Author{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per $Author{$v8term}$mycountq2,$sep01,AUTHOR from DEF_JOB $nolock GROUP BY AUTHOR ORDER BY AUTHOR";
            dosql(1);
            putsheet();

# Owner

            $current_sheet="$Owner{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#Jobs per $Owner{$v8term}$mycountq2,$sep01,OWNER from DEF_JOB $nolock GROUP BY OWNER ORDER BY OWNER";
            dosql(1);
            putsheet();

# Tbls per User Daily

            $current_sheet="$Tbl{$v8term}s per $UserDaily{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#Sched $table{$v8term}s per Daily$mycountq2,$sep01,DATA_CENTER,$sep02,USER_DAILY from DEF_TABLES $nolock ";
            $sqlquery1 .= "GROUP BY DATA_CENTER,USER_DAILY ORDER BY DATA_CENTER,USER_DAILY ";
            dosql(1);
            putsheet();

# Def cond Do Odates

            $current_sheet="Def cond Do Odates";
            $sqlquery1 = "select count(*) ${mycountq1}# ODATEs in On/Do conditions$mycountq2,$sep01,ODATE from DEF_DO_COND $nolock GROUP BY ODATE ORDER BY ODATE  ";
            dosql(1);
            putsheet();

# overlib

            $current_sheet="$Overlib{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#jobs per $Overlib{$v8term}$mycountq2,$sep01,OVER_LIB from DEF_JOB $nolock GROUP BY OVER_LIB ORDER BY OVER_LIB";
            dosql(1);
            putsheet();

# memlib

            $current_sheet="$Memlib{$v8term}";
            $sqlquery1 = "select count(*) ${mycountq1}#jobs per $Memlib{$v8term}$mycountq2,$sep01,MEM_LIB from DEF_JOB $nolock GROUP BY MEM_LIB ORDER BY MEM_LIB";
            dosql(1);
            putsheet();

# doclib
            $current_sheet="doclib";
            $sqlquery1 = "select count(*) ${mycountq1}#jobs per Doc lib$mycountq2,$sep01,DOC_LIB from DEF_JOB $nolock GROUP BY DOC_LIB ORDER BY DOC_LIB";
            dosql(1);
            putsheet();

# Prereq Conds

            $current_sheet="Prereq Conds";
            if ($dbtype eq "O")                                                   # DB specific search for A%RES_P tables. E.g. PostgreSQL is lower case
               {
                 $sqlquery1 = "select TABLE_NAME from CAT $nolock where TABLE_NAME like ${myquote}A${mypat}RES_P$myquote and TABLE_TYPE='TABLE' order by TABLE_NAME desc";
               }
            elsif ($dbtype eq "P")
               {
                 $sqlquery1 = "select RELNAME from PG_CLASS $nolock where RELNAME like ${myquote}a${mypat}res_p$myquote order by RELNAME DESC  ";
               }
            else
               {
                 $sqlquery1 = "select $mysubstr(name,1,20) ${mycountq1}name $mycountq2 from sysobjects $nolock where name like ${myquote}A${mypat}RES_P$myquote order by name desc  ";
               }

            dosql(1);
            parseprereq();
            putsheet();

# SYM type AutoEdits

            $current_sheet="SYM";
            $sqlquery1 = "select count(*) ${mycountq1}#jobs per SYM type $AutoEdit{$v8term}$mycountq2,$sep01,NAME,$sep02,VALUE from DEF_SETVAR $nolock ";
            $sqlquery1 .= " where NAME=${myquote}%%LIBMEMSYM$myquote ";
            $sqlquery1 .= "    or NAME=${myquote}%%LIBSYM$myquote ";
            $sqlquery1 .= "    or NAME=${myquote}%%MEMSYM$myquote ";
            $sqlquery1 .= "GROUP BY NAME,VALUE ORDER BY VALUE,NAME";
            dosql(1);
            putsheet();
        }  # enddbquery

#-------------------------------------------------------------
# subroutine excelheader, put information at top of excel file
#-------------------------------------------------------------

sub excelheader
        {G
          #open (EXCEL, "> $excelfile" );    # open the file to write the excel spreadsheet in xml format
          &Openordie("EXCEL :: $excelfile :: > :: Cannot open to write the excel spreadsheet in xml format ");
          print EXCEL "<?xml version=\"1.0\"?>\n";
          print EXCEL "<?mso-application progid=\"Excel.Sheet\"?>\n";
          print EXCEL "<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\"\n";
          print EXCEL " xmlns:o=\"urn:schemas-microsoft-com:office:office\"\n";
          print EXCEL " xmlns:x=\"urn:schemas-microsoft-com:office:excel\"\n";
          print EXCEL " xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\"\n";
          print EXCEL " xmlns:html=\"http://www.w3.org/TR/REC-html40\">\n";
          print EXCEL " <DocumentProperties xmlns=\"urn:schemas-microsoft-com:office:office\">\n";
          print EXCEL "  <Author>emminer$emminer_version</Author>\n";
          print EXCEL "  <LastAuthor>emminer</LastAuthor>\n";
          print EXCEL "  <Created>2008-11-30T10:02:01Z</Created>\n";
          print EXCEL "  <LastSaved>2008-11-30T10:00:00Z</LastSaved>\n";
          print EXCEL "  <Version>12.00</Version>\n";
          print EXCEL " </DocumentProperties>\n";
          print EXCEL " <ExcelWorkbook xmlns=\"urn:schemas-microsoft-com:office:excel\">\n";
          print EXCEL "  <WindowHeight>9000</WindowHeight>\n";
          print EXCEL "  <WindowWidth>18000</WindowWidth>\n";
          print EXCEL "  <WindowTopX>360</WindowTopX>\n";
          print EXCEL "  <WindowTopY>105</WindowTopY>\n";
          print EXCEL "  <ProtectStructure>False</ProtectStructure>\n";
          print EXCEL "  <ProtectWindows>False</ProtectWindows>\n";
          print EXCEL " </ExcelWorkbook>\n";
          print EXCEL " <Styles>\n";
          print EXCEL "  <Style ss:ID=\"Default\" ss:Name=\"Normal\">\n";
          print EXCEL "   <Alignment ss:Vertical=\"Bottom\"/>\n";
          print EXCEL "   <Borders/>\n";
          print EXCEL "   <Font ss:FontName=\"Calibri\" x:Family=\"Swiss\" ss:Size=\"11\" ss:Color=\"#000000\"/>\n";
          print EXCEL "   <Interior/>\n";
          print EXCEL "   <NumberFormat/>\n";
          print EXCEL "   <Protection/>\n";
          print EXCEL "  </Style>\n";

          # this is the part that defines the style used for bold red
          print EXCEL "  <Style ss:ID=\"s21\">\n";
          print EXCEL "   <NumberFormat/>\n";
          print EXCEL "  </Style>\n";
          print EXCEL "  <Style ss:ID=\"s22\">\n";
          print EXCEL "   <NumberFormat ss:Format=\"0000\"/>\n";
          print EXCEL "  </Style>\n";
          print EXCEL "  <Style ss:ID=\"s23\">\n";
          print EXCEL "   <Alignment ss:Vertical=\"Bottom\" ss:WrapText=\"1\"/>\n";
          print EXCEL "  </Style>\n";
          print EXCEL "  <Style ss:ID=\"s27\">\n";
          print EXCEL "   <Font ss:FontName=\"Calibri\" x:Family=\"Swiss\" ss:Size=\"16\" ss:Color=\"#FF0000\"\n";
          print EXCEL "    ss:Bold=\"1\"/>\n";
          print EXCEL "   <NumberFormat/>\n";
          print EXCEL "  </Style>\n";


          print EXCEL "  <Style ss:ID=\"s63\">\n";
          print EXCEL "   <Alignment ss:Vertical=\"Bottom\" ss:WrapText=\"1\"/>\n";
          print EXCEL "  </Style>\n";
          print EXCEL "  <Style ss:ID=\"s64\">\n";
          print EXCEL "   <NumberFormat/>\n";
          print EXCEL "  </Style>\n";
          print EXCEL "  <Style ss:ID=\"s65\">\n";
          print EXCEL "   <NumberFormat ss:Format=\"0000\"/>\n";
          print EXCEL "  </Style>\n";
          #print EXCEL "  <Style ss:ID=\"s75\">\n";
      #print EXCEL "   <Font ss:FontName=\"Calibri\" x:Family=\"Swiss\" ss:Size=\"13\" ss:Color=\"#0070C0\"\n";
      #print EXCEL "   ss:Bold=\"1\"/ ss:WrapText=\"1\">\n";
      #print EXCEL "   <Interior ss:Color=\"#11FF7D\" ss:Pattern=\"Solid\"/>\n";
      #print EXCEL "   <NumberFormat/>\n";
      #print EXCEL "   </Style>\n";
          print EXCEL " </Styles>\n";
        }

#-------------------------------------------------
# subroutine Housekeeping:  general initialization
#-------------------------------------------------

sub Housekeeping
        {
                use Term::ReadKey;                                                              # used to hide password entry
                &gettime();                                             # capture start time
                $today="$year$mon$mday";
                $emminer_starttime="$hour:$min:$sec";
                if ($debug) { print "start $today $emminer_starttime\n";}
                chomp ($emminer_host= `hostname`);      # which host are we on?
                $duptestyr=$year;                               # makes this year the cal dup check year (may be overridden using -y option)

                use Getopt::Long;                                       # needed to accept command line parms
                GetOptions( "d!"        => \$debug,             # "emminer -d" turns on debugging
            "silent!"   => \$silent,                            # "emminer -silent" turns on silent running
            "p!"            => \$portrequest,                   # user wants to explicity set db port for connection
            "y=i"               => \$duptestyr,                         # "emminer -y 2010" forces the Cal by DC duplicate calendar check to be based on 2010
            "old!"              => \$oldterm,                           # "emminer -old" turns off display of new terminology (introduced at v8)
            "tempdir=s" => \$tempdir,                           # user can specify temp directory to be used
            "ip!"               => \$resolveip);                        # "emminer -ip" turns on ip lookup via ping

        if ($resolveip) {$resolveip=1;} else {$resolveip=0;}

        $SIG{'INT'}='User_cntl_c_catcher';   # if user hits Cntl+c invoke subroutine User_cntl_c_catcher
        }

#---------------------------------------------------------------
# subroutine parceagping: pull actual agent ip from ping results
#---------------------------------------------------------------

sub parseagping
        {
          if ($tot_agt_count == 0) {return;}
          $plural="s";
          if ($tot_agt_count == 1) {$plural="";}
          print "                --> $tot_agt_count agent$plural to process\n";
          if ($tot_agt_count == 0) {return;}
          print "                --> pinging each value (use -noip option to stop ping)\n";
          print "                    No $dq"."$Node{$v8term} group$dq lookup, values assumed to be pingable hosts.\n";
          print "                    processing ";
          system ("$oscopy $sqloutfile $sqloutfileb > $bitbucket"); #save the sql results so we can use dosql in while loop

          &Openordie("RESULTSIN :: $sqloutfileb :: < :: Cannot access temp file $sqloutfileb. Check file and directory permissions and ownership.\n");
          &Openordie("SQLOUT :: $sqloutfile :: > :: Cannot access file $sqloutfile. Check file and directory permissions and ownership.\n");

          $agt_count=0;
          $progress=0;                                          # initialised prior to spinner usage
          $tot_Done=0;                                          # initialised prior to spinner usage
          $upd_interval=0;
          if ($tot_agt_count > 0) {$upd_interval=$tot_agt_count/10;}

          while (<RESULTSIN>)
            {
                chomp;
                if ((length($_) < 3) || ($. == $myheaderdashline)) { print SQLOUT ("$_\n"); next;} # blank and header line treatment
                $savedin=$_;
                if ($.== $myheaderline )        # header line treatment including extra headings
                  {
                                        print SQLOUT ("$savedin $sep IP address (ping from $emminer_host)\n");
                                        next;
                  }

                if ($upd_interval > 0)
                   {
                                &Spinit(1,$tot_agt_count);  # (want progress % (0 or 1), how many)
                           }
                        else
                           {
                                    &Spinit(0,0);
                           }

                @colarray1 = split(/$sep/,"$savedin");

                $tname = "";

                if ($#colarray1 > 0)
                  {
                    $tname=$colarray1[1];$tname =~s/ //g;
                    if ($debug) {print "debug pargeagping $tname\n";}
                  }
                if (($tname ne "NULL") && ($tname ne ""))
                  {

                    print SQLOUT "$savedin " . agping($tname) . "\n"; #  ping agent
                  }
                else
                  {
                    print SQLOUT "$savedin $sep  \n";
                  }
                $agt_count++;
                &Spinit(0,0);
            }
          print SQLOUT "$myfooter";
          close SQLOUT;
          close RESULTSIN;
          print " completed\n";

        }  #end of parseagping function

#------------------------
# subroutine parsecalbydc
#------------------------

sub parsecalbydc
        {
          if ($debug) {print "--parsecalbydc with duptestyr $duptestyr\n";}
          $plural="s";
          if ($tot_cal_count == 1) {$plural="";}
          print "                --> $tot_cal_count calendar$plural to process\n";
          print "                    processing ";

          system ("$oscopy $sqloutfile $sqloutfileb > $bitbucket"); #save the sql results so we can use dosql in while loop
          &Openordie("RESULTSIN :: $sqloutfileb :: < :: Cannot access temp file $sqloutfileb. Check file and directory permissions and ownership.\n");
          &Openordie("NEWFL :: $new :: > :: Cannot access temp file $new. Check file and directory permissions and ownership.\n");

          $cal_count=0;
          while (<RESULTSIN>) # extract each calendar for each datacenter in turn and find out where they are used
            {
            chomp;
                if ((length($_) < 3) || ($. == $myheaderdashline)) { print NEWFL ("$_\n"); next;} # blank and header line treatment
                $savedin=$_;
                if ($.== $myheaderline )  # header line treatment including extra headings
                  {
                    print NEWFL ("Data Center Name $sep CALENDAR $sep CalType $sep Monthcal $sep Weekcal $sep Confcal $sep Highest Yr defined $sep desc $sep $duptestyr days 1-183 $sep $duptestyr days 184-366\n");
                    next;
                  }

                @colarray1 = split(/$sep/,"$savedin");
                $tdc=$colarray1[0]; $tdc =~s/ //g;
                $tcal=$colarray1[1];$tcal =~s/ //g;

                if ($dbtype eq "O") {$tcal=~s/\&/\\\&/g;}       # the & character in a calendar name caused the oracle query to hang.  excape is now on.

                if ($upd_interval > 0)
                   {
                                &Spinit(1,$tot_cal_count);  # (want progress % (0 or 1), how many)
                           }
                        else
                           {
                                    &Spinit(0,0);
                           }
                                                                            # get number of jobs which use this calendar in the Month Calendar field
                $sqlquery1 = "select count(*) from DEF_JOB a,DEF_TABLES b where b.DATA_CENTER=$myquote$tdc$myquote and a.DAYS_CAL=$myquote$tcal$myquote and b.TABLE_ID=a.TABLE_ID";

                        dosql(0);
                &Openordie("INDAYS :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                while (<INDAYS>) { if ($. == $myheaderdashline + 1) { chomp;s/ //g; $indayscnt=$_; last; } }  # grab line after header dash, then chomp, remove spaces and assign $indayscnt
                close INDAYS;
                if ($debug) {print "debug INDAYS got $indayscnt as month cal usage for $tcal on $tdc\n";}
                                                                            # get number of jobs which use this calendar in the Weekday Calendar field
                $sqlquery1 = "select count(*) from DEF_JOB a,DEF_TABLES b where b.DATA_CENTER=$myquote$tdc$myquote and a.WEEKS_CAL=$myquote$tcal$myquote and b.TABLE_ID=a.TABLE_ID";

                        dosql(0);
                &Openordie("INWEEKS :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                while (<INWEEKS>) { if ($. == $myheaderdashline + 1) { chomp;s/ //g; $inweekscnt=$_; last; } } # assign $inweekscnt
                close INWEEKS;
                if ($debug) {print "debug INWEEKS got $inweekscnt as month cal usage for $tcal on $tdc\n";}
                                                                            # get number of jobs which use this calendar in the Conf Calendar field
                $sqlquery1 = "select count(*) from DEF_JOB a,DEF_TABLES b where b.DATA_CENTER=$myquote$tdc$myquote and a.CONF_CAL=$myquote$tcal$myquote and b.TABLE_ID=a.TABLE_ID";

                        dosql(0);
                &Openordie("INCONF :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                while (<INCONF>) { if ($. == $myheaderdashline + 1) { chomp;s/ //g; $inconfcnt=$_; last; } }  # assign $inconfcnt
                close INCONF;
                if ($debug) {print "debug INCONF got $inconfcnt as month cal usage for $tcal on $tdc\n";}

                $sqlquery1 = "select YEAR ${mycountq1}Calendar Years$mycountq2,$sep01,DESCRIPTION,$sep02,DAYS_1 ${mycountq1}Days part 1$mycountq2,$sep03,";
                $sqlquery1 .= "DAYS_2 ${mycountq1}Days part 2$mycountq2 from DF_YEARS $nolock ";
                $sqlquery1 .= "where CALENDAR=$myquote$tcal$myquote and DATA_CENTER=$myquote$tdc$myquote order by YEAR DESC";
                dosql(0);
                $calhiyr = "no yr defined"; # default values
                $calname[$cal_count] = $tcal;
                $caldc[$cal_count] = $tdc;
                $caldupno[$cal_count] = 0;
                $caldesc= " ";
                $calval1="no $tdc:$tcal years defined";
                $calval2="no $tdc:$tcal years defined";
                $calval[$cal_count]="no $tdc:$tcal years defined";

                        &Openordie("INYEAR :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                while (<INYEAR>)
                  {
                    if ((length($_) < 3) || ($. <= $myheaderdashline)) { next;} # blank and header line treatment
                    chomp;
                    @colarray2 = split(/$sep/,"$_");
                    $colarray2[0] =~ s/^\s+//;        #remove leading & trailing blanks from year column
                    $colarray2[0] =~ s/\s+$//;
                    if ($. == $myheaderdashline + 1)                                         # get highest year
                      {
                        $calhiyr=$colarray2[0];
                        $caldesc=$colarray2[1];
                      }
                    if ($colarray2[0] eq $duptestyr)       # grab the correct year of cal days
                      {
                        $calval1=$colarray2[2];$calval1 =~ s/^\s+//; $calval1 = substr($calval1, 0, 183);
                        $calval2=$colarray2[3];$calval2 =~ s/^\s+//; $calval2 = substr($calval2, 0, 183);
                        $calval[$cal_count]="$calval1$calval2";                               # array of calendar values to check for duplication.
                        last; # we are only interested in one year
                      }
                  }
                close INYEAR;
                if ($debug) {print "debug INYEAR got $calhiyr as highest year for $tcal on $tdc\n";}

                print NEWFL "$savedin$sep$indayscnt$sep$inweekscnt$sep$inconfcnt$sep$calhiyr$sep$caldesc$sep$calval1$sep$calval2\n"; # dups will need adding on the next pass
                if ($debug) {print "$savedin$sep$indayscnt$sep$inweekscnt$sep$inconfcnt$sep$calhiyr$sep$caldesc$sep$calval1$sep$calval2\n";} # dups will need adding on the next pass
                $cal_count++;
            }
          print NEWFL "$myfooter";
          close NEWFL;
          close RESULTSIN;
          print " completed\n";
          $dupsacrossdc = 0;                                                          # 0 - look for dups per DC. 1 - ignore DC in dup test
          $caltocompare = 0;
          while ($caltocompare < @calval)                                            # check for dups - compare each cal in turn with the rest of the cals
            {
              if ($caldupno[$caltocompare] == 0) {$caldup[$caltocompare] = " in $duptestyr";}
              if ($debug) {print " --- parsecalbydc while   $caltocompare $caldupno[$caltocompare] $caldup[$caltocompare]\n";}
              for (my $i = $caltocompare + 1; $i < @calval; $i++)                    # compare with the rest for dups
                {
                  if ( (($caldc[$i] eq $caldc[$caltocompare]) || $dupsacrossdc)
                    && ($calval[$i] eq $calval[$caltocompare]) )
                    {
                      if ($caldupno[$caltocompare] == 0)
                        {
                          $caldup[$caltocompare] = $calname[$i];
                        }
                      else
                        {
                          $caldup[$caltocompare] = $caldup[$caltocompare] . " " . $calname[$i];
                        }
                      if ($caldupno[$i] == 0)
                        {
                          $caldup[$i] = $calname[$caltocompare];
                        }
                      else
                        {
                          $caldup[$i] = $caldup[$i] . " " . $calname[$caltocompare];
                        }
                      $caldupno[$i]++;
                      $caldupno[$caltocompare]++;
                      if ($debug) {print " --- parsecalbydc do loop $caltocompare $caldupno[$caltocompare] $caldup[$caltocompare]\n";}
                      if ($debug) {print " --- parsecalbydc do loop $i $caldupno[$i] $caldup[$i]\n";}
                    }
                }
              $caltocompare++;                                                        # next cal
            }

          &Openordie("RESULTSIN :: $new :: < :: Cannot access temp file $new. Check file and directory permissions and ownership.\n");
          &Openordie("SQLOUT :: $sqloutfile :: > :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
          $cal_count=0;

          while (<RESULTSIN>) # extract each calendar for each datacenter in turn and find out where they are used
            {
                chomp;
                if ((length($_) < 3) || ($. == $myheaderdashline)) { print SQLOUT ("$_\n"); next;} # blank and header line treatment
                $savedin=$_;
                if ($.== $myheaderline )
                  {
                  print SQLOUT ("$savedin $sep duplicate calendars\n");
                  next;
                  }  # header line treatment including extra headings
                print SQLOUT "$savedin$sep$caldupno[$cal_count] $caldup[$cal_count]\n"; # add dup cal data
                $cal_count++;
            }
          print SQLOUT "$myfooter";
          close SQLOUT;
          close RESULTSIN;

        }  #end of parsecalbydc function

#---------------------
# subroutine parsecmds
#---------------------

sub parsecmds
        {
        # what commands are we interested in?
          if ($debug) {print " --- parsecmds routine\n";}
          if (-f "$cmdstrings")
             {
                # $donothing=1;
                # already have a file containing cmd line strings to be searched for
             }
          else
              {
                print "\nnote: Data Miner is building a default set of strings to scan for within\n";
                print "      job definitions COMMAND LINE.  You can adjust or add to the strings\n";
                print "      scanned for by editing the file $cmdstrings\n\n";

                initial_cmdstrings();  #else give the user a default file
              }

        # load up my hash array which holds the strings to be looked for
          #open (CMDSTRINGS,"<$cmdstrings") || die "Can't access temp file $cmdstrings. Check file and directory permissions and ownership\n";
          &Openordie("CMDSTRINGS :: $cmdstrings :: < :: Cannot access temp file $cmdstrings. Check file and directory permissions and ownership.\n");
          while (<CMDSTRINGS>)
             {
                chomp;
                if (substr($_,0,1) eq "#") {next;}
                $cmdhash{$_}=0;
             }
          close CMDSTRINGS;

        # parse original sqlout file for Control-M commands
          system "$oscopy $sqloutfile $sqloutfileb > $bitbucket";
          &Openordie("TEMPOUT :: $sqloutfile :: > :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
          &Openordie("TEMPIN :: $sqloutfileb :: < :: Cannot access temp file $sqloutfileb. Check file and directory permissions and ownership.\n");

          while (<TEMPIN>)
           {
             chomp;
             if ($. == $myheaderline ) { print TEMPOUT " Count $sep Contains String\n"; next;}    # replace header title line
             if ($. <= $myheaderdashline ) {print TEMPOUT "$_\n"; next;}    # pass thru rest of header
             foreach my $cmd (keys %cmdhash)
               {
                 if (index($_,$cmd) > -1)       # if the commandline contains one of our command list
                    {
                        $cmdhash{$cmd}++;       # then increment its count
                        last;
                    }
               } #end of foreach cmd array
           }
           close TEMPIN;
        # having finished counting each hit of the string across all command lines,
        # lets report them sorted by popularity with a secondary sort by command

           foreach my $cmd (sort { $cmdhash{$b} <=> $cmdhash{$a} or "\L$a" cmp "\L$b"} keys %cmdhash)
               {
                 print TEMPOUT "$cmdhash{$cmd} $sep $cmd \n";
               }
           print TEMPOUT $myfooter;   # print footer
           close TEMPOUT;
        }  #end of parsecmds function

#-------------------------
# subroutine parsejobcount
#-------------------------

sub parsejobcount
        {
          if ($debug) {print "sub parsejobcount\n";}

          system "$oscopy $sqloutfile $report02 > $bitbucket";

          &Openordie("AJFIN :: $report02 :: < :: Cannot access temp file $report02. Check file and directory permissions and ownership.\n");
          &Openordie("NEWFL :: $new :: > :: Cannot access temp file $new. Check file and directory permissions and ownership.\n");

          $olddc="";                    # give this variable an original value of nothing
          $olddt="";
          $highwater=-1;
          $firstsum=1;
          $biggestday=0;
          $overunder = " ";
          $ct = 0;
          $exceededtaskmsg="";
          $daystotal=0;
          $noofdays=0;

        #------- then while processing, each "new date" found indicates most recent download.  process it and skip to next "day change"

          while (<AJFIN>)
            {
            chomp;
            if ($. == $myheaderline ) { print NEWFL " # jobs $sep  date      $sep Data Center           $sep  date     $sep total\n"; next;}    # replace header title line
            if (($. <= $myheaderdashline ) || (length($_) < 3)) {print NEWFL "$_\n"; next;}    # pass thru rest of header and footer
            $_ =~ s/^\s+//;
            $_ =~ s/\s+$//;        #remove leading & trailing blanks
            $dbtbl=substr($_,0,15);
            $mo=substr($_,3,2);
            $yr=substr($_,1,2);
            $day=substr($_,5,2);
            $dt="$mo-$day-20$yr";
            $dc=substr($_,7,3);
            if ($debug) {print "\n\n--- at dt if test, dc=$dc, olddc=$olddc, dt=$dt, olddt=$olddt\n";&Pauser(1719);}
            if (($dc ne $olddc) || ($dt ne $olddt))
               {
                 if ($dt ne $olddt)
                   {
                          if ($debug) {print "--- date changed, was $olddt, now $dt\n";}
                      if ($firstsum)
                        {
                              if ($debug) {print "  -- initial sum\n";}
                          $firstsum = 0;          # we dont have a job count yet
                        }
                      else
                        {
                                $daystotal=$daystotal + $ct;
                                if ($debug) {print "  -- not initial sum daystotal now =$daystotal\n";}
                          $overunder = "";

                          if ($daystotal > 0)
                             {
                                     #print  " -- tot=$daystotal.\n";
                                        print NEWFL "$sep$sep$sep$olddt $sep $daystotal\n";  # print day's total
                                 }
                          if ($debug) {print  "$sep$sep$sep$olddt $sep $ct  $daystotal\n"; }
                          if ($daystotal >= $highwater )                                       # is this day the highest
                            {
                              $highwater = $daystotal;
                              $biggestday=$olddt;
                              $exceededtaskmsg = " ";           # suspect this is no longer needed but leaving in for now (tc aug 2019)
                            }
                          $ct = 0;
                          $daystotal=0;

                        }
                   }
                 if ($debug) {print "  -- post dt ne olddt test\n";}
                 $olddc=$dc;
                 $olddt=$dt;
                 $sqlquery1 = "select count(*),$sep01,$myquote $dt $myquote,$sep02,DATA_CENTER ";
                 $sqlquery1 .= "from $dbtbl,COMM $nolock WHERE COMM.CODE=$myquote$dc$myquote GROUP BY DATA_CENTER";
                 dosql(0);

                         &Openordie("RESULTIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                 while (<RESULTIN>)
                   {
                      if ($. == ($myheaderdashline +1) )               # only expecting 0 or 1 line of data
                        {
                                $noofdays++;
                          chomp;
                          @colarray2 = split(/:-01:/,"$_");
                          print NEWFL "$_\n";                          # print job count for this DC this day
                          if ($debug) {print  " -- dc for the day job count --> $_\n";  }
                          if (index($_,':-01') != -1) { $ct += $colarray2[0]; } # accumulates the day's job count
                        }
                   }
                 close RESULTIN;
               }
            }
          close AJFIN;
                                          # repeat of above code for subtotals after the while loop has finished
          if ($debug) {print "  -- repeating for subtotals, overunder=$overunder\n";}
          $overunder = "";
          $daystotal=$daystotal + $ct;

          if ($daystotal > 0)
             {
                        print NEWFL "$sep$sep$sep$olddt $sep    $daystotal\n";  # print day's total
                 }
          if ($debug) {print   "$sep$sep$sep$olddt $sep  $ct  $daystotal\n";}
          if ($daystotal >= $highwater )                                       # is this day the highest
            {
              $highwater = $daystotal;
              $biggestday=$olddt;
              $exceededtaskmsg = " ";           # suspect this is no longer needed but leaving for now (tc aug 2019)
            }
          print NEWFL "$sep$sep$sep\n";
          print NEWFL "$sep${sep}Over the past $noofdays days, highest # of jobs in a day was$sep$biggestday$sep$highwater\n";
          print NEWFL "$myfooter";
          close NEWFL;
          system "$oscopy $new $sqloutfile > $bitbucket";
        }

#---------------------
# subroutine parsemisc
#---------------------

sub parsemisc($$$)
        {
          my $sql_t = $_[0];
          my $sql_d = $_[1];
          my $sql_q = $_[2];
              $sqlquery1 = $sql_q;
              dosql($sql_t);
              &Openordie("INCONF :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
              while (<INCONF>) { if ($. == $myheaderdashline + 1) { chomp;s/ //g; print NEWFL "$sql_d$sep$_\n"; last; } }  # send desc and 1st line of query tupes to NEWFL
              close INCONF;
              if ($debug) {print "debug MISC got $sql_d as $_\n";}
        }

#---------------------------
# subroutine parsejobglobals
#---------------------------

sub parsejobglobals
  {

  if ($jg_count > 0)
     {
                print "               --> $jg_count global prefixes to process, showing % completion on next line\n";
                print "                  processing";
         }
  else
     {
             print "               --> $jg_count global prefixes\n";
             return;
     }

  $tot_jg_done= -$myheaderdashline; # GPS loop count will be 1 on first line of data

#-------------------------------------------------------------------------------
# for each global prefix, find all Jobs with either IN's, OUT's or DO_COND that are global
#-------------------------------------------------------------------------------
  system "$oscopy $sqloutfile $gps > $bitbucket";
  &Openordie("GPS :: $gps :: < :: Cannot access temp file $gps Check file and directory permissions and ownership.\n");
  &Openordie("NEWFL :: $new :: > :: Cannot access temp file $new. Check file and directory permissions and ownership.\n");

  while (<GPS>) # start of GPS loop
      {
    if (($jg_count > 0) && ($tot_jg_done == int($tot_jg_done/10) * 10)) # show activity by update user on status
           {
             printf ("...%3d%%",$tot_jg_done/$jg_count*100);
           }
        $tot_jg_done++;

        chomp;
        if ($. == $myheaderline ) { print NEWFL " DATA_CENTER $sep SCHED_TABLE $sep Jobname $sep Condition $sep Type    \n"; next;}    # replace header title line
        if ($. <= $myheaderdashline ) {print NEWFL "$_\n"; next;}    # pass thru rest of header
        if ($tot_jg_done > ($jg_count)) {next;}
        $glp=$_;
        $glp =~ s/^\s+//;
        $glp =~ s/\s+$//;        #remove leading & trailing blanks
        if ($debug)
            {
                print "tot_jg_done: $tot_jg_done, GlobalPrefix: $glp\n";
            }
                                              # global ins
        $sqlquery1 = "select DATA_CENTER,$sep01,SCHED_TABLE,$sep02,JOB_NAME ${mycountq1}Jobname $mycountq2,$sep03,";
        $sqlquery1 .= "$mysubstr(CONDITION,1,40) ${mycountq1}Condition $mycountq2,$sep04, $myquote IN $myquote ";
        $sqlquery1 .= "from DEF_LNKI_P a,DEF_JOB b,DEF_TABLES c $nolock where a.JOB_ID=b.JOB_ID and b.TABLE_ID=c.TABLE_ID ";
        $sqlquery1 .= "and a.TABLE_ID=b.TABLE_ID and a.CONDITION like $myquote$glp$mypat$myquote";
        dosql(0);

        &Openordie("RESULTIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
        while (<RESULTIN>)
          {
             if (($. <= $myheaderdashline ) || (length($_) < 3)) {next;}    # skip header lines and blanks
             chomp;
             print NEWFL "$_\n";
          }
        close RESULTIN;

                                              # global outs
        $sqlquery1 = "select DATA_CENTER,$sep01,SCHED_TABLE,$sep02,JOB_NAME ${mycountq1}Jobname $mycountq2,$sep03,";
        $sqlquery1 .= "$mysubstr(CONDITION,1,40) ${mycountq1}Condition $mycountq2,$sep04, $myquote OUT $myquote  ";
        $sqlquery1 .= "from DEF_LNKO_P a,DEF_JOB b,DEF_TABLES c  $nolock where a.JOB_ID=b.JOB_ID and  ";
        $sqlquery1 .= "b.TABLE_ID=c.TABLE_ID and a.TABLE_ID=b.TABLE_ID and a.CONDITION like $myquote$glp$mypat$myquote";
        dosql(0);

        &Openordie("RESULTIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
        while (<RESULTIN>)
          {
             if (($. <= $myheaderdashline ) || (length($_) < 3)) {next;}    # skip header lines and blanks
             chomp;
             print NEWFL "$_\n";
          }
        close RESULTIN;

                                              # global do cond
        $sqlquery1 = "select DATA_CENTER,$sep01,SCHED_TABLE,$sep02,JOB_NAME ${mycountq1}Jobname $mycountq2,$sep03,";
        $sqlquery1 .= "$mysubstr(CONDITION,1,40) ${mycountq1}Condition $mycountq2,$sep04, $myquote DO $myquote  ";
        $sqlquery1 .= "from DEF_DO_COND a,DEF_JOB b,DEF_TABLES c  $nolock where a.JOB_ID=b.JOB_ID and  ";
        $sqlquery1 .= "b.TABLE_ID=c.TABLE_ID and a.TABLE_ID=b.TABLE_ID and a.CONDITION like $myquote$glp$mypat$myquote";
        dosql(0);

        &Openordie("RESULTIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
        while (<RESULTIN>)
          {
             if (($. <= $myheaderdashline ) || (length($_) < 3)) {next;}    # skip header lines and blanks
             chomp;
             print NEWFL "$_\n";
          }
        close RESULTIN;

      }                     # end of while (<GPS>) loop

    close GPS;
    print NEWFL "$myfooter";
    close NEWFL;
    if ($debug)
        {
            print "--- this was in sqloutfile---\n\n\n";
            system ("type $sqloutfile");
            print "\n\n\n\n\nthis is now in it\n";
            system ("type $new");
            print "\n";
        }
    system "$oscopy $new $sqloutfile > $bitbucket";
    print " completed\n";
  }

#------------------------------
# subroutine parseprereq
#------------------------------

sub parseprereq
        {
          if ($debug) {print "-- sub parseprereq\n";}
          system "$oscopy $sqloutfile $report02 > $bitbucket";

          &Openordie("AJFIN :: $report02 :: < :: Cannot access temp file $report02. Check file and directory permissions and ownership.\n");
          &Openordie("NEWFL :: $new :: > :: Cannot access temp file $new. Check file and directory permissions and ownership.\n");

          $olddc="";                    # give this variable an original value of nothing

        #------- then while processing, each "new date" found indicates most recent download.  process it and skip to next "day change"
        # - ********** but change is based on DC change not day!! Is this correct?

          while (<AJFIN>)
            {
            chomp;
            if ($. == $myheaderline ) { print NEWFL " no. of recs $sep ODATE $sep $Archive{$v8term} tablename \n"; next;}    # replace header title line
            if (($. <= $myheaderdashline ) || (length($_) < 3)) {print NEWFL "$_\n"; next;}    # pass thru rest of header and footer
            $_ =~ s/^\s+//;
            $_ =~ s/\s+$//;        #remove leading & trailing blanks
            $dbtbl=substr($_,0,17);
            $dc=substr($_,7,3);
            if ($debug) {print "debug AJFIN $dc $olddc\n";}

            if ($dc ne $olddc)
               {
                 $sqlquery1 = "select count(*),$sep01,ODATE,$sep02,$myquote $dbtbl $myquote ";
                 $sqlquery1 .= "from $dbtbl $nolock GROUP BY ODATE ORDER BY ODATE";
                 dosql(0);

                 &Openordie("RESULTIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                 while (<RESULTIN>)
                   {
                      if (($. <= $myheaderdashline ) || (length($_) < 3)) {next;}    # skip header lines and blanks
                      chomp;
                      print NEWFL "$_\n";
                   }
                 close RESULTIN;
                 $olddc=$dc;
                 $olddt=$dt;
               }
            }
          close AJFIN;
          print NEWFL "$myfooter";
          close NEWFL;
          system "$oscopy $new $sqloutfile > $bitbucket";
        }

#------------------------
# subroutine parseusers
#------------------------

sub parseusers
        {
        # now for each user, also show the groups they belong to
          if ($debug) {print " -- parceusers\n";}
          system "$oscopy $sqloutfile $emusers > $bitbucket";
          &Openordie("USEROUT :: $emusers2 :: > :: Cannot access temp file $emusers2. Check file and directory permissions and ownership.\n");
          close USEROUT;                    # this was opened/closed to empty the file
          &Openordie("USEROUT :: $emusers2 :: >> :: Cannot access temp file $emusers2. Check file and directory permissions and ownership.\n");
          &Openordie("USERIN :: $emusers :: < :: Cannot access temp file $emusers2. Check file and directory permissions and ownership.\n");

          while (<USERIN>)
           {
             chomp;
             if (($. <= $myheaderdashline ) || (length($_) < 3)) {print USEROUT "$_\n"; next;}    # pass thru header and blanks
             print USEROUT ("$_ $sep");
             @userinrec = split(/$sep/,"$_");
             $username=$userinrec[0];
             $username =~ s/^\s+//;
             $username =~ s/\s+$//;        #remove leading & trailing blanks

             $sqlquery1 = "select USERGROUP from USERSGROUPS where USERNAME=$myquote$username$myquote"; # what groups for this user
             dosql(0);

             &Openordie("GROUPINFO :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
             while (<GROUPINFO>)
             {
                if (($. <= $myheaderdashline ) || (length($_) < 3)) {next;}    # skip header lines and blanks
                chomp; s/^\s+//; s/\s+$//;        #remove leading & trailing blanks
                print USEROUT " $_, ";
             }
             close GROUPINFO;
             print USEROUT "\n";

           } #end of while userin
          close USERIN;
          close USEROUT;
          system "$oscopy $emusers2 $sqloutfile > $bitbucket";
          system "$oserase $emusers2 > $bitbucket";
        }  #end of parseusers function

#------------------------------------------------------------------------------
# subroutine dosql, actually invoke needed sql command to run select statements
#------------------------------------------------------------------------------

sub dosql ($)
        {
          my $incquerycnt = $_[0];

          if ($incquerycnt == 1)
            {
              $querycnt++;          # increment the querycnt (for user status of how done they are)
              if ($querycnt < 10)
                 {
                         print "     $querycnt/$querytot       $current_sheet\n";
                 }
              else
                 {
                         print "    $querycnt/$querytot       $current_sheet\n";
                 }
            }
          &Spinit(0,0); # (want progress % (0 or 1), how many)
          if ($debug) {print " --- dosql routine for $current_sheet\n";}
          &Openordie("TEMP :: $sqlinfile :: > :: Cannot access temp file $sqlinfile. Check file and directory permissions and ownership.\n");
          print TEMP "$mysqlpre1";   # sets DB specific sql environment (pagesize, tab off, ...)
          print TEMP "$sqlquery1";   # write the sql sql to TEMP
          print TEMP "$go$myexit";   # add the DB specific 'go' and exit commands
          close TEMP;

          if ($debug)
              {
                   print " --- sql executing " . $sqlcmd . $sqlio . "\n";
                   print " --- dosql_count=$dosql_count, ostype=$ostype, sqlio=$sqlio\n";
                   if ($dbtype eq "O") {$tsqlio=substr($sqlio,1);}
                   if ($dbtype ne "O") {$tsqlio=$sqlio;}
                   print " --- here are the contents of the sql command file $sqlinfile\n";
                   system "$ostype $sqlinfile";
                   print "\n";
              }
           $dosql_count++;

          if (-e $sqloutfile) {$nop=1;} else {system ("echo . > $sqloutfile");}

          system ("$sqlcmd  $sqlio ");  # execute the sql

          my $mydbline_count= 0;
          if (-e $sqloutfile)
              {
                          &Openordie("TEMP :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                          while (<TEMP>)
                            {
                              $mydbline_count++;                                             # count the lines - this is also a test that data exists
                              if (($incquerycnt eq "testdb") && ($debug))
                                 {
                                         print "$mydbline_count: $_";
                                 }
                            }
                          close TEMP;

                          if ($debug)
                             {
                                if (($dbtype eq "O") && ($mydbline_count eq 0) )
                                    {
                                        print " --- sql results in $mydbline_count rows (" . ($mydbline_count) . " rows of tupes)\n";
                                    }
                                else
                                    {
                                        print " --- sql results in $mydbline_count rows (" . ($mydbline_count - $mynontupes) . " rows of tupes)\n";
                                    }
                                system "$ostype $sqlinfile";
                                system "$ostype $sqloutfile";
                             }
                  }
          if (($dbtype eq "O") && ($mydbline_count eq 0) ) { $mydbline_count += $mynontupes; } # Oracle returns no lines if no rows so compensate
          return ($mydbline_count - $mynontupes);  # adjust linecount to exclude header and footer lines

        }

#-------------------------------------------------
# subroutine putsheet, puts data onto excel sheets
#-------------------------------------------------

sub putsheet
   {
                if ($debug) {print " -- in putsheet\n";}
                $snmpscript="";
                $maxcol = -1;
                $maxrow = 0;
                                                                                                                                                 # RESULTIN 1st pass
                &Openordie("RESULTIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");
                while (<RESULTIN>)
                 {
                  if (($. == $myheaderdashline ) || (length($_) < 3)) {next;}    # skip headerdash line and blanks
                  $maxrow++;  # count rows

                  if ($debug) { print " -- incoming sqlresult line: $_";}

                  chomp;
                  @coltmp = split(/$sep/,"$_");
                  if ($debug) {print " --coltmp[0]=@coltmp[0] coltmp[1]=@coltmp[1] coltmp[2]=@coltmp[2] coltmp[3]=@coltmp[3] coltmp[4]=@coltmp[4]\n";      }
                  for (my $i = 0; $i < @coltmp; $i++)               # experimenting with setting width override here
                        {
                        if ($debug) {print "   maxcol=$maxcol, i=$i, sheet_width_override[$i]=$sheet_width_override[$i] \n";}
                        if ($i > $maxcol) # set default column width
                                {
                                        $maxcol = $i; $sheet_width_override[$i] = $defcolw;
                                        if ($debug) {print "   reset 1 sheet_width_override[$i]=$sheet_width_override[$i]       (defcolw=$defcolw)\n";}
                                }
                        $tmp=$coltmp[$i]; $tmp =~ s/^\s+//; $tmp =~ s/\s+$//;        #remove leading & trailing blanks
                        if ( length($tmp) > $sheet_width_override[$i] )
                                {
                                        $sheet_width_override[$i] = length($tmp);
                                        if ($debug) {print "   reset 2 sheet_width_override[$i]=$sheet_width_override[$i]       (defcolw=$defcolw)\n";}                    
                                }
                        }
                 }
                close RESULTIN;

                ### find 10 highest days usage across all data centers and show data by MVS vr Distributed Control-M Server
                # was originally just top 10 highest but adjusted to have this variable to control how many

                $tophowmany=10;    # controls how many highest days information are included in the "job hist by day" tab

                $row=0;
    print EXCEL " <Worksheet ss:Name=\"${current_sheet}\">\n";
    # adjusted the following line to be maxcol + 2 instead of +1.  if I don't, then I cant stuff additional info into a column following the last given column
    #print EXCEL "  <Table ss:ExpandedColumnCount=\"" . (${maxcol} + 1) . "\" ss:ExpandedRowCount=\"${maxrow}\" x:FullColumns=\"1\"\n";
    if (($current_sheet eq "Job Hist by Day") && ($emver gt "6.2"))
        {

                #$maxrow=$maxrow + 15;   # we add the top 10 usage dates to one sheet so must adjust the number of rows excel expects or it will not open the spreadsheet
                $maxrow=$maxrow + $tophowmany + 3 + $tophowmany + 3 + $tophowmany + 3 + 5 + 5;   # we add the top 10 usage dates to one sheet so must adjust the number of rows excel expects or it will not open the spreadsheet
                $maxcol=7;
                }

    print EXCEL "  <Table ss:ExpandedColumnCount=\"" . (${maxcol} + 2) . "\" ss:ExpandedRowCount=\"${maxrow}\" x:FullColumns=\"1\"\n";
    print EXCEL "   x:FullRows=\"1\" ss:DefaultRowHeight=\"15\">\n";
    if ($debug) {print " --- putsheet $current_sheet sheet activated\nwidth before override [$row] ";}
    for (my $i=0; $i <= $maxcol; $i++)
     {
       if ($debug) {print "$sheet_width_override[$i], ";}
       $sheet_width_override[$i] *= 1.25;          # adjust column width if required
       if ($sheet_width_override[$i] > $maxcolw) {$sheet_width_override[$i] = $maxcolw;}          # adjust column width if required
     }
        if ($debug) {print "\n";}
    override_colwidth();                                                                  # override computed column widths
    if ($debug) { print "width after override  [$row] "; }
    for (my $i=0; $i <= $maxcol; $i++)                                                     # look at overridden column widths
     {
       if ($debug) {print "$sheet_width_override[$i], ";}
       print EXCEL "   <Column ss:AutoFitWidth=\"0\" ss:Width=\"". (int($sheet_width_override[$i] * 21) / 4 + 3.75) . "\"/>\n";
     }
    if ($debug) { print "\n"; }

    if ($current_sheet ne "Job Hist by Day") {goto overjhbd;}

    # RESULTSIN 2nd pass.  this used to calculate the 10 highest days usage from available data

    if (($current_sheet eq "Job Hist by Day") && ($emver > "6.2"))
       {


                $tot_mvs_jobsforday=0;

                $tot_mvs_executionsforday=0;
                $tot_ds_jobsforday=0;
    #print "\n\n--- set default tot_ds_jobsforday to zero\n";
                $tot_ds_executionsforday=0;
                $lastdate="";
                $rowno=0;
                @toptendate=();
                @toptenmvsjobs=();
                @toptenmvsexec=();
                @toptendsjobs=();
                @toptendsexec=();
                @toptenjobs=();
                @toptenexecutions=();
                $dods=0;
                $dozos=0;

                # as requested (rp), adding an addition 2 sections which give highest (topten) days jobs for distributed only and zos only
                @dstoptendate=();
                @dstoptenjobs=();
                @dstoptenexec=();

                # as requested (rp), adding an addition 2 sections which give highest (topten) days jobs for distributed only and zos only
                @zostoptendate=();
                @zostoptenjobs=();
                @zostoptenexec=();


                $totjobs=0;
                $totexecutions=0;
                $havemvsdc=0;
                $havedsdc=0;

                        #pen (RESULTSIN,"<$sqloutfile") || die "Can't access RESULTIN file $sqloutfile for high 10 search. Check file and directory permissions and ownership\n";
                        &Openordie("RESULTSIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");

                while (<RESULTSIN>)
                        {
                                if (($. == $myheaderdashline ) || (length($_) < 3)) {next;}    # skip myheaderdashline line and blanks
                                chomp;
                                s/</&lt;/g;                    # the next few line substitute character to the format required for XML
                                s/>/&gt;/g;

                                # these replacements made for spanish characters that sometimes cause Excel not to be able to open the spreadsheet
                                        # Catch Unicode chars
                                        s/\x{DF}/s/g;
                                        s/\x{E0}/a/g;
                                        s/\x{E1}/a/g;
                                        s/\x{E2}/a/g;
                                        s/\x{E3}/a/g;
                                        s/\x{E4}/a/g;
                                        s/\x{E5}/a/g;
                                        s/\x{E6}/ae/g;
                                        s/\x{E7}/c/g;
                                        s/\x{E8}/e/g;
                                        s/\x{E9}/e/g;
                                        s/\x{EA}/e/g;
                                        s/\x{EB}/e/g;
                                        s/\x{EC}/i/g;
                                        s/\x{ED}/i/g;
                                        s/\x{EE}/i/g;
                                        s/\x{EF}/i/g;
                                        s/\x{F0}/ /g;
                                        s/\x{F1}/n/g;
                                        s/\x{F2}/o/g;
                                        s/\x{F3}/o/g;
                                        s/\x{F4}/o/g;
                                        s/\x{F5}/o/g;
                                        s/\x{F6}/o/g;
                                        s/\x{F8}/o/g;
                                        s/\x{F9}/u/g;
                                        s/\x{FA}/u/g;
                                        s/\x{FB}/u/g;
                                        s/\x{FC}/u/g;
                                        s/\x{FD}/y/g;
                                        s/\x{FE}/t/g;
                                        s/\x{FF}/y/g;
                                        s/\x{C0}/A/g;
                                        s/\x{C1}/A/g;
                                        s/\x{C2}/A/g;
                                        s/\x{C3}/A/g;
                                        s/\x{C4}/A/g;
                                        s/\x{C5}/A/g;
                                        s/\x{C6}/AE/g;
                                        s/\x{C7}/C/g;
                                        s/\x{C8}/E/g;
                                        s/\x{C9}/E/g;
                                        s/\x{CA}/E/g;
                                        s/\x{CB}/E/g;
                                        s/\x{CC}/I/g;
                                        s/\x{CD}/I/g;
                                        s/\x{CE}/I/g;
                                        s/\x{CF}/I/g;
                                        s/\x{D0}/ /g;
                                        s/\x{D1}/N/g;
                                        s/\x{D2}/O/g;
                                        s/\x{D3}/O/g;
                                        s/\x{D4}/O/g;
                                        s/\x{D5}/O/g;
                                        s/\x{D6}/O/g;
                                        s/\x{D8}/O/g;
                                        s/\x{D9}/U/g;
                                        s/\x{DA}/U/g;
                                        s/\x{DB}/U/g;
                                        s/\x{DC}/U/g;
                                        s/\x{DD}/U/g;
                                        s/\x{DE}/U/g;
                                        # Original EMMIner catch (minus letters)
                                s/\‡//g;
                                s/\Æ//g;
                                s/\“//g;
                                s/\'/ /g;
                                s/\º/ /g;
                                s/\ª/ /g;
                                        # Catch all else
                                        s/(.)/(ord($1) > 127) ? "" : $1/egs;

                                $dbline = $_;

                                @colarray1 = split(/$sep/,"$dbline");
                                $row++;
                                if ($debug) {print "input: $_\n\n";}
                                #&Pauser(2265);
                                $col=0;
                                @colarray1[0] =~ s/^\s+//;
                    @colarray1[0] =~ s/\s+$//;        #remove leading & trailing blanks
                    @colarray1[0] = substr(@colarray1[0],0,10);

                    @colarray1[2] =~ s/^\s+//;
                    @colarray1[2] =~ s/\s+$//;        #remove leading & trailing blanks

                                    if (@colarray1[0] eq "Date")
                                        {
                                                if ($debug) {print " -- skipping header line\n";}
                                                next;
                                            }           # header line seen and skipped
                                    if ($lastdate eq "")                                                # initial data line record seen and values initialized
                                        {
                                               if (@colarray1[2] eq "MVS")
                                                  {
                                                        $tot_mvs_jobsforday=@colarray1[4];
                                                        $tot_mvs_executionsforday=@colarray1[5];

                                                  }
                                               else
                                                  {
                                                        $tot_ds_jobsforday=@colarray1[4];
                                                        $tot_ds_executionsforday=@colarray1[5];
                                                  }
                                               $lastdate=@colarray1[0];
                                        #       @toptenjobs[0]=$tot_mvs_jobsforday + $tot_ds_jobsforday;
                                    #      @toptendate[0]=$lastdate;
                                    #      @toptenexecutions[0]=$tot_mvs_executionsforday + $tot_ds_executionsforday;
                                               if ($debug)
                                                  {
                                                          print " -- see initial date @colarray1[0].  lastdate=$lastdate.\n";
                                                          print "        type=@colarray1[2]\n";
                                                          print "        totmvsjobsforday=$tot_mvs_jobsforday\n";
                                                          print "        tot_mvs_executionsforday=$tot_mvs_executionsforday\n";
                                                          print "        tot_ds_jobsforday=$tot_ds_jobsforday\n";
                                                          print "        tot_ds_executionsforday=$tot_ds_executionsforday\n\n";
                                                  }
                                               next;
                                       }
                                    if ($lastdate eq @colarray1[0])                             # for same date, keep totaling by platform type (mvs or dist)
                                       {

                                               if (@colarray1[2] eq "MVS")
                                                  {
                                                        $tot_mvs_jobsforday=$tot_mvs_jobsforday+@colarray1[4];
                                                        $tot_mvs_executionsforday=$tot_mvs_executionsforday+@colarray1[5];
                                                  }
                                               else
                                                  {
                                                        $tot_ds_jobsforday=$tot_ds_jobsforday+@colarray1[4];
                                                        $tot_ds_executionsforday=$tot_ds_executionsforday+@colarray1[5];
                                                  }
                                               $lastdate=@colarray1[0];
                                               if ($debug)
                                                  {
                                                          print " -- see last date equal @colarray1[0].  lastdate=$lastdate.\n";
                                                          print "        type=@colarray1[2].  jobs=@colarray1[4]. executions=@colarray1[5]\n";
                                                          print "        totmvsjobsforday=$tot_mvs_jobsforday\n";
                                                          print "        tot_mvs_executionsforday=$tot_mvs_executionsforday\n";
                                                          print "        tot_ds_jobsforday=$tot_ds_jobsforday\n";
                                                          print "        tot_ds_executionsforday=$tot_ds_executionsforday\n\n";
                                                  }
                                               next;
                                       }
                                   if ($lastdate ne @colarray1[0])                              # date changed, test for data importance (top 10 days of usage), reset variables
                                       {

                                               # Ok so the date on this record is different from the last date.  In debug print the held totals for the last date
                                               if ($debug)
                                                        {
                                                                #print "\n -- tot for prev day $lastdate, totmvsjobsforday=$tot_mvs_jobsforday, tot_mvs_executionsforday=$tot_mvs_executionsforday, tot_ds_jobsforday=$tot_ds_jobsforday, tot_ds_executionsforday=$tot_ds_executionsforday\n";
                                                        }
                                               # quick check.  if last days sum is lower than lowest in ten list, skip
                                               $totjobs=$tot_mvs_jobsforday + $tot_ds_jobsforday;
                                               if ($tot_mvs_jobsforday > 0) {$dozos=1;$tophowmanyzos=$tophowmany;}
                                               if ($tot_ds_jobsforday > 0) {$dods=1;$tophowmanyzos=$tophowmany;}

#print " -- new date seen (@colarray1[0]) so finish calculations on lastdate $lastdate, totjobs calculated as $tot_mvs_jobsforday + $tot_ds_jobsforday = $totjobs\n";      
                                               $totexecutions=$tot_mvs_executionsforday + $tot_ds_executionsforday;

                                               if ($debug)
                                                  {
                                                          print " -- see new date equal @colarray1[0].  lastdate=$lastdate.  finishing calculations on last date now\n";
                                                          print "        tot mvs jobs were $tot_mvs_jobsforday, tot ds jobs were $tot_ds_jobsforday\n";
                                                          print "        tot mvs exec were $tot_mvs_executionsforday, tot ds exec were $tot_ds_executionsforday\n";
                                                          print "        totjobs=$tot_mvs_jobsforday + $tot_ds_jobsforday                      ($totjobs)\n";
                                                          print "        totexecutions=$tot_mvs_executionsforday + $tot_ds_executionsforday    ($totexecutions)\n\n";

                                                  }

                                               if ($totjobs > @toptenjobs[$tophowmany-1])
                                                  {
                                                          #if ($debug) {print " -- prev days sum $totjobs, less than smallest of top 10 @toptenjobs[9], skipping\n";}
                                                          #goto rinitvals;


                                               for ($t_ind = 0; $t_ind < $tophowmany; $t_ind++)                    # compare to current highest 10 list
                                                        {
                                                                if ($debug)
                                                                   {
                                                                           #print " --compare topten #$t_ind of @toptendate[$t_ind], @toptenjobs[$t_ind], @toptenexecutions[$t_ind] to prev day\n";
                                                                   }
                                                                if ($totjobs < @toptenjobs[$t_ind])
                                                                        {
                                                                                if ($debug) {print "   topten #$t_ind ok at @toptendate[$t_ind], @toptenjobs[$t_ind], @toptenexecutions[$t_ind]\n";}
                                                                        }

                                                                if (($totjobs > @toptenjobs[$t_ind]) || (@toptenjobs[$t_ind] eq ""))
                                                                        {
                                                                                #for ($p_ind = 9; $p_ind > $t_ind; $p_ind--)
                                                                                for ($p_ind = $tophowmany-1; $p_ind > $t_ind; $p_ind--)
                                                                                                {

                                                                                                        #print " debug -- moving topten $p_ind-1 to $p_ind\n";
                                                                                                        #&Pauser(2382);
                                                                                                        @toptenjobs[$p_ind]=@toptenjobs[$p_ind-1];
                                                                                                @toptendate[$p_ind]=@toptendate[$p_ind-1];
                                                                                                @toptenexecutions[$p_ind]=@toptenexecutions[$p_ind-1];
                                                                                                @toptenmvsjobs[$p_ind]=@toptenmvsjobs[$p_ind-1];
                                                                                                @toptenmvsexec[$p_ind]=@toptenmvsexec[$p_ind-1];
                                                                                                @toptendsjobs[$p_ind]=@toptendsjobs[$p_ind-1];
                                                                                                @toptendsexec[$p_ind]=@toptendsexec[$p_ind-1];
                                                                                                }

                                                                                @toptenjobs[$t_ind]=$totjobs;
                                                                                @toptendate[$t_ind]=$lastdate;
                                                                                @toptenexecutions[$t_ind]=$totexecutions;
                                                                                @toptenmvsjobs[$t_ind]=$tot_mvs_jobsforday;
                                                                                @toptendsjobs[$t_ind]=$tot_ds_jobsforday;
#print " -- just moved value of $tot_ds_jobsforday into toptendsjobs[$t_ind] which is now @toptendsjobs[$t_ind]\n";
                                                                                @toptendsexec[$t_ind]=$tot_ds_executionsforday;
                                                                                @toptenmvsexec[$t_ind]= $tot_mvs_executionsforday;
                                                                                if ($debug) {print "         topten $t_ind  --> @toptendate[$t_ind], @toptenjobs[$t_ind], @toptenexecutions[$t_ind]\n";}
                                                                                #goto rsetvals;
                                                                                goto cdsonly;
                                                                        }
                                                        }
                                                        }

                                      # now check for new entry in the top ten for DS jobs for the day
cdsonly: #$debug=1; print " -- tot_ds_jobsforday=$tot_ds_jobsforday  least in array is @dstoptenjobs[$tophowmany-1]\n";
                                                if ($tot_ds_jobsforday > @dstoptenjobs[$tophowmany-1])
                                                  {
                                                          if ($debug) {print " -- prev days ds sum $tot_ds_jobsforday, > than smallest of top 10 @dstoptenjobs[9], processing\n";}


                                               for ($t_ind = 0; $t_ind < $tophowmany; $t_ind++)                    # compare to current highest 10 list
                                                        {
                                                                if ($debug)
                                                                   {
                                                                           print " --compare dstopten #$t_ind of @dstoptendate[$t_ind], @dstoptenjobs[$t_ind], @dstoptenexec[$t_ind] to prev day\n";
                                                                   }
                                                                if ($tot_ds_jobsforday < @dstoptenjobs[$t_ind])
                                                                        {
                                                                                if ($debug) {print "   dstopten #$t_ind ok at @dstoptendate[$t_ind], @dstoptenjobs[$t_ind], @dstoptenexec[$t_ind]\n";}
                                                                        }

                                                                if (($tot_ds_jobsforday > @dstoptenjobs[$t_ind]) || (@dstoptenjobs[$t_ind] eq ""))
                                                                        {
                                                                                for ($p_ind = $tophowmany-1; $p_ind > $t_ind; $p_ind--)
                                                                                                {

                                                                                                        #print " debug -- moving topten $p_ind-1 to $p_ind\n";
                                                                                                        #&Pauser(2431);
                                                                                                        @dstoptenjobs[$p_ind]=@dstoptenjobs[$p_ind-1];
                                                                                                @dstoptendate[$p_ind]=@dstoptendate[$p_ind-1];
                                                                                                @dstoptenexec[$p_ind]=@dstoptenexec[$p_ind-1];
                                                                                                }

                                                                                @dstoptenjobs[$t_ind]=$tot_ds_jobsforday;
                                                                                @dstoptendate[$t_ind]=$lastdate;
                                                                                @dstoptenexec[$t_ind]=$tot_ds_executionsforday;
                                                                                if ($debug) {print "         dstopten $t_ind  --> @dstoptendate[$t_ind], @dstoptenjobs[$t_ind], @dstoptenexec[$t_ind]\n";}
                                                                                goto czosonly;
                                                                        }
                                                        }
                                                        }

                                      # now check for new entry in the top ten for zos jobs for the day
czosonly:               #print " -- tot_mvs_jobsforday=$tot_mvs_jobsforday  least in array is @zostoptenjobs[$tophowmany-1]     \n";
                                        if ($tot_mvs_jobsforday > @zostoptenjobs[$tophowmany-1])
                                                  {
                                                          if ($debug) {print " -- prev days zos sum $tot_mvs_jobsforday, > than smallest of top 10 @zostoptenjobs[9], processing\n";}


                                               for ($t_ind = 0; $t_ind < $tophowmany; $t_ind++)                    # compare to current highest 10 list
                                                        {
                                                                if ($debug)
                                                                   {
                                                                           print " --compare zostopten #$t_ind of @zostoptendate[$t_ind], @zostoptenjobs[$t_ind], @zostoptenexec[$t_ind] to prev day\n";
                                                                   }
                                                                if ($tot_mvs_jobsforday < @zostoptenjobs[$t_ind])
                                                                        {
                                                                                if ($debug) {print "   zostopten #$t_ind ok at @zostoptendate[$t_ind], @zostoptenjobs[$t_ind], @zostoptenexec[$t_ind]\n";}
                                                                        }

                                                                if (($tot_mvs_jobsforday > @zostoptenjobs[$t_ind]) || (@zostoptenjobs[$t_ind] eq ""))
                                                                        {
                                                                                for ($p_ind = $tophowmany-1; $p_ind > $t_ind; $p_ind--)
                                                                                                {

                                                                                                        #print " debug -- moving topten $p_ind-1 to $p_ind\n";
                                                                                                        #&Pauser(2470);
                                                                                                        @zostoptenjobs[$p_ind]=@zostoptenjobs[$p_ind-1];
                                                                                                @zostoptendate[$p_ind]=@zostoptendate[$p_ind-1];
                                                                                                @zostoptenexec[$p_ind]=@zostoptenexec[$p_ind-1];
                                                                                                }

                                                                                @zostoptenjobs[$t_ind]=$tot_mvs_jobsforday;
                                                                                @zostoptendate[$t_ind]=$lastdate;
                                                                                @zostoptenexec[$t_ind]=$tot_mvs_executionsforday;
                                                                                if ($debug) {print "         zostopten $t_ind  --> @zostoptendate[$t_ind], @zostoptenjobs[$t_ind], @zostoptenexec[$t_ind]\n";}
                                                                                goto rsetvals;
                                                                        }
                                                        }
                                                        }

rsetvals:                                 if ($debug)
                                                                {
                                                                        print "\n\n------------at rsetvals---------------\n";
                                                                        #for ($x_ind = 0; $x_ind < 10; $x_ind++)
                                                                        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                                                                {
                                                                                        print "  #$x_ind  dt=@toptendate[$x_ind], jobs=@toptenjobs[$x_ind], exec=@toptenexecutions[$x_ind]\n";
                                                                                }
                                                                        print "\n\n --- top mvs\n";
                                                                        #for ($x_ind = 0; $x_ind < 10; $x_ind++)
                                                                        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                                                                {
                                                                                        print "  #$x_ind  dt=@zostoptendate[$x_ind], jobs=@zostoptenjobs[$x_ind], exec=@zostoptenexec[$x_ind]\n";
                                                                                }
                                                                        &Pauser(2499);

                                                                        print "\n\n --- top ds\n";
                                                                        #for ($x_ind = 0; $x_ind < 10; $x_ind++)
                                                                        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                                                                {
                                                                                        print "  #$x_ind  dt=@dstoptendate[$x_ind], jobs=@dstoptenjobs[$x_ind], exec=@dstoptenexec[$x_ind]\n";
                                                                                }
                                                                        &Pauser(2507);
                                                                }
rinitvals:
                                               #print " ---debug colarray1[2]=@colarray1[2]\n";
                                               $tot_mvs_jobsforday=0;
                                               $tot_mvs_executionsforday=0;
                                               $tot_ds_jobsforday=0;
                                               $tot_ds_executionsforday=0;
                                               if (@colarray1[2] eq "MVS")
                                                  {
                                                        $havemvsdc=1;
                                                        $tot_mvs_jobsforday=@colarray1[4];
                                                        $tot_mvs_executionsforday=@colarray1[5];
                                                  }
                                               else
                                                  {
                                                        $havedsdc=1;
                                                        $tot_ds_jobsforday=@colarray1[4];
#print " -- at point where initializing tot_ds_jobsforday to $tot_ds_jobsforday\n";
                                                        $tot_ds_executionsforday=@colarray1[5];
                                                  }
                                               $lastdate=@colarray1[0];
                                               if ($debug)
                                                  {
                                                          print " -- resets\n";
                                                          print "        totmvsjobsforday=$tot_mvs_jobsforday\n";
                                                          print "        tot_mvs_executionsforday=$tot_mvs_executionsforday\n";
                                                          print "        tot_ds_jobsforday=$tot_ds_jobsforday\n";
                                                          print "        tot_ds_executionsforday=$tot_ds_executionsforday\n";
                                                          print "        lastdate=$lastdate\n\n";


                                                  }
                                               next;
                                       }



                                }
                        close RESULTSIN;

                        # originally I forgot to process the final record that had been read so here goes

                        $totjobs=$tot_mvs_jobsforday + $tot_ds_jobsforday;
                        $totexecutions=$tot_mvs_executionsforday + $tot_ds_executionsforday;

                        if ($debug)
                                 {
                                        print " -- see EOF.  lastdate=$lastdate.  finishing calculations on last date now\n";
                                        print "        tot mvs jobs were $tot_mvs_jobsforday, tot ds jobs were $tot_ds_jobsforday\n";
                                        print "        tot mvs exec were $tot_mvs_executionsforday, tot ds exec were $tot_ds_executionsforday\n";
                                        print "        totjobs=$tot_mvs_jobsforday + $tot_ds_jobsforday                      ($totjobs)\n";
                                        print "        totexecutions=$tot_mvs_executionsforday + $tot_ds_executionsforday    ($totexecutions)\n\n";                        
                                }

                        if ($totjobs > @toptenjobs[$tophowmany-1])
                                {
                                        if ($debug) {print " -- prev days sum $totjobs, > smallest of top 10 @toptenjobs[$tophowmany-1], processing\n";}

                        for ($t_ind = 0; $t_ind < $tophowmany; $t_ind++)                    # compare to current highest 10 list
                                {
                                        if ($debug)
                                                {
                                                        #print " --compare topten #$t_ind of @toptendate[$t_ind], @toptenjobs[$t_ind], @toptenexecutions[$t_ind] to prev day\n";
                                                }
                                        if ($totjobs < @toptenjobs[$t_ind])
                                                {
                                                        if ($debug) {print "   topten #$t_ind ok at @toptendate[$t_ind], @toptenjobs[$t_ind], @toptenexecutions[$t_ind]\n";}
                                                }

                                        if (($totjobs > @toptenjobs[$t_ind]) || (@toptenjobs[$t_ind] eq ""))
                                                {
                                                        #for ($p_ind = 9; $p_ind > $t_ind; $p_ind--)
                                                        for ($p_ind = $tophowmany-1; $p_ind > $t_ind; $p_ind--)
                                                                {
                                                                        #print " debug -- moving topten $p_ind-1 to $p_ind\n";
                                                                        #&Pauser(2583);
                                                                        @toptenjobs[$p_ind]=@toptenjobs[$p_ind-1];
                                                                @toptendate[$p_ind]=@toptendate[$p_ind-1];
                                                                @toptenexecutions[$p_ind]=@toptenexecutions[$p_ind-1];
                                                                @toptenmvsjobs[$p_ind]=@toptenmvsjobs[$p_ind-1];
                                                                @toptenmvsexec[$p_ind]=@toptenmvsexec[$p_ind-1];
                                                                @toptendsjobs[$p_ind]=@toptendsjobs[$p_ind-1];
                                                                @toptendsexec[$p_ind]=@toptendsexec[$p_ind-1];
                                                                }

                                                @toptenjobs[$t_ind]=$totjobs;
                                                @toptendate[$t_ind]=$lastdate;
                                                @toptenexecutions[$t_ind]=$totexecutions;
                                                @toptenmvsjobs[$t_ind]=$tot_mvs_jobsforday;
                                                @toptendsjobs[$t_ind]=$tot_ds_jobsforday;
#print " -- just moved value of $tot_ds_jobsforday into toptendsjobs[$t_ind] which is now @toptendsjobs[$t_ind]\n";
                                                @toptendsexec[$t_ind]=$tot_ds_executionsforday;
                                                @toptenmvsexec[$t_ind]= $tot_mvs_executionsforday;
                                                if ($debug) {print "         topten $t_ind  --> @toptendate[$t_ind], @toptenjobs[$t_ind], @toptenexecutions[$t_ind]\n";}
                                                                                #goto donit;
                                                                                goto don1;
                                                }
                                }
                        }

don1:   $nop=1;
                                      # now check for new entry in the top ten for DS jobs for the day
c2dsonly:                       if ($tot_ds_jobsforday > @dstoptenjobs[$tophowmany-1])
                                                  {
                                                          if ($debug) {print " -- prev days ds sum $tot_ds_jobsforday, > than smallest of top 10 @dstoptenjobs[9], processing\n";}


                                               for ($t_ind = 0; $t_ind < $tophowmany; $t_ind++)                    # compare to current highest 10 list
                                                        {
                                                                if ($debug)
                                                                   {
                                                                           #print " --compare dstopten #$t_ind of @dstoptendate[$t_ind], @dstoptenjobs[$t_ind], @dstoptenexec[$t_ind] to prev day\n";
                                                                   }
                                                                if ($tot_ds_jobsforday < @dstoptenjobs[$t_ind])
                                                                        {
                                                                                if ($debug) {print "   dstopten #$t_ind ok at @dstoptendate[$t_ind], @dstoptenjobs[$t_ind], @dstoptenexec[$t_ind]\n";}
                                                                        }

                                                                if (($tot_ds_jobsforday > @dstoptenjobs[$t_ind]) || (@dstoptenjobs[$t_ind] eq ""))
                                                                        {
                                                                                for ($p_ind = $tophowmany-1; $p_ind > $t_ind; $p_ind--)
                                                                                                {

                                                                                                        #print " debug -- moving topten $p_ind-1 to $p_ind\n";
                                                                                                        #&Pauser(2632);
                                                                                                        @dstoptenjobs[$p_ind]=@dstoptenjobs[$p_ind-1];
                                                                                                @dstoptendate[$p_ind]=@dstoptendate[$p_ind-1];
                                                                                                @dstoptenexec[$p_ind]=@dstoptenexec[$p_ind-1];
                                                                                                }

                                                                                @dstoptenjobs[$t_ind]=$tot_ds_jobsforday;
                                                                                @dstoptendate[$t_ind]=$lastdate;
                                                                                @dstoptenexec[$t_ind]=$tot_ds_executionsforday;
                                                                                if ($debug) {print "         dstopten $t_ind  --> @dstoptendate[$t_ind], @dstoptenjobs[$t_ind], @dstoptenexec[$t_ind]\n";}
                                                                                goto c2zosonly;
                                                                        }
                                                        }
                                                        }

                                      # now check for new entry in the top ten for zos jobs for the day
c2zosonly:                      if ($tot_mvs_jobsforday > @zostoptenjobs[$tophowmany-1])
                                                  {
                                                          if ($debug) {print " -- prev days zos sum $tot_mvs_jobsforday, > than smallest of top 10 @zostoptenjobs[9], processing\n";}


                                               for ($t_ind = 0; $t_ind < $tophowmany; $t_ind++)                    # compare to current highest 10 list
                                                        {
                                                                if ($debug)
                                                                   {
                                                                           #print " --compare zostopten #$t_ind of @zostoptendate[$t_ind], @zostoptenjobs[$t_ind], @zostoptenexec[$t_ind] to prev day\n";
                                                                   }
                                                                if ($tot_mvs_jobsforday < @zostoptenjobs[$t_ind])
                                                                        {
                                                                                if ($debug) {print "   zostopten #$t_ind ok at @zostoptendate[$t_ind], @zostoptenjobs[$t_ind], @zostoptenexec[$t_ind]\n";}
                                                                        }

                                                                if (($tot_mvs_jobsforday > @zostoptenjobs[$t_ind]) || (@zostoptenjobs[$t_ind] eq ""))
                                                                        {
                                                                                for ($p_ind = $tophowmany-1; $p_ind > $t_ind; $p_ind--)
                                                                                                {

                                                                                                        #print " debug -- moving topten $p_ind-1 to $p_ind\n";
                                                                                                        #&Pauser(2670);
                                                                                                        @zostoptenjobs[$p_ind]=@zostoptenjobs[$p_ind-1];
                                                                                                @zostoptendate[$p_ind]=@zostoptendate[$p_ind-1];
                                                                                                @zostoptenexec[$p_ind]=@zostoptenexec[$p_ind-1];
                                                                                                }

                                                                                @zostoptenjobs[$t_ind]=$tot_mvs_jobsforday;
                                                                                @zostoptendate[$t_ind]=$lastdate;
                                                                                @zostoptenexec[$t_ind]=$tot_mvs_executionsforday;
                                                                                if ($debug) {print "         zostopten $t_ind  --> @zostoptendate[$t_ind], @zostoptenjobs[$t_ind], @zostoptenexec[$t_ind]\n";}
                                                                                goto donit;
                                                                        }
                                                        }
                                                        }

donit:







      if (($debug) && ($current_sheet eq "Job Hist by Day"))
                                                                {
                                                                        print "\n\n------final top ten---------------------\n";
                                                                        #for ($x_ind = 0; $x_ind < 10; $x_ind++)
                                                                        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                                                                {
                                                                                        print "  dt=@toptendate[$x_ind], @toptenjobs[$x_ind], @toptenexecutions[$x_ind]\n";
                                                                                }
                                                                        &Pauser(2701);

                                                                }

                                                                #@toptenjobs[$t_ind]=$totjobs;
                                                        #@toptendate[$t_ind]=$lastdate;
                                                        #@toptenexecutions[$t_ind]=$totexecutions;
                                                        #@toptenmvsjobs[$t_ind]=$tot_mvs_jobsforday;
                                                        #@toptendsjobs[$t_ind]=$tot_ds_jobsforday;
#print " -- just prior to printing out the topten, tot_ds_jobsforday = $tot_ds_jobsforday\n";
                                                        #@toptendsexec[$t_ind]=$tot_ds_executionsforday;
                                                        #@toptenmvsexec[$t_ind]=        $tot_mvs_executionsforday;
    for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                {
                        #print "toptenjobs[$x_ind]=@toptenjobs[$x_ind] in precomify\n";
                @toptenjobs[$x_ind]=Comify(@toptenjobs[$x_ind]);
                #print "    @toptenjobs[$x_ind] in postcomify\n";
                #&Pauser(2718);
                @toptenexecutions[$x_ind]=Comify(@toptenexecutions[$x_ind]);
                @toptenmvsjobs[$x_ind]=Comify(@toptenmvsjobs[$x_ind]);
                @toptendsjobs[$x_ind]=Comify(@toptendsjobs[$x_ind]);
                @toptendsexec[$x_ind]=Comify(@toptendsexec[$x_ind]);
                @toptenmvsexec[$x_ind]= Comify(@toptenmvsexec[$x_ind]);
                }

    $extype = "\"String\"";
#$rowno++;print "--a$rowno\n";
        print EXCEL "   <Row>\n";

        print EXCEL "    <Cell><Data ss:Type=${extype}>top ten days of enterprise wide jobs</Data></Cell>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--b$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "    <Cell><Data ss:Type=${extype}>date</Data></Cell>\n";
        if ($havemvsdc)
                {
                        print EXCEL "    <Cell><Data ss:Type=${extype}>mvs jobs</Data></Cell>\n";
                }
        if ($havemvsdc)

           {
                        print EXCEL "    <Cell><Data ss:Type=${extype}>mvs exec</Data></Cell>\n";
           }
        if ($havedsdc)
                {
                        print EXCEL "    <Cell><Data ss:Type=${extype}>ds jobs</Data></Cell>\n";
                        print EXCEL "    <Cell><Data ss:Type=${extype}>ds exec</Data></Cell>\n";
                }
        #<Cell><Data ss:Type="String">ds exec</Data></Cell>
    #<Cell ss:StyleID="s65"><Data ss:Type="String">highest  jobs</Data></Cell>
        print EXCEL "    <Cell ss:StyleID=\"s65\"><Data ss:Type=${extype}>highest&#10;  jobs</Data></Cell>\n";
        print EXCEL "    <Cell><Data ss:Type=${extype}>highest exec</Data></Cell>\n";
        print EXCEL "   </Row>\n";



        #for ($x_ind = 0; $x_ind < 10; $x_ind++)
        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                {
                                        $extype = "\"String\"";
#$rowno++;print "--c$rowno\n";
                                        print EXCEL "   <Row>\n";
                                        print EXCEL "    <Cell${exstyle}><Data ss:Type=${extype}>@toptendate[$x_ind]</Data></Cell>\n";
                                        $extype = "\"Number\"";
                                        @toptenmvsjobs[$x_ind] =~ s/^\s+//;                    @toptenmvsjobs[$x_ind] =~ s/\s+$//;
                                        @toptenmvsexec[$x_ind] =~ s/^\s+//;                    @toptenmvsexec[$x_ind] =~ s/\s+$//;
                                        @toptendsjobs[$x_ind] =~ s/^\s+//;                    @toptendsjobs[$x_ind] =~ s/\s+$//;
                                        @toptendsexec[$x_ind] =~ s/^\s+//;                    @toptendsexec[$x_ind] =~ s/\s+$//;
                                        @toptenjobs[$x_ind] =~ s/^\s+//;                    @toptenjobs[$x_ind] =~ s/\s+$//;
                                        @toptenexecutions[$x_ind] =~ s/^\s+//;                    @toptenexecutions[$x_ind] =~ s/\s+$//;
                                        if ($havemvsdc)
                                                {
                                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptenmvsjobs[$x_ind]</Data></Cell>\n";
                                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptenmvsexec[$x_ind]</Data></Cell>\n";
                                                }
                                        if ($havedsdc)
                                                {
                                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptendsjobs[$x_ind]</Data></Cell>\n";
                                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptendsexec[$x_ind]</Data></Cell>\n";
                                                }
                                        if ($x_ind != 0)
                                                {
                                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptenjobs[$x_ind]</Data></Cell>\n";
                                                }
                                        else
                                                {
                                                        #print EXCEL "    <Cell ss:StyleID=$dq"."s75$dq><Data ss:Type=${extype}>@toptenjobs[$x_ind]</Data></Cell>\n";
                                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptenjobs[$x_ind]</Data></Cell>\n";
                                                }
                                        #print "--- top10[$x_ind] was @toptenjobs[$x_ind]\n";
                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@toptenexecutions[$x_ind]</Data></Cell>\n";
                                        print EXCEL "   </Row>\n";
                                }
#$rowno++;print "--d$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--e$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--f$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";

        # now for top ten days of zos only
        #if ($dozos)
           #{
            for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                {
                @zostoptenjobs[$x_ind]=Comify(@zostoptenjobs[$x_ind]);
                @zostoptenexec[$x_ind]=Comify(@zostoptenexec[$x_ind]);
                }

    $extype = "\"String\"";
#$rowno++;print "--g$rowno\n";
        if ($havemvsdc && $havedsdc)
                {
                        print EXCEL "   <Row>\n";
                        print EXCEL "    <Cell><Data ss:Type=${extype}>top ten days of zos only jobs</Data></Cell>\n";
                        print EXCEL "   </Row>\n";
#$rowno++;print "--h$rowno\n";
                        print EXCEL "   <Row>\n";
                        print EXCEL "    <Cell><Data ss:Type=${extype}>date</Data></Cell>\n";
                        print EXCEL "    <Cell><Data ss:Type=${extype}>mvs jobs</Data></Cell>\n";
                        print EXCEL "    <Cell><Data ss:Type=${extype}>mvs exec</Data></Cell>\n";
                        print EXCEL "   </Row>\n";

                        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                {
                                        $extype = "\"String\"";
#$rowno++;print "--i$rowno\n";
                                        print EXCEL "   <Row>\n";
                                        print EXCEL "    <Cell${exstyle}><Data ss:Type=${extype}>@zostoptendate[$x_ind]</Data></Cell>\n";
                                        $extype = "\"Number\"";
                                        @zostoptenjobs[$x_ind] =~ s/^\s+//;                    @zostoptenjobs[$x_ind] =~ s/\s+$//;
                                        @zostoptenexec[$x_ind] =~ s/^\s+//;                    @zostoptenexec[$x_ind] =~ s/\s+$//;
                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@zostoptenjobs[$x_ind]</Data></Cell>\n";
                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@zostoptenexec[$x_ind]</Data></Cell>\n";
                                        print EXCEL "   </Row>\n";
                                }
#$rowno++;print "--j$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--k$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--l$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";


        # now for top ten days of ds only
        #if ($dods)
           #{
            for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                {
                @dstoptenjobs[$x_ind]=Comify(@dstoptenjobs[$x_ind]);
                @dstoptenexec[$x_ind]=Comify(@dstoptenexec[$x_ind]);
                }

    $extype = "\"String\"";
#$rowno++;print "--m$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "    <Cell><Data ss:Type=${extype}>top ten days of dist only jobs</Data></Cell>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--n$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "    <Cell><Data ss:Type=${extype}>date</Data></Cell>\n";
        print EXCEL "    <Cell><Data ss:Type=${extype}>ds jobs</Data></Cell>\n";
        print EXCEL "    <Cell><Data ss:Type=${extype}>ds exec</Data></Cell>\n";
        print EXCEL "   </Row>\n";

        for ($x_ind = 0; $x_ind < $tophowmany; $x_ind++)
                                {
                                        $extype = "\"String\"";
#$rowno++;print "--o$rowno\n";
                                        print EXCEL "   <Row>\n";
                                        print EXCEL "    <Cell${exstyle}><Data ss:Type=${extype}>@dstoptendate[$x_ind]</Data></Cell>\n";
                                        $extype = "\"Number\"";
                                        @dstoptenjobs[$x_ind] =~ s/^\s+//;                    @dstoptenjobs[$x_ind] =~ s/\s+$//;
                                        @dstoptenexec[$x_ind] =~ s/^\s+//;                    @dstoptenexec[$x_ind] =~ s/\s+$//;
                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@dstoptenjobs[$x_ind]</Data></Cell>\n";
                                        print EXCEL "    <Cell ss:StyleID=$dq"."s64$dq><Data ss:Type=${extype}>@dstoptenexec[$x_ind]</Data></Cell>\n";
                                        print EXCEL "   </Row>\n";
                                }
#$rowno++;print "--p$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--q$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
#$rowno++;print "--r$rowno\n";
        print EXCEL "   <Row>\n";
        print EXCEL "   </Row>\n";
                }

        }



overjhbd:


$rowno=0;                                                                     # RESULTIN 3nd pass
    #pen (RESULTSIN,"<$sqloutfile") || die "Can't access RESULTIN file $sqloutfile. Check file and directory permissions and ownership\n";
    &Openordie("RESULTSIN :: $sqloutfile :: < :: Cannot access temp file $sqloutfile. Check file and directory permissions and ownership.\n");

    while (<RESULTSIN>)
      {

        if (($. == $myheaderdashline ) || (length($_) < 3)) {next;}    # skip myheaderdashline line and blanks
        chomp;
        s/</&lt;/g;                    # the next few line substitute character to the format required for XML
        s/>/&gt;/g;
#       $OK_CHARS='-a-zA-Z0-9_.@ *';    # A restrictive list, which should be modified to match as appropriate
#       s/[^$OK_CHARS]/_/go;        # this line added so $OK_CHARS is used to sanitize data if required

                # these replacements made for spanish characters that sometimes cause Excel not to be able to open the spreadsheet
                # Catch Unicode chars
                s/\x{DF}/s/g;
                s/\x{E0}/a/g;
                s/\x{E1}/a/g;
                s/\x{E2}/a/g;
                s/\x{E3}/a/g;
                s/\x{E4}/a/g;
                s/\x{E5}/a/g;
                s/\x{E6}/ae/g;
                s/\x{E7}/c/g;
                s/\x{E8}/e/g;
                s/\x{E9}/e/g;
                s/\x{EA}/e/g;
                s/\x{EB}/e/g;
                s/\x{EC}/i/g;
                s/\x{ED}/i/g;
                s/\x{EE}/i/g;
                s/\x{EF}/i/g;
                s/\x{F0}/ /g;
                s/\x{F1}/n/g;
                s/\x{F2}/o/g;
                s/\x{F3}/o/g;
                s/\x{F4}/o/g;
                s/\x{F5}/o/g;
                s/\x{F6}/o/g;
                s/\x{F8}/o/g;
                s/\x{F9}/u/g;
                s/\x{FA}/u/g;
                s/\x{FB}/u/g;
                s/\x{FC}/u/g;
                s/\x{FD}/y/g;
                s/\x{FE}/t/g;
                s/\x{FF}/y/g;
                s/\x{C0}/A/g;
                s/\x{C1}/A/g;
                s/\x{C2}/A/g;
                s/\x{C3}/A/g;
                s/\x{C4}/A/g;
                s/\x{C5}/A/g;
                s/\x{C6}/AE/g;
                s/\x{C7}/C/g;
                s/\x{C8}/E/g;
                s/\x{C9}/E/g;
                s/\x{CA}/E/g;
                s/\x{CB}/E/g;
                s/\x{CC}/I/g;
                s/\x{CD}/I/g;
                s/\x{CE}/I/g;
                s/\x{CF}/I/g;
                s/\x{D0}/ /g;
                s/\x{D1}/N/g;
                s/\x{D2}/O/g;
                s/\x{D3}/O/g;
                s/\x{D4}/O/g;
                s/\x{D5}/O/g;
                s/\x{D6}/O/g;
                s/\x{D8}/O/g;
                s/\x{D9}/U/g;
                s/\x{DA}/U/g;
                s/\x{DB}/U/g;
                s/\x{DC}/U/g;
                s/\x{DD}/U/g;
                s/\x{DE}/U/g;
                # Original EMMIner catch (minus letters)
                s/\‡//g;
                s/\Æ//g;
                s/\“//g;
                s/\'/ /g;
                s/\º/ /g;
                s/\ª/ /g;
                # Catch all else
                s/(.)/(ord($1) > 127) ? "" : $1/egs;

        $dbline = $_;

# do spreadsheet cell output here
#$rowno++;print "--s$rowno\n";
        print EXCEL "   <Row>\n";

        @colarray1 = split(/$sep/,"$dbline");
        $row++;
        if ($debug) {print "[$row]";}
        $col=0;
        foreach my $xx (@colarray1)    # put each member of the array (columns) into individual cells for this row
         {
           $xx =~ s/^\s+//;      #remove leading whitespace
           $xx =~ s/\s+$//;      #remove trailing whitespace
           if ($debug) { print "[$col]=$xx (" . length($xx) . " chr) ";}

           $extype = "\"String\""; $exstyle = "";
           if($xx =~ m/&#10;/)
             {
               $exstyle = " ss:StyleID=\"s63\"";
             }

           # tlc adjustment made here.  On certain periodic calendars which had only numbers for the values, this switched to the "Number" type format.
           #     The files generated with that were failing to open.  Once these were manually adjusted to be just a "String" format like the other
           #     calendar values, it worked.  This change attempting to make all of the "calendar" tabs use the "String" type.
           #if (($xx !~ m/\D/) && ($xx ne ""))                         # if all numeric
           if (($xx !~ m/\D/) && ($xx ne "") && ($current_sheet ne "$Memlib{$v8term}")&& ($current_sheet ne "Cal by DC") && ($current_sheet ne "With Holiday cal") && ($current_sheet ne "With Weekly cal") && ($current_sheet ne "With Monthly cal"))                         # if all numeric
             {
               $extype = "\"Number\"";
               $exstyle = " ss:StyleID=\"s64\"";
               if ((length($xx) == 4) && (substr($xx,0,1) eq "0"))   # stop ODATE and hhmm leading zeros disappearing in excel. E.g. ODATE 0125
                 {
                   $exstyle = " ss:StyleID=\"s65\"";                  # see excelheader() for style definition
                 }
             }
          # test to see if we want to turn this to a bold red font because of rules

#          <Comment
#      ss:Author="BMC Employee"><ss:Data xmlns="http://www.w3.org/TR/REC-html40"><B><Font
#         html:Face="Tahoma" html:Size="8" html:Color="#000000">this is a test comment that is about 60 chars long&#10;</Font></B></ss:Data></Comment>
#
#<Comment
#      ss:Author="BMC Employee"><ss:Data xmlns="http://www.w3.org/TR/REC-html40"><B><Font
#         html:Face="Tahoma" x:Family="Swiss" html:Size="8" html:Color="#000000">BMC Employee:</Font></B><Font
#        html:Face="Tahoma" x:Family="Swiss" html:Size="8" html:Color="#000000">&#10;this is a much longer and more detailed explanation about what I would like to say in this box.  it could be much larger and I could reference a section in one of the manuals.</Font></ss:Data></Comment>
          $comment="";


     #if ($current_sheet eq "Misc")
     #{ print " -- see misc, row=$row, col=$col, xx=${xx}.\n";&Pauser(2984);}

        if (($current_sheet eq "Job Hist by Day") && ($col == 2) && (${xx} eq "UNIX"))  # windows is also designated as UNIX so just set all to distributed
             {
                 if ($debug) {print " -- see platform in Job Hist by Day equal to UNIX, setting to Distributed\n";}
                 ${xx} = "Distributed";
             }
        if (($current_sheet eq "Job Hist by Day") && ($col == 0) && ($emver gt "6.2"))  # remove the time data that follows the date
             {
                 ${xx} = substr(${xx},0,10);
             }

          if (($current_sheet eq "Misc") && ($row == 4) && ($col == 1) && (${xx} gt "0"))
             {
                 if ($debug) {print " -- see cyclic jobs with non-zero $MaxWait{$v8term}, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">Best Practice: </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Routine cyclic tasks do not usually have $MaxWait{$v8term} > 0.&#10;&#10;</Font></ss:Data></Comment>";
             }

          if (($current_sheet eq "Misc") && ($row == 5) && ($col == 1) && (${xx} gt "0"))
             {
                 if ($debug) {print " -- see non cyclic jobs with zero $MaxWait{$v8term}, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">Best Practice: </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;These jobs are removed from AJF after 1 day.  Use 3 if more days if needed.&#10;&#10;</Font></ss:Data></Comment>";
             }

          if (($current_sheet eq "Misc") && ($row == (12 + $bpOff1)) && ($col == 1) && (${xx} gt "0"))
             {
                 if ($debug) {print " -- see inactivated jobs, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">Best Practice: </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;These jobs told not to submit in future&#10;&#10;</Font></ss:Data></Comment>";
             }

          #if (($current_sheet eq "Misc") && ($row == (18 + $bpOff2)) && ($col == 1) && (${xx} ne "v9"))
          #   {
          #       if ($debug) {print " -- see older EM version, changing color\n";}
          #       $number_of_excel_comments++;
          #       $exstyle = " ss:StyleID=\"s27\"";
          #       $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">Best Practice: </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;A newer Version of EM (v800) available Dec 2012.&#10;&#10;</Font></ss:Data></Comment>";
          #   }


          # machine type in the confreg 0=unix, 1=windows, not sure about any others

           if (($current_sheet eq "Components") && ($col == 5))
             {
                 if ($debug) {print " -- Adjust machine type in components accordingly to english like name instead of numeric\n";}
                 if (${xx} eq "0")
                    {
                        if ($debug) {print " -- modify machine type from 0 to Unix\n";}
                        ${xx} = "Unix";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 if (${xx} eq "1")
                    {
                        if ($debug) {print " -- modify machine type from 1 to Windows\n";}
                        ${xx} = "Windows";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 }

          if (($current_sheet eq "Components") && ($col == 0))
             {
                 if ($debug) {print " -- Adjust current state in components accordingly to english like name instead of numeric\n";}
                 if (${xx} eq "0")
                    {
                        if ($debug) {print " -- modify component status from 0 to Down\n";}
                        ${xx} = "Down";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 if (${xx} eq "1")
                    {
                        if ($debug) {print " -- modify component status from 1 to Up\n";}
                        ${xx} = "Up";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 }

          if (($current_sheet eq "Components") && ($col == 1))
             {
                 if ($debug) {print " -- Adjust desired state in components accordingly to english like name instead of numeric\n";}
                 if (${xx} eq "0")
                    {
                        if ($debug) {print " -- modify component status from 0 to Down\n";}
                        ${xx} = "Down";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 if (${xx} eq "1")
                    {
                        if ($debug) {print " -- modify component status from 1 to Up\n";}
                        ${xx} = "Up";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 if (${xx} eq "4")
                    {
                        if ($debug) {print " -- modify component status from 4 to Ignored\n";}
                        ${xx} = "Ignored";
                        $extype = "\"String\"";
                                $exstyle = " ss:StyleID=\"s63\"";
                    }
                 }

          #db type {m for MSSQL 2000, e for MSSQL 2005 or higher, s for SYBASE, p for PostgreSQL, or o for ORACLE}

          if (($current_sheet eq "Misc") && ($row == 16) && ($col == 1))
             {
                 if ($debug) {print " -- Adjust DB type field accordingly to english like name instead of abbreviation\n";}
                 if (${xx} eq "M")
                    {
                        if ($debug) {print " -- modify dbtype from m to mssql 2000\n";}
                        ${xx} = "MSsql 2000";
                    }
                 if (${xx} eq "E")
                    {
                        if ($debug) {print " -- modify dbtype from E to MSsql 2005 or higher\n";}
                        ${xx} = "MSsql";
                    }
                 if (${xx} eq "S")
                    {
                        if ($debug) {print " -- modify dbtype from S to Sybase\n";}
                        ${xx} = "Sybase";
                    }
                 if (${xx} eq "P")
                    {
                        if ($debug) {print " -- modify dbtype from P to PostgreSQL\n";}
                        ${xx} = "PostgreSQL";
                    }
                 if (${xx} eq "O")
                    {
                        if ($debug) {print " -- modify dbtype from O to Oracle\n";}
                        ${xx} = "Oracle";
                    }
             }



           if (($current_sheet eq "$MaxWait{$v8term}") && ($col == 1) && (${xx} eq "99"))
              {
                  if ($debug) {print " -- see $MaxWait{$v8term} = 99, changing color\n";}
                  $number_of_excel_comments++;
                  $exstyle = " ss:StyleID=\"s27\"";
                  $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">Best Practice: </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Few Control-M clients utilize the $MaxWait{$v8term} = 99 feature.                           &#10;It means that these jobs stay in the AJF even after they successfully run.         &#10;Be sure to remove them when needed.            &#10;&#10;&#10;&#10;&#10;                                       &#10;</Font></ss:Data></Comment>";

    #<Cell ss:StyleID="s21"><Data ss:Type="Number">2233</Data></Cell>
    #<Cell ss:StyleID="s27"><Data ss:Type="Number">99</Data></Cell>
              }
                   #Map the type of calendar to numeric output
           if (($current_sheet eq "Cal by DC") && ($row == 1) && ($col == 2))
             {
                 if ($debug) {print " -- Calendar types, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;0=Regular Calendar, 1=Periodic Calendar, 2=Rule Based Calendar.&#10;&#10;</Font></ss:Data></Comment>";
                         }


           if (($current_sheet eq "Cal by DC") && ($row > 0) && ($col == 6) && (${xx} lt "$year"))
             {
                 if ($debug) {print " -- see no current calendar, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Old calendar, nothing for this year or future.&#10;&#10;</Font></ss:Data></Comment>";
             }

           if (($current_sheet eq "Cal by DC") && ($row > 0) && ($col == 6) && (${xx} eq "no yr defined"))
             {
                 if ($debug) {print " -- see no calendar dates, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Empty calendar, no dates for this year or future.&#10;&#10;</Font></ss:Data></Comment>";
             }

           # see if this calendar is used at all
           if (($current_sheet eq "Cal by DC") && ($row > 0) && ($col == 5) && (${xx} eq "0") && ($colarray1[3] eq "0") && ($colarray1[4] eq "0"))
             {
                 if ($debug) {print " -- see calendar never referenced in job definitions, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Calendar not referenced by any job definition.&#10;&#10;</Font></ss:Data></Comment>";
             }

            # see if this high number of alerts in system
           if (($current_sheet eq "Alerts") && ($row > 0) && ($col == 0) && (${xx} > 2000) && (substr($xx,0,1) ne "."))
             {
                 if ($debug) {print " -- see more than 2000 of some class of alerts, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Periodically clean up old alerts.&#10;&#10;</Font></ss:Data></Comment>";
             }

           # see if SNMP traps being sent specifically to a script

           if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "SendAlarmToScript") && ($col == 2) && (${xx} ne ""))
             {
                 $snmpscript=${xx};
             }
           if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "SendAlarmToScript") && ($col == 2) && (${xx} eq "script_name"))
             {
                 $snmpscript="";
             }

           # see if SNMP traps being sent anywhere


           if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "SnmpHost") && ($col == 2) && (${xx} eq "") && ($snmpscript eq ""))
             {
                 if ($debug) {print " -- see no SNMP trap management, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;SNMP Traps generated by Control-M Alerts do not appear to be utilized outside of Control-M.  They could be sent to incident ticket systems or other monitors (or to your own capture scripts).&#10;&#10;</Font></ss:Data></Comment>";
             }
           elsif (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "SnmpHost") && ($col == 2) && (${xx} eq "no_host") && ($snmpscript eq ""))
             {
                 if ($debug) {print " -- see no SNMP trap management, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;SNMP Traps generated by Control-M Alerts do not appear to be utilized outside of Control-M.  They could be sent to incident ticket systems or other monitors (or to your own capture scripts).&#10;&#10;</Font></ss:Data></Comment>";
             }

           if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "HandleAlertsOnRerun") && ($col == 2) && (${xx} eq "0"))
             {
                 if ($debug) {print "-- see not handling alerts on rerun, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;If you set this to 1, job failure alerts will automatically be handled when you rerun the job.&#10;&#10;</Font></ss:Data></Comment>";
             }

          if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "VMVersionsNumberToKeep") && ($col == 2) && (${xx} lt "5"))
             {
                 if ($debug) {print " -- see annotation not on, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;Set this to how many versions of a jobs history to keep (old versions to compare/restore)&#10;&#10;</Font></ss:Data></Comment>";
             }

          if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "MaxOldDay") && ($col == 2) && (${xx} < "5"))
             {
                 if ($debug) {print " -- see only a few archive networks, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;A higher number gives more playback days.  Set MaxOldTotal a few higher than this number.&#10;&#10;</Font></ss:Data></Comment>";
             }

           if (($current_sheet eq "EMPARMS") && ($colarray1[0] eq "UserAuditOn") && ($col == 2) && (${xx} eq "0"))
             {
                 if ($debug) {print " -- see not auditing, changing color\n";}
                 $number_of_excel_comments++;
                 $exstyle = " ss:StyleID=\"s27\"";
                 $comment="<Comment ss:Author=\"Best Practice: \"><ss:Data xmlns=\"http://www.w3.org/TR/REC-html40\"><B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\">  </Font></B><Font html:Face=\"Tahoma\" x:Family=\"Swiss\" html:Size=\"8\" html:Color=\"#000000\" ss:ShowAlways=\"1\">&#10;If you set this to 1, audit information will be captured.&#10;&#10;</Font></ss:Data></Comment>";
             }

           if (($current_sheet eq "Job Hist by Day"))    # for license report only, then don't show execution or group/smart table totals
              {
                        if (($col == 6) || ($col == 7))
                           {
                                   ${xx}="";
                           }
              }
                        # these replacements made for spanish characters that sometimes cause Excel not to be able to open the spreadsheet
                        # Catch Unicode chars
                        $xx=~s/\x{DF}/s/g;
                        $xx=~s/\x{E0}/a/g;
                        $xx=~s/\x{E1}/a/g;
                        $xx=~s/\x{E2}/a/g;
                        $xx=~s/\x{E3}/a/g;
                        $xx=~s/\x{E4}/a/g;
                        $xx=~s/\x{E5}/a/g;
                        $xx=~s/\x{E6}/ae/g;
                        $xx=~s/\x{E7}/c/g;
                        $xx=~s/\x{E8}/e/g;
                        $xx=~s/\x{E9}/e/g;
                        $xx=~s/\x{EA}/e/g;
                        $xx=~s/\x{EB}/e/g;
                        $xx=~s/\x{EC}/i/g;
                        $xx=~s/\x{ED}/i/g;
                        $xx=~s/\x{EE}/i/g;
                        $xx=~s/\x{EF}/i/g;
                        $xx=~s/\x{F0}/ /g;
                        $xx=~s/\x{F1}/n/g;
                        $xx=~s/\x{F2}/o/g;
                        $xx=~s/\x{F3}/o/g;
                        $xx=~s/\x{F4}/o/g;
                        $xx=~s/\x{F5}/o/g;
                        $xx=~s/\x{F6}/o/g;
                        $xx=~s/\x{F8}/o/g;
                        $xx=~s/\x{F9}/u/g;
                        $xx=~s/\x{FA}/u/g;
                        $xx=~s/\x{FB}/u/g;
                        $xx=~s/\x{FC}/u/g;
                        $xx=~s/\x{FD}/y/g;
                        $xx=~s/\x{FE}/t/g;
                        $xx=~s/\x{FF}/y/g;
                        $xx=~s/\x{C0}/A/g;
                        $xx=~s/\x{C1}/A/g;
                        $xx=~s/\x{C2}/A/g;
                        $xx=~s/\x{C3}/A/g;
                        $xx=~s/\x{C4}/A/g;
                        $xx=~s/\x{C5}/A/g;
                        $xx=~s/\x{C6}/AE/g;
                        $xx=~s/\x{C7}/C/g;
                        $xx=~s/\x{C8}/E/g;
                        $xx=~s/\x{C9}/E/g;
                        $xx=~s/\x{CA}/E/g;
                        $xx=~s/\x{CB}/E/g;
                        $xx=~s/\x{CC}/I/g;
                        $xx=~s/\x{CD}/I/g;
                        $xx=~s/\x{CE}/I/g;
                        $xx=~s/\x{CF}/I/g;
                        $xx=~s/\x{D0}/ /g;
                        $xx=~s/\x{D1}/N/g;
                        $xx=~s/\x{D2}/O/g;
                        $xx=~s/\x{D3}/O/g;
                        $xx=~s/\x{D4}/O/g;
                        $xx=~s/\x{D5}/O/g;
                        $xx=~s/\x{D6}/O/g;
                        $xx=~s/\x{D8}/O/g;
                        $xx=~s/\x{D9}/U/g;
                        $xx=~s/\x{DA}/U/g;
                        $xx=~s/\x{DB}/U/g;
                        $xx=~s/\x{DC}/U/g;
                        $xx=~s/\x{DD}/U/g;
                        $xx=~s/\x{DE}/U/g;
            # Original EMMIner catch (minus letters)
                        $xx=~s/\'/ /g;
                        $xx=~s/\‡/ /g;
                        $xx=~s/\Æ/ /g;
                        $xx=~s/\“/ /g;
                        $xx=~s/\'/ /g;
                        $xx=~s/\ª/ /g;
                        $xx=~s/\º/ /g;
                        # Catch all non-ascii over 127
                        $xx=~s/(.)/(ord($1) > 127) ? "" : $1/egs;

            print EXCEL "    <Cell${exstyle}><Data ss:Type=${extype}>${xx}</Data>$comment</Cell>\n";
#            print EXCEL "    <Cell><Data ss:Type=\"String\">${xx}</Data></Cell>\n";
#            print EXCEL "    <Cell><Data ss:Type=\"String\">${xx}</Data></Cell>\n";
           #if ($current_sheet eq "EMPARMS") {print "---emparms col=$col. xx=$xx\n";&Pauser(3263);}
           if (($current_sheet eq "EMPARMS") && ($col == 2))
               {
         #          print "-- see emparms and col=2 current parm name is $colarray1[0]\n";
                   # note what parm this is for
                   #print "--- see col ==2, current name=$colarray1[0]. family=$colarray1[1]. value=$colarray1[2]. xx=$xx\n";&Pauser(3268);
                   $sp_ind=-1;
                   #$tss=scalar(@emsysparmdefval);$tss1=scalar(@emsysparmname);
                   foreach my $pv(@emsysparmname)
                        {
                            $sp_ind++;
                            $defval=$emsysparmdefval[$sp_ind];
                            #print "--defval=$defval.  sp_ind=$sp_ind.  tss=$tss  tss1=$tss1\n";&Pauser(3275);
                            if ($defval eq "") {next;}
        #                    print "-- check array for name=$pv\n";
                            if ($pv eq $colarray1[0])   # found matching parm
                               {
       #                            print "-- see match check value vrs def value $emsysparmdefval[$sp_ind]. vr $xx.\n";
                                   if (($emsysparmcomptype[$sp_ind] ne $colarray1[1]))
                                      {
                                          #print "--- tossed as comptype $emsysparmcomptype[$sp_ind]. ne cell[1] $colarray1[1].\n";&Pauser(3283);
                                          next;
                                      }
                                   if (($defval eq "NULL") && ($xx eq "")) {next;}
                                   if (($defval ne "$xx") && ($defval ne "NULL") && ("$xx" ne ""))    # note non default setting
                                      {
      #                                    print "-- saw match \n";
      #<Cell><Data ss:Type="String">Value</Data></Cell>
                                                                                $exstyle = " ss:StyleID=\"s27\"";

                                          print EXCEL "    <Cell${exstyle}><Data ss:Type=\"String\">        Site modified (default is $defval)</Data></Cell>\n";

                                      }
                                   goto espm;
                               }

                        }
espm:

               }

           $col++;
         }

        print EXCEL "   </Row>\n";
        if ($debug) {print "\n";}
      }
     close RESULTSIN;
  print EXCEL "  </Table>\n";
  print EXCEL "  <WorksheetOptions xmlns=\"urn:schemas-microsoft-com:office:excel\">\n";
  print EXCEL "   <PageSetup>\n";
  print EXCEL "    <Header x:Margin=\"0.3\"/>\n";
  print EXCEL "    <Footer x:Margin=\"0.3\"/>\n";
  print EXCEL "    <PageMargins x:Bottom=\"0.75\" x:Left=\"0.7\" x:Right=\"0.7\" x:Top=\"0.75\"/>\n";
  print EXCEL "   </PageSetup>\n";
  print EXCEL "   <ProtectObjects>False</ProtectObjects>\n";
  print EXCEL "   <ProtectScenarios>False</ProtectScenarios>\n";
  print EXCEL "  </WorksheetOptions>\n";

  print EXCEL " </Worksheet>\n";
    }


#-----------------------------------------------------------------------------------------
# subroutine getconfig.  recapture previously supplied input prompt values to save typeing
#-----------------------------------------------------------------------------------------

sub getconfig
        {
         if ($debug) {print " --- getconfig routine\n";}

         if (-d "$tempdir")     #verify that a temp directory exist or create it
            {
                #its already there if I take the IF
                if ($debug) {print "      temp dir $tempdir exist\n";}
            }
           else
            {
                if ($debug) {print "      making needed temp dir --> $tempdir \n";}
                if ($debug) {print "      $osmkdir -p $tempdir \n";}
                system "$osmkdir -p $tempdir";

            }

         if (-e "$configfile")
            {
                        &Openordie("CONFIG :: $configfile :: < :: Cannot access temp file $configfile Check file and directory permissions and ownership.\n");
            while (<CONFIG>)
                  {
                   chomp;
                   $fld=substr($_,0,5);
                   $val=substr($_,5);
                   if ($fld eq "emvr:") { $emver="$val"; }
                   if ($fld eq "fpre:") { $fpref="$val";  }
                   if ($fld eq "user:") { $emuser="$val";  }
                   if ($fld eq "serv:") { $server="$val";  }
                   if ($fld eq "dbty:") { $dbtype="$val";  }
                   if ($fld eq "rdir:") { $rptdir="$val";  }
                   if ($fld eq "dbpt:") { $dbport="$val";  }
                #    if ($fld eq "pass:")
                #       {
                #       $empass="$val";
                #       if ($dbtype eq "P") { $ENV{PGPASSWORD} = "$empass"; }
                #       }
                   if ($fld eq "dbnm:") { $dbname="$val";  }
                  }
             close CONFIG;
            }
         else
            {
                if ($debug) {print " -- could not find config file $configfile\n";}
                    $emver="";
                    $fpref="";
                    $emuser="";
                    $server="";
                    $dbtype="";
                    $empass="";
                    $dbname="";
                    #$dbport="";
            }
        }

#-----------------------------------
# subroutine getuser_input
#-----------------------------------

sub getuser_input
   {

           #newcheck:
           #            print "    ---> Want to check for newer version of EMminer (y/n default n):";
           #            $ans = <STDIN>;                              #get options
           #            chomp $ans;                                  #remove carrage return
           #            if (lc($ans) eq "y" )
           #               {
           #               &Versioncheck();
           #            }
           #  #printsyntax();

getver:
   print "    ---> Control-M EM version  9, 8, 7, 6.4, 6.3, 6.2, or 6.1.3 ($emver):";
   $ans = <STDIN>;                              #get options
   chomp $ans;                                  #remove carrage return
   if (("$ans" eq "" ) && ("$emver" eq "")) { print " --- must enter a version number ---\n"; goto getver; }
   if ("$ans" ne "" ) { $emver=$ans; }
   if (($emver ne "9") && ($emver ne "8") && ($emver ne"7") && ($emver ne"6.4") && ($emver ne"6.3") && ($emver ne"6.2") && ($emver ne"6.1.3"))
   { print " --- must enter a valid version number ---\n\n"; goto getver; }


getuser:
   print "    ---> Control-M EM userid ($emuser):";
   $ans = <STDIN>;                              #get options
   chomp $ans;                                  #remove carrage return
   if (("$ans" eq "" ) && ("$emuser" eq "")) { print " --- must enter a user ---\n"; goto getuser; }
   if ("$ans" ne "" ) { $emuser=$ans; }

getserver:

   print "    ---> DB Server ($server):";
   $ans = <STDIN>;                              #get options
   chomp $ans;                                  #remove carrage return
   if (("$ans" eq "" ) && ("$server" eq "")) { print " --- must enter a server ---\n"; goto getserver; }
   if ("$ans" ne "" ) { $server=$ans; }

getdbtype:

   #print "    ---> db type {m for MSSQL 2000, e for MSSQL 2005 or higher, s for SYBASE, p for PostgreSQL, or o for ORACLE} ($dbtype):";

   $mdbpointer="   ";
   $edbpointer="   ";
   $sdbpointer="   ";
   $pdbpointer="   ";
   $odbpointer="   ";

   if (lc($dbtype) eq "m") {$mdbpointer="-->";$dbabbrev="m";}
   if (lc($dbtype) eq "e") {$edbpointer="-->";$dbabbrev="e";}
   if (lc($dbtype) eq "s") {$sdbpointer="-->";$dbabbrev="s";}
   if (lc($dbtype) eq "p") {$pdbpointer="-->";$dbabbrev="p";}
   if (lc($dbtype) eq "o") {$odbpointer="-->";$dbabbrev="o";}

   print "    ---> DB type  $mdbpointer m=MSSQL\n";
   print "                  $edbpointer e=MSSQL up to 2005\n";
   print "                  $sdbpointer s=SYBASE\n";
   print "                  $pdbpointer p=PostgreSQL\n";
   print "                  $odbpointer o=ORACLE\n";
   print "                 ($dbabbrev): ";

   $ans = <STDIN>;                              #get options
   chomp $ans;                                  #remove carrage return
   $ans=uc($ans);

   if (("$ans" eq "" ) && ("$dbtype" eq "")) { print " --- must enter a db type ---\n"; goto getdbtype; }
   if ("$ans" ne "" )
      { $dbtype=$ans; }

    if (($dbtype ne "M") && ($dbtype ne "S") && ($dbtype ne "O") && ($dbtype ne "P") && ($dbtype ne "E"))
      {
        print "\n\nsorry but a DB type of $dbtype . is not supported.  Try again\n";
        goto getdbtype;
      }


getdbname:

    if ($dbtype eq "P")
      {
         #print "    ---> em database name - always uppercase ($dbname):";
         $dbname =~ s/^\s+//;
         $dbname =~ s/\s+$//;        #remove leading & trailing blanks
         #if ($dbname eq "")
            #{
                    print "    The name of the EM DB is needed.  Here are some suggestions to try if you do not know\n";
                    print "    for version 9.18+ --> emdb\n";
                    print "                9     --> em900\n";
                    print "                8     --> em800\n";
                    print "                7     --> em700\n";
                    print "                6.4   --> EM640\n";
                    print "                6.3   --> EM630\n";
                    print "                6.2   --> EM620\n";
                    print "                6.1.3 --> EM613\n";
            #}
         print "    ---> EM Database name ($dbname): ";
         $ans = <STDIN>;                            #get options
         chomp $ans;                                #remove carrage return
         $ans =~ s/^\s+//;
         $ans =~ s/\s+$//;        #remove leading & trailing blanks
         #$ans=uc($ans);
         if (("$ans" eq "" ) && ("$dbname" eq "")) { print " --- must enter a dbname ---\n"; goto getdbname; }
         if ("$ans" ne "" ) { $dbname=$ans; }
      }

getdbport:
   #if (($dbport ne "") || ($portrequest))
      #{
             #print "\nNote that specifying the DB port is currently active only for PostgreSQL DB.\n";
             #print "If you have non-default ports for the other DB, email $emailcontact to request.\n";
             if ($dbport eq "") {$displayport="default";}
             else {$displayport="$dbport";}
         print "    ---> DB port ($dq$displayport$dq,  you can specify a number or $dq"."default$dq):";
                $ans = <STDIN>;                              #get options
                chomp $ans;                                  #remove carrage return
                $ans=lc($ans);
                $ans =~ s/^\s+//;
        $ans =~ s/\s+$//;        #remove leading & trailing blanks

        if ("$ans" eq "default") {$dbport="";}
                elsif ("$ans" ne "") { $dbport=$ans; }

          #}



getcomp:
   print "    ---> Your company name or abbreviation - with no spaces ($fpref):";
   $ans = <STDIN>;                              #get options
   chomp $ans;                                  #remove carrage return
   if (("$ans" eq "" ) && ("$fpref" eq "")) { print " --- must enter a company name ---\n"; goto getcomp; }
   if ("$ans" ne "" ) { $fpref=$ans; }


getrptdir:
   if ($rptdir eq "") {$rptdir=$ENV{TEMP};}
   print "    ---> EMminer Report directory ($rptdir):";
   $ans = <STDIN>;                              #get options
   chomp $ans;                                  #remove carrage return
   if ("$ans" ne "" ) { $rptdir=$ans; }

getpswd:

   #print "    ---> em user password ($empass):";
   $hidepass=$empass;
   #$hidepass=~s/./*/g;

   #added new feature to not display the password even on the initial run

   #print "    ---> EM DBO user password ($hidepass): ";
   print "    ---> EM DBO user password: ";
   ReadMode('noecho');
   $ans = ReadLine(0);

   #ans = <STDIN>;                          #get options
   chomp $ans;                                  #remove carrage return
   if ("$ans" ne "" ) { $empass=$ans; }
   if ($dbtype eq "P") { $ENV{PGPASSWORD} = "$empass"; }
   #if (!$debug) {system "$osclear";}                #clear screen to hide entered password
   print "\n\n";




}

#----------------------------
# subroutine cleanup
#----------------------------

sub Cleanup
        {
                #------------------------------------------------
                # close the excel spreadsheet
                #------------------------------------------------

                  print EXCEL "</Workbook>\n";
                  close EXCEL;

                  if (-e "$report02")   {system "$oserase $report02 > $bitbucket";}
                  if (-e "$emusers")    {system "$oserase $emusers > $bitbucket";}
                  if (-e "$emusers2")   {system "$oserase $emusers2 > $bitbucket";}
                  if (-e "$emusers3")   {system "$oserase $emusers3 > $bitbucket";}
                  if (-e "$gps")                {system "$oserase $gps > $bitbucket";}
                  close TEMP;
                  if (-e "$sqloutfile") {system "$oserase $sqloutfile > $bitbucket";}
                  if (-e "$sqloutfileb") {system "$oserase $sqloutfileb ";}
                  if (-e "$sqlinfile")  {system "$oserase $sqlinfile";}
                  if (-e "$new")  {system "$oserase $new";}
                  if (-e "$bitbucket")  {system "$oserase $bitbucket";}

        }

#------------------------------------------------------------------------------------------
#update the config file with current settings (saves ftp info for next time and naming info)
#------------------------------------------------------------------------------------------

sub updconfig
{
      &Openordie("CONFIG :: $configfile :: > :: Cannot access temp file $configfile Check file and directory permissions and ownership.\n");

      print CONFIG "fpre:$fpref\n";
      print CONFIG "user:$emuser\n";
      print CONFIG "serv:$server\n";
      print CONFIG "dbty:$dbtype\n";
      print CONFIG "rdir:$rptdir\n";
      print CONFIG "dbnm:$dbname\n";
      print CONFIG "emvr:$emver\n";
      print CONFIG "dbpt:$dbport\n";
      # print CONFIG "pass:$empass\n";
      close CONFIG;
}

#-----------------------------------
# general routine to get system time
#-----------------------------------

sub gettime
    {
     our ($wday,$yday,$isdst);
     ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
     if (length($mday) < 2) {$mday="0$mday";}
     if (length($min) < 2) {$min="0$min";}
     if (length($sec) < 2) {$sec="0$sec";}
     if (length($hour) < 2) {$hour="0$hour";}
     $year=$year+1900;
     $mon=$mon+1;
     if ($mon < 10) {$mon="0$mon";}
    }

#-----------------------------------
# routine to set any specific column widths to values other than the default which is usually the entire column width from the DB
#-----------------------------------

sub override_colwidth
    {
       if ($debug) {print " --- override_colwidth routine\n";}
       if ($current_sheet eq "SNMP")
           {
       $sheet_width_override[0]=30;                                 # 30 is space for about 30 lower case characters
       $sheet_width_override[1]=60;
           }

       if ($current_sheet eq "Globals")
           {
       $sheet_width_override[0]=18;
           }

       if ($current_sheet eq "$Tbl{$v8term}s per $UserDaily{$v8term}")
           {
       $sheet_width_override[0]=24;
           }

       if ($current_sheet eq "Jobs in EM AJF")
           {
       $sheet_width_override[0]=8;
       $sheet_width_override[1]=12;
       $sheet_width_override[2]=20;
       $sheet_width_override[3]=10;
       $sheet_width_override[4]=10;
       $sheet_width_override[5]=10;
       $sheet_width_override[6]=10;
           }


       if ($current_sheet eq "Cal by DC")
           {
       $sheet_width_override[2]=9;
       $sheet_width_override[3]=9;
       $sheet_width_override[4]=9;
       $sheet_width_override[5]=9;
       $sheet_width_override[6]=19;
       $sheet_width_override[8]=18;
       $sheet_width_override[9]=18;
       $sheet_width_override[10]=40;
           }


       if ($current_sheet eq "Misc")
           {
       $sheet_width_override[0]=50;
           }
    }

#-----------------------------------
# routine to optionally ping the agents
#-----------------------------------

## no critic
# Perl::Critic will ignore any problems it sees with your code

sub agping ($)
{

                $tname=$_[0];
                $tname =~ s/^\s+//;
                $tname =~ s/\s+$//;        #remove leading & trailing blanks
                $tname =~ s/ //g;
                if ($debug) { print " --- agping() $osping $tname\n";}
                &Spinit(0,0);

            #at one site, the following 2 lines of error occurred representing a failed ping.  I am doing ping -c 1.
                #Usage:  ping [-oprv] [-I interval] host [-n count [-m timeout]]
            #ping [-oprv] [-I interval] host packet-size [[-n] count [-m timeout]]

                                if (-e "$tempc")        {system "$oserase $tempc > $bitbucket";}
                #system "$osping $tname > $tempc";
                system "$osping $tname $oserrredirect1 $tempc $oserrredirect2";

crpr:
                $agip = $sep;

                #open (RIPRET,"<$tempc") || die "Can't access temp file $tempc. Check file and directory permissions and ownership\n";
                &Openordie("RIPRET :: $tempc :: < :: Cannot access temp file $tempc Check file and directory permissions and ownership.\n");
                $gotanip=0;
                while (<RIPRET>)
                  {
                          &Spinit(0,0); # (want progress % (0 or 1), how many)
                     chomp;
                     if (length($_) < 3) {next;}
                 if ($debug) { print " --- agping() $_\n";}
                     # commented out following section.  Most sites were just getting the value "pinging" for the ip
                     #if (length ($agip) > length($sep))
                     #  {
                     #
                     #     $agip .= "&#10;$_";
                     #     #if ($debug) {print " -- took 1st:$agip.\n";}
                     #  }
                     #else
                     #  {
                     #     $agip .= "$_";
                     #     #if ($debug) {print " -- took 2nd:$agip.\n";}
                     #  }

                     if ( /Reply from.*:/ ) # windows
                        {
                            $rf_ind=index($_,"Reply from");
                            $colon_ind=index($_,":");
                            $xagip=substr($_,$rf_ind + 11, $colon_ind - $rf_ind - 11);
                            $agip .= "$xagip";
                            $gotanip=1;
                            goto gotagip;
                        }

                     if ( /bytes from.*\(.*\)/ ) # linux eg. redhat
                        {
                            $start_ind=index($_,"(")+1;
                            $end_ind=index($_,")");
                            $xagip=substr($_,$start_ind, $end_ind - $start_ind);
                            $agip .= "$xagip";
                            $gotanip=1;
                            goto gotagip;
                        }

                     $us_ind=index($_,"Usage:");
                     $nr_ind=index($_,"not recognized");
                     if (($us_ind > -1) || ($nr_ind > -1))
                        {
                            $agip .= "Ping Failed, invalid usage or command message recieved (was using $osping $tname)\n";
                            goto agipct;
                        }



#                     $ripi1=index($_,"Reply from ");       # unix will be different
#                     $ripi2=index($_,":");
#                     if ($ripi1 > -1)
#                        {
#                           $agip = $sep . substr($_,$ripi1+11,$ripi2-$ripi1-11);
#                           last;
#                        }
                  }
gotagip:        if (!$gotanip)
                                        {
                                                $agip .= "Not pingable, does not exist, or a $Node{$v8term}group (see definition to id actual agents)";
                                        }
                                #print "agip=$agip.\n";$nop=<STDIN>;
agipct:
                                &Spinit(0,0);
                close RIPRET;
                return $agip;
}
## use critic
# Perl::Critic will report any problems it sees within your code

#-----------------------------------
#   initial_cmdstrings function
#-----------------------------------

sub initial_cmdstrings
{
    if ($debug) {print " --- initial_cmdstrings routine\n";}
    #pen (CMDSTRINGS,">$cmdstrings")|| die "Can't access file $cmdstrings. Check file and directory permissions and ownership\n";
    &Openordie("CMDSTRINGS :: $cmdstrings :: > :: Cannot access temp file $cmdstrings Check file and directory permissions and ownership.\n");
# agent utilities
    print CMDSTRINGS "# any line starting with a # will be ignored in the report so you can\n";
    print CMDSTRINGS "# turn off the reporting of any particular string by putting a # in col 1\n";
    print CMDSTRINGS "#----------------------------------------------------------\n";
    print CMDSTRINGS " su - \n";
    print CMDSTRINGS " FTP \n";
    print CMDSTRINGS " SFTP \n";
    print CMDSTRINGS " SSH \n";
    print CMDSTRINGS "_exit\n";
    #print CMDSTRINGS "_sleep\n";
    print CMDSTRINGS "ag_ping\n";
    print CMDSTRINGS "ag_diag_comm\n";
    #print CMDSTRINGS "ctmag\n";
    print CMDSTRINGS "ctmcontb\n";
    print CMDSTRINGS "ctmcreate\n";
    print CMDSTRINGS "ctmfw\n";
    #print CMDSTRINGS "ctmpwd\n";
    #print CMDSTRINGS "ctmwincfg\n";
    # em utilities
    print CMDSTRINGS "cli\n";
    print CMDSTRINGS "copydefcal\n";
    print CMDSTRINGS "copydefjob\n";
    print CMDSTRINGS "defcal\n";
    print CMDSTRINGS "defjob\n";
    print CMDSTRINGS "defjobconvert\n";
    print CMDSTRINGS "deftable\n";
    print CMDSTRINGS "deldefjob\n";
    print CMDSTRINGS "duplicatedefjob\n";
    print CMDSTRINGS "exportdefcal\n";
    print CMDSTRINGS "exportdefjob\n";
    print CMDSTRINGS "exportdeftable\n";
    print CMDSTRINGS "updatedef\n";
    print CMDSTRINGS "util\n";
    print CMDSTRINGS "check_gtw\n";
    print CMDSTRINGS "ctl\n";
    # control-m server utilities
    print CMDSTRINGS "ctm_agstat\n";
    print CMDSTRINGS "ctm_backup_bcp\n";
    #print CMDSTRINGS "ctm_menu\n";
    print CMDSTRINGS "ctm_restore_bcp\n";
    print CMDSTRINGS "ctmagcln\n";
    print CMDSTRINGS "ctmcalc_date\n";
    #print CMDSTRINGS "ctmcpt\n";
    #print CMDSTRINGS "ctmdbbcl\n";
    print CMDSTRINGS "ctmdbcheck\n";
    #print CMDSTRINGS "ctmdbopt\n";
    print CMDSTRINGS "ctmdbrst\n";
    print CMDSTRINGS "ctmdbspace\n";
    #print CMDSTRINGS "ctmdbtrans\n";
    #print CMDSTRINGS "ctmdbused\n";
    print CMDSTRINGS "ctmdefine\n";
    #print CMDSTRINGS "ctmdiskspace\n";
    #print CMDSTRINGS "ctmcheckmirror\n";
    #print CMDSTRINGS "ctmexdef\n";
    #print CMDSTRINGS "ctmgetcm\n";
    #print CMDSTRINGS "ctmgrpdef\n";
    print CMDSTRINGS "ctmjsa\n";
    #print CMDSTRINGS "ctmkilljob\n";
    print CMDSTRINGS "ctmldnrs\n";
    print CMDSTRINGS "ctmloadset\n";
    print CMDSTRINGS "ctmlog\n";
    print CMDSTRINGS "ctmnodegrp\n";
    #print CMDSTRINGS "ctmordck\n";
    print CMDSTRINGS "ctmorder\n";
    #print CMDSTRINGS "ctmpasswd\n";
    print CMDSTRINGS "ctmping\n";
    print CMDSTRINGS "ctmpsm\n";
    print CMDSTRINGS "ctmrpln\n";
    print CMDSTRINGS "ctmruninf\n";
    print CMDSTRINGS "ctmshout\n";
    #print CMDSTRINGS "ctmshtb\n";
    #print CMDSTRINGS "ctmspdiag\n";
    print CMDSTRINGS "ctmstats\n";
    #print CMDSTRINGS "ctmstvar\n";
    print CMDSTRINGS "ctmsuspend\n";
    #print CMDSTRINGS "ctmsys\n";
    #print CMDSTRINGS "ctmudchk\n";
    print CMDSTRINGS "ctmudlst\n";
    print CMDSTRINGS "ctmudly\n";
    print CMDSTRINGS "ctmvar\n";
    #print CMDSTRINGS "ctmwhy\n";
    #print CMDSTRINGS "dbversion\n";
    print CMDSTRINGS "ecactltb\n";
    print CMDSTRINGS "ecaqrtab\n";
    close CMDSTRINGS;
} #end of initial_cmdstrings function

#-----------------------------------
#    sub testdb
#-----------------------------------

sub testdb
{
  if ($debug) {print " --- testdb routine for dbtype=$dbtype\n";}

  if ($dbtype eq "P")    {$sqlquery1 = "select version()$go";} # make needed PostgreSQL assignments
  elsif ($dbtype eq "O") {$sqlquery1 = "show release$go$myexit";} # make needed Oracle assignments
  else                   {$sqlquery1 = "select \@\@VERSION$go$myexit";} # make needed Sybase/msde/Mssql assignments

  $current_sheet = "";
  print "    ---> Testing DB access using given credentials and command:\n";
  print "    ---> $sqlcmd\"\n\n";
  dosql("testdb");

  if (-e $sqloutfile) {$nop=1;} else {$failed=9;goto cf;}
  &Openordie("TEMP :: $sqloutfile :: < :: Cannot access temp file $sqloutfile Check file and directory permissions and ownership.\n");
  $failed="nofail";     # assume failure (> -1) until the first line is read - PSQL fails this way
  $doesnotexist="exist";
  $baduser="gOpenordie";

  while (<TEMP>)
    {
          print " ---:$_:";
          chomp;
          if ("$_" eq ". ") {$failed=8;last;}
      if ($debug) {print "debug dbtest $_ \n";}
      $failed=index($_,"failed");                      # 1st failure test - MSSQL
      if ($failed == -1) { $failed=index($_,"ERROR");}   # 2nd failure test - Oracle
      $doesnotexist=index($_,"does not exist");            # seen if the postgreSQL DB name is not valid
      $baduser=index($_,"password authentication failed for user");     # see if id was bad, this is the postgreSQL text

      if ($doesnotexist > -1) {last;}
      if ($baduser > -1) {last;}
      if ($failed > -1)           {last;}                  # exit loop if a failure is detected
    }  # end of while TEMP

  close TEMP;
cf:

  if ($failed > -1)
    {

          if ($dbport eq "") {$displayport="default";}
      if (($dbtype eq "M") || ($dbtype eq "S") || ($dbtype eq "E") || ($dbtype eq "O")) # make needed Sybase/msde/Mssql assignments
        {
           print "Error --> DB SQL failed using given DB id, password, server, and port $dq$displayport$dq.\n\n";
        }
      elsif (lc($dbtype) eq "p")    # make needed PostgreSQL assignments
        {
           print "Error --> DB SQL failed using given DB id, password, server, and port $dq$displayport$dq.\n\n";
           print "database: $dbname\n";
        }
      print "      id: $emuser\n";
      $hidepass=$empass;
      $hidepass=~s/./*/g;
      print "    pswd: $hidepass\n";
      print "  server: $server\n";
      if ($dbtype eq "P")
        {
                print "  dbname: $dbname\n";
        }
      print "    port: $displayport\n\n";

      printsyntax();
      &Openordie("TEMP :: $sqloutfile :: < :: Cannot access temp file $sqloutfile Check file and directory permissions and ownership.\n");
      while (<TEMP>)
        {
                 chomp;
                 print "$_\n";
            }
      close TEMP;

      &Cleanup();
          print "exiting with error.\n";
      exit 1;
    }
  elsif ($doesnotexist > -1)
    {

          if ($dbport eq "") {$displayport="default";}
      print "Error --> DB accessed (gOpenordie id/pswd/server/port), but EM DB name $dq$dbname$dq appears to be incorrect.\n\n";
      print "      id: $emuser\n";
      $hidepass=$empass;
      $hidepass=~s/./*/g;
      print "    pswd: $hidepass\n";
      print "  server: $server\n";
          print "  dbname: $dbname\n";
      print "    port: $displayport\n\n";

      printsyntax();

      #pen (TEMP,"<$sqloutfile") || die "Can't access temp file $sqloutfile. Check file and directory permissions and ownership\n";
      &Openordie("TEMP :: $sqloutfile :: < :: Cannot access temp file $sqloutfile Check file and directory permissions and ownership.\n");
      while (<TEMP>) { chomp; print "$_\n"; }
      close TEMP;
          print "exiting with error.\n";
      exit 1;
    }
  elsif ($baduser > -1)
    {

          if ($dbport eq "") {$displayport="default";}
      $hidepass=$empass;
      $hidepass=~s/./*/g;
      print "Error --> DB accessed (gOpenordie server/port), but EM id $dq$emuser$dq or password $dq$hidepass$dq appears to be incorrect.\n\n";
      print "      id: $emuser\n";
      print "    pswd: $hidepass\n";
      print "  server: $server\n";
          print "  dbname: $dbname\n";
      print "    port: $displayport\n\n";

      printsyntax();

      #pen (TEMP,"<$sqloutfile") || die "Can't access temp file $sqloutfile. Check file and directory permissions and ownership\n";
      &Openordie("TEMP :: $sqloutfile :: < :: Cannot access temp file $sqloutfile Check file and directory permissions and ownership.\n");
      while (<TEMP>) { chomp; print "$_\n"; }
      close TEMP;
      exit 1;
    }
  else
    {

      print "   --> DB access verified\n";

      if (!$debug) {system "$osclear";}
    }
}  # end of testdb subroutine


#-------------------------------------------
#    sub initvars
#-----------------------------------

sub initvars
        {
                if ($debug) {print "\n --- initvars routine\n";}

                $v8term="new";                               # display new v8 terminology
                if (($emver lt "8") || $oldterm) {$v8term = "old";}
                %Tbl = ( old => "Tbl", new => "Folder");  # e.g. "Tbls per DC" => "$Tbl{$v8term}s per DC";
                %table = ( old => "table", new => "folder");
                %Group = ( old => "Group", new => "SubApp");
                %Owner = ( old => "Owner", new => "RunAsUser");
                %Author = ( old => "Author", new => "CreatedBy");
                %Node = ( old => "Node", new => "Host");
                %Sysout = ( old => "Sysout", new => "Output");
                %UserDaily = ( old => "User Daily", new => "OrderMethod");
                %Memlib = ( old => "Memlib", new => "FilePath");
                %Memname = ( old => "Memname", new => "FileName");
                %Overlib = ( old => "Overlib", new => "OverridePath");
                %AutoEdit = ( old => "AutoEdit", new => "Variable");
                %Archive = ( old => "Archive", new => "History");
                %MaxWait = ( old => "Max Wait", new => "Retention");

            if ($debug) {print "\n --- using $v8term terminology\n";}
            $ftpversionsite="ftp.bmc.com";              # current anonymous ftp site housing this program
            $excelfile="$rptdir" . "$slash" . "$fpref.emminer.em$emver.rpt.$year.$mon.$mday.$hour.$min.xml";   # name sheet
            $percent="%";
            $defcolw = 9; # The default column width
            $maxcolw = 50; # The maximum column on any sheet
            @spinner=();
            $spinner[0]="\\";
            $spinner[1]="\|";
            $spinner[2]="\/";
            $spinner[3]="-";
            $spinner_index=0;

            if ($emver lt "7")
                    {
                                $emdir=$ENV{'NDS_ECS_ROOT'};            # find the EM directory
                    }
            else
                    {
                                $emdir=$ENV{'EM_HOME'};            # find the EM directory
                    }

            if ($emdir eq "")
                    {
                                $emdir=$ENV{'CONTROLM_SERVER'};            # if full install then use CONTROLM_SERVER home
                                if ($emdir ne "") { $emdir .= "${slash}..${slash}ctm_em"; }
                    }

                @emsysparmname=();
                @emsysparmrefresh=();
                @emsysparmdefval=();
                @emsysparmvalidval=();
                @emsysparmdesc=();
                @emsysparmcomptype=();
                $emplastline="";
                if ($emdir ne "")
                        {
                                $sysparmfile="$emdir${slash}data${slash}systemParametersDesc.xml"; # only exists on EM server

                         # if this file exist, grab it's contents so we can use it during the build of the EMPARMS tab of the spreadsheet
                         if (-e $sysparmfile)
                           {
                                 if ($debug) {print "      sysparmfile=$sysparmfile\n";}
                                 &Openordie("temsysp :: $sysparmfile :: < :: Cannot access temp file $sysparmfile Check file and directory permissions and ownership.\n");
                                 $nameparmtally=-1;
                                 while (<temsysp>)
                                        {
                                                if (index($_,"PARAM>") > -1) {next;}     # don't need the start and end param lines
                                                if (length($_) < 10) {next;}            # line to short to have useful data so skip it
                                                chomp;
                                                if ($emplastline eq "$_") {next;}       # there were some dup lines in the systemParametersDesc.xml file
                                                $emplastline="$_";
                                                $type_ind=index($_,"<TYPE>");
                                                $endtype_ind=index($_,"</TYPE>");
                                                $name_ind=index($_,"<NAME>");
                                                $comptype_ind=index($_,"<COMP_TYPE>");
                                                $endcomptype_ind=index($_,"</COMP_TYPE>");
                                                $endname_ind=index($_,"</NAME>");
                                                $refresh_ind=index($_,"<REFRESH_TYPE>");
                                                $endrefresh_ind=index($_,"</REFRESH_TYPE>");
                                                $desc_ind=index($_,"<DESCRIPTION>");
                                                $enddesc_ind=index($_,"</DESCRIPTION>");
                                                $def_ind=index($_,"<DEF_VALUE>");
                                                $enddef_ind=index($_,"</DEF_VALUE>");
                                                $valid_ind=index($_,"<VALID_VALUES>");
                                                $endvalid_ind=index($_,"</VALID_VALUES>");
                                                #if ($debug) {print " -- sysparm input:$_\n";}
                                                if ($type_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$type_ind + 6,$endtype_ind - $type_ind - 6);
                                                                push(@emsysparmtype,"$pvalue");
                                                                #if ($debug) {print "   type=$pvalue.\n";}
                                                                next;
                                                   }
                                                if ($name_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$name_ind + 6,$endname_ind - $name_ind - 6);
                                                                push(@emsysparmname,"$pvalue");
                                                                $nameparmtally++;
                                                                $emsysparmcomptype[$nameparmtally]="*";
                                                                #$ttt1=scalar(@emsysparmname);print " --- scalar defval=$ttt1\n";
                                                                #if ($debug) {print "   name=$pvalue.\n";}
                                                                next;
                                                   }
                                                if ($comptype_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$comptype_ind + 11,$endcomptype_ind - $comptype_ind - 11);
                                                                $emsysparmcomptype[$nameparmtally]=$pvalue;
                                                                #if ($debug) {print "   comp_type=$pvalue.\n";}
                                                                next;
                                                   }
                                                if ($refresh_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$refresh_ind + 14,$endrefresh_ind - $refresh_ind - 14);
                                                                push(@emsysparmrefresh,"$pvalue");
                                                                #if ($debug) {print "   refresh=$pvalue.\n";}
                                                                next;
                                                   }
                                                if ($desc_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$desc_ind + 13,$enddesc_ind - $desc_ind - 13);
                                                                push(@emsysparmdesc,"$pvalue");
                                                                #if ($debug) {print "   desc=$pvalue.\n";}
                                                                next;
                                                   }
                                                if ($def_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$def_ind + 11,$enddef_ind - $def_ind - 11);
                                                                #if ($pvalue eq "") {$pvalue="NULL";}
                                                                push(@emsysparmdefval,"$pvalue");
                                                                #$ttt=scalar(@emsysparmdefval);print " --- scalar defval=$ttt\n";
                                                                #if ($debug) {print "   def=$pvalue.\n";}
                                                                next;
                                                        }
                                                if ($valid_ind > -1)
                                                   {
                                                                $pvalue=substr($_,$valid_ind + 14,$endvalid_ind - $valid_ind - 14);
                                                                push(@emsysparmvalidval,"$pvalue");
                                                                #if ($debug) {print "   valid=$pvalue.\n";}
                                                                next;
                                                        }
                                        }
                                 close "temsysp";
                            }
                    }

                $number_of_excel_comments=0;

                if ($debug)
                        {
                                print "      sqlcmd=$sqlcmd\n";
                                print "      bitbucket=$bitbucket\n";
                                print "      configfile=$configfile\n";
                                print "      tempdir=$tempdir\n";
                                print "      oseditor=$oseditor\n";
                                print "\n";
                        }
        }

#---------------------------------------
# subroutine initdbclient
#---------------------------------------
# only PostgrSQL at this time
sub initdbclient
{
  $querycnt=0;                                  # incremented in dosql(1)
  $dosql_count=0;
  $nolock=" with (NOLOCK)";         # have set this to null for now
  $nolock="";
  if (lc($dbtype) eq  "m") {$dbtypename="MSsql";}
  elsif (lc($dbtype) eq  "e") {$dbtypename="MSsql up to 2005";}
  elsif (lc($dbtype) eq  "s") {$dbtypename="Sybase";}
  elsif (lc($dbtype) eq  "p") {$dbtypename="PostgreSQL";}
  elsif (lc($dbtype) eq  "o") {$dbtypename="Oracle";}

  if (($dbtype eq "M") || ($dbtype eq "S") || ($dbtype eq "E"))     # make needed Sybase/msde/Mssql assignments
    {
      $sqlcmd = "sqlcmd";
      if ($dbtype eq "E") { $sqlcmd ="osql"; }                  # adjust for msde support of osql
          $origsqlcmd=$sqlcmd;
          if ($dbport ne "")
                  {
					# Original line $sqlcmd = $origsqlcmd . " -w 9000 -N -U $emuser -P $empass -S \"$server,$dbport\" ";
                    $sqlcmd = $origsqlcmd . " -w 9000 -U $emuser -P $empass -S \"$server,$dbport\" ";
                         print "Since a non-default port was requested, attempting connection with $origsqlcmd -w 9000 -n -Uxxxxxxx -Pxxxxxx -S$server:$dbport\n";
                     print "Paused, hit enter to continue...";
                     $nop=<STDIN>;
                     print "\n";
                  }
          else
              {
				  # Original line $sqlcmd = $origsqlcmd . " -w 9000 -N -U $emuser -P $empass -S $server ";
                $sqlcmd = $origsqlcmd . " -w 9000 -U $emuser -P $empass -S $server ";                 
				}

      $sqlio = "-i $sqlinfile -o $sqloutfile";
      #$calio = "-i $calsql -o $calsqlout";
      $go=" \ngo\n";
      $myexit="exit\n";
      $mysubstr="substring";
      $myquote='"';
      $mycountq1=" '";
      $mycountq2="'";
      # $myprint="print";
      $mysqlpre1="set nocount on$go";
      $mypat="%";
      $myheaderline = 1;
      $myheaderdashline = 2;
      $mynontupes = 3;                                  # tupes = data
      $mypreheader = "";                                # header including zero or more \n if required during cloning of $sqloutfile
      $myfooter = "\n";                                 # footer including zero or more \n if required during cloning of $sqloutfile
    }
  elsif ($dbtype eq "P")
    {
      if ($ENV{PGCLIENTENCODING} eq "")
          {
            $ENV{PGCLIENTENCODING} = "SQL_ASCII";       # psql 9.1 or above client uses this. Best first guess as it is set to SQL_ASCII on v9 EM server.
            if ($debug) { print "set PGCLIENTENCODING=SQL_ASCII\n"; }
          }
      &testdbclient();                                  # this routine verifies access to the db
      $dbportinfo="";
      if ($dbport ne "") {$dbportinfo="-p $dbport";}

      $sqlcmd = "$dq$ospsql$dq -U $emuser -h $server -d $dbname -q -X $dbportinfo";
      #$debugsqlcmd = "$dq$ospsql$dq -U $emuser -h $server -d $dbname -q -X $dbportinfo";
      $sqlio = "-f $sqlinfile -o $sqloutfile";
      #$calio = "-f $calsql -o $calsqlout";
      $go=";\n";
      #$myexit="\\q\n";
      $myexit="\\q";
      $mysubstr="substr";
      $myquote="'";
      $mycountq1=' as "';
      $mycountq2='"';
      $mysqlpre1="\\pset border 0\n\\pset footer\n";
      $mypat="%";
      $myheaderline = 1;
      $myheaderdashline = 2;
      $mynontupes = 3;
      $mypreheader = "";
      $myfooter = "\n";
    }
  else                      # make needed Oracle assignments
    {
      $sqlcmd = "sqlplus -L -S $emuser/$empass\@$server ";      # -L for single logon attempt
      $sqlio = "\@$sqlinfile > $sqloutfile";
      #$calio = "\@$calsql > $calsqlout";
      $go=";\n";
      $myexit="exit\n";
      $mysubstr="substr";
      $myquote="'";
      $mycountq1=' as "';
      $mycountq2='"';
      # $myprint="prompt";
      $mysqlpre1="set pagesize 9999${go}set linesize 9000${go}set tab off${go}set feedback off${go}set escape on${go}";
      $mypat="%";
      $myheaderline = 2;
      $myheaderdashline = 3;
      $mynontupes = 3;
      $mypreheader = "\n";
      $myfooter = "";
    }

  $sep=":-..:";                         # this is the "separator" value between sql columns (helps with parsing)
  $sep01="${myquote}:".'-01'.":$myquote ${mycountq1}:".'-01'.":$mycountq2"; # this gives us $sep as we want to use it in a SELECT
  $sep02="${myquote}:".'-02'.":$myquote ${mycountq1}:".'-02'.":$mycountq2"; # we need lots of these because Sybase will not allow multiple columns of the same name
  $sep03="${myquote}:".'-03'.":$myquote ${mycountq1}:".'-03'.":$mycountq2";
  $sep04="${myquote}:".'-04'.":$myquote ${mycountq1}:".'-04'.":$mycountq2";
  $sep05="${myquote}:".'-05'.":$myquote ${mycountq1}:".'-05'.":$mycountq2";
  $sep06="${myquote}:".'-06'.":$myquote ${mycountq1}:".'-06'.":$mycountq2";
  $sep07="${myquote}:".'-07'.":$myquote ${mycountq1}:".'-07'.":$mycountq2";
  $sep08="${myquote}:".'-08'.":$myquote ${mycountq1}:".'-08'.":$mycountq2";
  $sep09="${myquote}:".'-09'.":$myquote ${mycountq1}:".'-09'.":$mycountq2";
  $sep10="${myquote}:".'-10'.":$myquote ${mycountq1}:".'-10'.":$mycountq2";
}


#---------------------------------------
# subroutine testdbclient
#---------------------------------------
# only PostgrSQL at this time
sub testdbclient
{
  if ($dbtype eq "P")
    {
                # verity that psql will resolve from path or look around for it
                # 1st assume path
                system "$ospsql $ospsqlhelp $oserrredirect1 $bitbucket $oserrredirect2";

                $psqlfound = 0;
             #&Openordie("results :: $bitbucket :: < :: Error:  could not access the $bitbucket for PSQL confirmation");
             #pen ("results","<$bitbucket") || die "Can't access temp test file $bitbucket during psql confirmation.\n";
             &Openordie("results :: $bitbucket :: < :: Cannot access temp file $bitbucket Check file and directory permissions and ownership.\n");

             if ($debug)
                {
                                    print " --- Trying to determine if this machine found psql.exe when executed\n";
                        print " --- Executing  psql and scanning response for valid execution\n";
                }

             while (<results>)
                {
                    $t1=lc($_);
                    if ($debug) { print "  --- $_ \n"; }
                    $i1=index($t1,"the postgresql interactive terminal"); # check after converting to lower case
                    if ($i1 > -1)
                    {
                        $psqlfound = 1;
                        last; # found so exit loop
                    }
                }

                # 2nd look around if required
            if ($psqlfound == 0)
                {
                        if ($debug)
                            {
                                print "\n --- Scan of each line of output returned from psql -? did not see   the postgresql interactive terminal\n";
                                print "\nPostgreSQL (psql.exe) does not appear to be in your current path.  Searching for it in likely places ...\n";
                            }

                        $osaltdrive = "D:"; # a likely alternative to the current drive
                        $emclient = "default";

                        @cmd2try = (
                                "$emdir${slash}pgsql${slash}bin${slash}$ospsql",  # try emdir
                                "$emdir${slash}pgsql32${slash}bin${slash}$ospsql",
                                "\\program files\\bmc software\\Control-M EM ${emver}.0.00\\${emclient}\\pgsql\\bin\\$ospsql", # how about a few standard install locations
                                "\\program files\\bmc software\\Control-M EM ${emver}.0.00\\${emclient}\\pgsql32\\bin\\$ospsql",
                                "${osaltdrive}\\program files\\bmc software\\Control-M EM ${emver}.0.00\\${emclient}\\pgsql\\bin\\$ospsql",
                                "${osaltdrive}\\program files\\bmc software\\Control-M EM ${emver}.0.00\\${emclient}\\pgsql32\\bin\\$ospsql",
                                );
                        foreach my $ptest (@cmd2try)
                                {
                                  if ($debug)
                                    {
                                      print " -- searching for psql at $ptest\n";
                                    }
                                  if (-e "$ptest")
                                   {
                                      $psqlfound = 1;
                                      $ospsql="$ptest";
                                      if ($debug) { print " -- found it and set psql=$ospsql\n\n"; }                                                                       
                                      last; # exit loop when found
                                   }
                                  else
                                   {
                                      if ($debug) {print " -- did not see $ptest \n";}
                                   }
                                }
                }
            if ($psqlfound == 0) # not found so tidy up and exit
                {
                        print "\nCannot find psql.exe on your machine (in Path or other common directories). Please install, add to 'path' or run emminer in psql directory and retry.  Exiting.\n";
                        &Cleanup;
                        exit 1302;
                }
    }
}

#---------------------------------------
# subroutine wrapup
#---------------------------------------

sub wrapup
{
   if ($debug) {print " ---  wrapup routine\n";}
   print "  \n\n   --> Your EM report is $excelfile\n";
   print "       You can use Excel (or some Browsers) to open this Excel Spreadsheet\n";
   if ($number_of_excel_comments > 0)
      {
          if ($number_of_excel_comments > 1) {$plurals="s are";}
          else {$plurals=" is";}
          print "\nNote: $number_of_excel_comments Comment$plurals denoted within cells of this report for your best practices review\n";
      }
}


#----------------------------
# subroutine printsyntax
#----------------------------

sub printsyntax
        {
           print "\n\n     EMminer accesses the Control-M Enterprise Manager DB using simple SQL selects\n";
           print "     with the SQL client on your machine.  If there is no SQL client, EMminer will\n";
           print "     not work.  Either use a different machine, or ask your DBA team to install a SQL\n";
           print "     client that will access the EM DB.  You can test access with the following.\n";
           print "\n\n     This requires the emuser id, password, DB server, DB type, and port (if not default).\n";
           print "     If this is your first use of EMminer, here is how you validate those values.\n";
           print "\n";
           print "     Open a command window and try the native SQL command required for your DB type.\n\n";
           print "\n        For Sybase      --> isql -U<EM user id> -P<pswd> -S<dbserver> \n";
           print "        For MSsql 2000  --> isql -U<EM user id> -P<pswd> -S<dbserver> \n";
           print "        For MSsql 2005  --> osql -U<EM user id> -P<pswd> -S<dbserver>\n";
           print "        For MSsql 2008  --> osql -U<EM user id> -P<pswd> -S<dbserver>\n";
           print "        For MSDE        --> osql -U<EM user id> -P<pswd> -S<dbserver>\n";
           print "        For Oracle      --> sqlplus <EM user id>/<pswd>@<dbserver> \n";
           print "                  <TNS net service name> or //<hostname>:<port>/<SID> are valid dbserver names\n";
           print "                  Oracle instant client is a quick and easy way of adding an Oracle client.\n";
           print "                  Add Oracle instant client's basic and sqlplus components\n";
           print "\n        For PostgreSQL --> psql -W -U<EM user id> -h<dbserver> -d <EM db name> -p<port if not default>\n";
           print "                  You will be prompted for the password. To exit psql use \\q\n";
           print "                  For quick and easy psql access on Windows add psql.exe, libeay32.dll, libpq.dll\n";
           print "                  and ssleay32.dll into the folder used to run emminer.pl\n";
           print "                  If psql.exe is version 9.1 or above you may get an error - FATAL: conversion between WIN1252 ...\n";
           print"                   set PGCLIENTENCODING=SQL_ASCII in the environment before re-running emminer\n\n";
           print "    If you see a response like SQL>       , you can then exit from SQL and your values were OK.\n";
           print "    If the login fails, then try a different id, password, dbserver, or contact your DBA.\n\n\n";
        }


#
#------------------------
# set up os specific variables and file variables
#-----------------------
sub osvars
        {
          $iwin=index($^O,"Win");                       # test for OS type
          $dq='"';

        # set all OS specific commands to Unix type then reset if this is a Windows OS

                $slash="/";
                $tempdir="$ENV{EM_HOME}/../tmp";            # ~/ctm_em/../temp
                # $tempdir="$ENV{USER}/tmp";            # ~/tmp (comment prior and uncomment this if erroring in finding tempdir. adjust as needed (/var/tmp?))
                $oscopy="cp";
                $ostype="cat";
                $osclear="clear";
                $oserase="rm";
                $oseditor="vi";
                $osrename="mv";
                $osdir="ls";
                $osmkdir="mkdir";
                $osping="ping -c 1 -w 1";
                $ospsql="psql";
                $ospsqlhelp=" --help"; # used to find psql
                $oserrredirect1=">&"; # redirect stdout and stderr to a file - csh (sh would be "2>&1")
                $oserrredirect2="";
                $multcmdsep=";";

                if ($iwin > -1)         # this is a windows OS, reset these variables
                   {
                         $slash="\\";
                         $tempdir=$ENV{TEMP};       # the users %TEMP% directory
                         $oscopy="copy";
                         $ostype="type";
                         $osclear="cls";
                         $oserase="erase";
                         $oseditor="notepad";
                         $osrename="rename";
                         $osdir="dir";
                         $osmkdir="mkdir";
                         $osping="ping -4 -n 1 -w 1000"; # -w in milliseconds on Windows
                         $ospsql="psql.exe";
                         $ospsqlhelp=" -?";
                         $oserrredirect1="1>";
                         $oserrredirect2="2>&1";
                         $multcmdsep=" && ";
                   }

        #------------------------------------------------------------------------------------
        # define the file names here so they agree with the OS type for slashes, etc
        #------------------------------------------------------------------------------------

                $calsql         ="$tempdir" . "$slash" . "calsql.sql";                          # used for calendar sql request
                $calsqlout      ="$tempdir" . "$slash" . "calsql.out";                          # holds the calendar sql request output
                $tempc          ="$tempdir" . "$slash" . "temper";
                $cmdstrings     ="$tempdir" . "$slash" . "emminer.cmdstrings";          # created file to hold strings to search for in command line
                $report02       ="$tempdir" . "$slash" . "emminer.report02";
                $emusers        ="$tempdir" . "$slash" . "emminer.emusers";
                $emusers2       ="$tempdir" . "$slash" . "emminer.emusers2";
                $emusers3       ="$tempdir" . "$slash" . "emminer.emusers3";
                $new            ="$tempdir" . "$slash" . "emminer.new";
                $gps            ="$tempdir" . "$slash" . "emminer.gps";
                $bitbucket      ="$tempdir" . "$slash" . "emminer.temp.txt";
                $ftpcommands="$tempdir" . "$slash" . "emminer.temp.ftpcommands";
                $tempfile       ="$tempdir" . "$slash" . "emminer.temp.txt";
                $sqlinfile      ="$tempdir" . "$slash" . "emminer.sqlin.sql";           # generally holds the sql commands to be executed
                $sqloutfile     ="$tempdir" . "$slash" . "emminer.sqlout.out";          # generally holds the response from sql commands
                $sqloutfileb="$tempdir" . "$slash" . "emminer.sqlout.outb";
                $configfile     ="$tempdir" . "$slash" . "emminer.config";                      # holds the input prompts from users in a config file
        }

#-------------------------#
# routine Pauser          #  general routine to pause the screen for user response or enter
#-------------------------#

sub Pauser
        {
                if (!$silent)
                   {
                        #if ($debug)
                                #{
                                         if ("$_[0]" ne "") {  print "-- at program line: $_[0]\n";}
                                #}
                        #print "-- at program line: $_[0]\n";
                        print "Hit enter to continue .....\n";
                        $nop=<STDIN>;
                        chop($nop);
                        if ($nop eq "q") {exit;}
                        if ($nop eq "d")
                           {
                                   if ($debug) {$debug=0;print "-- debug now off\n";}
                                   else {$debug=1;print "-- debug now on\n";}
                           }
                   }
                return
        }

#------------------------------------------------------
# routine spinit
#
# calling example --> & Spinit(1,$LastRow);
# where the 1 indicates that the spinit routine should be producing % complete feedback by default every 10% (0 means don't show % complete)
#           in this case $LastRow (or the 2nd value) indicates how many rows are to be processed (hmmm, seems no longer needed in this routine)
#------------------------------------------------------

sub Spinit
{

                if ($_[0])
                        {
                          $progress++;
                          if (($progress == $upd_interval) || ($progress > $upd_interval))
                            {
                                $tot_Done=$tot_Done+$progress;
                                if ($_[1] < 1) {$tot_perc_Done=100;}
                                else {$tot_perc_Done=$tot_Done*100/$_[1] ;}
                                printf ("%4d",$tot_perc_Done);
                                print "$percent";
                                print "\b\b\b\b\b";
                                $progress=0;
                            }
                        }

                print "$spinner[$spinner_index]\b";     # this actually prints the "rolling dash" to show progress is happening
                $spinner_index++;
                if ($spinner_index > 3) {$spinner_index=0;}

}

#----------------------------------
# syntax for emminer
#----------------------------------

sub syntax
        {
      print " EMminer syntax\n";
      print "\n";
      print " May be invoked as a .exe (executable) from a Windows machine or as a source PERL\n";
      print " routine from a Windows or UNIX machine.  Access to the EM DB via a SQL client\n";
      print " (i.e. sqlplus for Oracle DB, osql for MSsql, isql for Sybase, Psql for PostgreSQL)\n";
      print " is required as that is the DB access used by EMminer to gather information.\n\n";
      print " emminer.pl     or   emminer.exe     (invokes the routine)\n";
      print " options:  -d       (turns on debugging)\n";
      print "           -silent  (uses previous input values and runs with no prompts)\n";
      print "           -noip    (turns off IP address lookup)\n";
      print "           -y 2010  (uses 2010 as the year for checking for duplicate calendars instead of gettime() $year)\n";
      print "           -old     (display old terminology e.g. Tbls not Folders)\n";
        }

#------------------------------------------------------------
#  this routine marks the start of some alert analysis to be added
#------------------------------------------------------------

sub determinealerttype
     {
             if ($debug)
                {
                        print "\n -- starting determinealerttype routine with the following counts in place\n";
                        $dat_ind=-1;
                        printf ("  %20s   %5s   %5s   %5s   %5s   %5s   %5s  %5s   %5s   %5s  %5s\n","application         ","agsta","notok","rest","syste","other"," sla ","late "," bim "," OK  ","nsubm","nstar","long","rest");
                        foreach my $da (@appname)
                             {
                                     $dat_ind++;
                                     printf ("  %20s   %5d   %5d   %5d   %5d   %5d   %5d   %5d   %5d   %5d  %5d\n",$da,$alerttype_agstatus[$dat_ind],$alerttype_notok[$dat_ind],$alerttype_restart[$dat_ind],$alerttype_system[$dat_ind],$alerttype_other[$dat_ind],$alerttype_sla[$dat_ind],$alerttype_late[$dat_ind],$alerttype_bim[$dat_ind],$alerttype_ok[$dat_ind],$alerttype_notsub[$dat_ind],$alerttype_notstarted[$dat_ind],$alerttype_long[$dat_ind],$alerttype_restart[$dat_ind]);
                             }
                }
             $messagetext=lc($alarmarray[3]);
             $ttype=lc($alarmarray[16]);
                 $ttype=~ s/^\s+//;        #remove leading & trailing blanks from application
         $ttype=~ s/\s+$//;
             if ($debug) {print " --messagetext=$messagetext\n";}
             #print " \n---type=$ttype.\n";
             if ($ttype eq "b")                                            {$alerttype_bim[$app_ind]++;if ($debug) {print " -- bim seen\n";} goto datend; }
             if (index($messagetext,"sla warning")>-1)     {$alerttype_sla[$app_ind]++;if ($debug) {print " -- sla warning seen\n";} goto datend; }
             if (index($messagetext,"status of agent")>-1) {$alerttype_agstatus[$app_ind]++;if ($debug) {print " -- status of agent seen\n";}goto datend;}
             if (index($messagetext,"ended notok")>-1)     {$alerttype_notok[$app_ind]++;if ($debug) {print " -- notok seen\n";}goto datend;   }
             if (index($messagetext,"failed")>-1)          {$alerttype_notok[$app_ind]++;if ($debug) {print " -- failed seen\n";}goto datend;   }
             if (index($messagetext,"not submitted")>-1)   {$alerttype_notsub[$app_ind]++;if ($debug) {print " -- not submitted seen\n";}goto datend;   }
             if (index($messagetext,"not started")>-1)     {$alerttype_notstart[$app_ind]++;if ($debug) {print " -- not started seen\n";}goto datend;   }
             if (index($messagetext,"restart")>-1)         {$alerttype_restart[$app_ind]++;if ($debug) {print " -- restart seen\n";}goto datend; }
             if (index($messagetext," late")>-1)           {$alerttype_late[$app_ind]++;if ($debug) {print " -- late seen\n";}goto datend; }
             if (index($messagetext," long")>-1)           {$alerttype_long[$app_ind]++;if ($debug) {print " -- long seen\n";}goto datend; }
             if (index($messagetext," notok")>-1)          {$alerttype_notok[$app_ind]++;if ($debug) {print " -- just notok seen\n";}goto datend;   }
             if (index($messagetext,"completed")>-1)       {$alerttype_ok[$app_ind]++;if ($debug) {print " -- completed seen\n";}goto datend;   }
             if (index($messagetext,"ok")>-1)              {$alerttype_ok[$app_ind]++;if ($debug) {print " -- ok seen\n";}goto datend;   }
             if ($appname[$app_ind] eq "Control-M")        {$alerttype_system[$app_ind]++;if ($debug) {print " -- control-m seen\n";}goto datend; }
             if ($debug) {print " -- alert type did not match so dropping into other bucket\n";}
             $alerttype_other[$app_ind]++;
#  @alerttype_restart=();    # RESTART
#  @alerttype_long=();          # LONG or "RUNNING MORE" or "OVER AVERAGE" or "EXCEEDED"
#  @alerttype_late=();          # LATE
#  @alerttype_notstarted=(); # "NOT STARTED"
#  @alerttype_notsub=();                # "NOT SUBMITTED"
#  @alerttype_OK=();                    # COMPLETED or OK (tested after other types in fall thru logic)
datend:
  if ($debug)
                {
                        print "\n -- ending determinealerttype routine with the following counts in place\n";
                        $dat_ind=-1;
                        foreach my $da (@appname)
                             {
                                     $dat_ind++;
                                     printf ("  %20s   %5d   %5d   %5d   %5d   %5d   %5d   %5d   %5d   %5d\n",$da,$alerttype_agstatus[$dat_ind],$alerttype_notok[$dat_ind],$alerttype_restart[$dat_ind],$alerttype_system[$dat_ind],$alerttype_other[$dat_ind],$alerttype_sla[$dat_ind],$alerttype_late[$dat_ind],$alerttype_bim[$dat_ind],$alerttype_ok[$dat_ind],$alerttype_notsub[$dat_ind],$alerttype_notstarted[$dat_ind],$alerttype_long[$dat_ind],$alerttype_restart[$dat_ind]);
                             }
                }
     } # end of routine determinealerttype

sub Comify      # add appropriate commas to numeric value
        {
            $text=reverse$_[0];
            $text=~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
            return scalar reverse $text
        }

#---------------------------------------------
# Routine to catch user interrups like Cntl+c
#---------------------------------------------

sub User_cntl_c_catcher
        {
          print "\n\nUser exited with Cntl+c\n";
          &Cleanup;
          exit 1301;
        }   # end of subroutine User_cntl_c_catcher


#-----------------------------------
# check for newer version of EMminer
#-----------------------------------

sub Versioncheck    # hit the internet site to see if this is the most recent version of this routine
{

    close currentver;
    if (-e "$bitbucket")     #verify that the file to be erased, exists
        {                        # erasing the general junk file

            if (-e "emminer.version.txt")
                  {
                          if ($debug) {print " -- saving emminer.version.txt (emminer.version.previous.txt)\n";}
                          system("$oscopy emminer.version.txt emminer.version.previous.txt > $bitbucket");
                          if ($debug) {print " -- eraseing old version file, $oserase emminer.version.txt\n";}
                      system("$oserase emminer.version.txt");
                  }
        }

    &Openordie("ftpcommands :: $ftpcommands :: > :: Cannot access temp file $ftpcommands Check file and directory permissions and ownership.\n");
    print ftpcommands "anonymous\n";
    print ftpcommands "emminer\n";
    print ftpcommands "cd pub\n";
    print ftpcommands "cd cannon\n";
    print ftpcommands "get emminer.version.txt\n";
    print ftpcommands "bye\n";
    close ftpcommands;
    if ($debug) {print "\nTrying to access internet site to check for more recent version.";}
    close tempfile;
    print "\nVerifying most recent version from internet ...\n";
    if ($debug)
       {
           print "debug is on, showing ftp commands which will check new version\n";
           print "-----------------------------------------------------------------\n";
           print " ftpsite: $ftpversionsite\n";
           system ("$ostype $ftpcommands");
           print "-----------------------------------------------------------------\n";
       }
    system ("ftp -s:$ftpcommands $ftpversionsite > $tempfile");

    &Openordie("ftpresults:: $tempfile :: < :: Cannot access temp file $tempfile Check file and directory permissions and ownership.\n");
    if ($debug)
       {
          print "-- here are the results from the ftp attempt\n";
          system ("$ostype $tempfile");
          &Pauser(4678);
       }
    while (<ftpresults>)
       {

           if ((index($_,"Transfer OK") > -1) || (index($_,"Transfer complete") > -1))
           {
               if ($debug) {print " Done \n";}
               goto ckver;
           }
       }
       if ($debug) { print " -- user $username version check to internet site $ftpversionsite failed";}
       if ($debug) {print " -- restoring pre ftp attempt emminer.version.txt\n";}
       system("$osrename emminer.version.previous.txt emminer.version.txt");
       print " Was unable to verify the version from internet site $ftpversionsite, sorry\n";
       print " You could email $emailcontact to request or verify newest version.\n";
       print " You are currently running $emminer_version.\n\n";
       print " Also you could manually download the file by:\n";
       print "     ftp $ftpversionsite\n";
       print "     <use anonymous for the user>\n";
       print "     <use your email name for the password>\n";
       print "     cd pub\n";
       print "     cd cannon\n";
       print "     get emminer.pl      <-- if you want the perl source\n";
       print "     bin\n";
       print "     get emminer.exe     <-- if you want the Windows executable (PERL not required)\n";
       print "     get emminer_user_guide.doc\n";
       print "     bye\n\n";
       $pauseneeded=1;
       close ftpresults;
       return;


ckver:
    close ftpresults;
    &Openordie("currentver:: emminer.version.txt :: < :: Cannot access latest version file emminer.version.txt.\n");
    &gettime;
    if ($verbose)
       {
           print "--Checking this routines version of $emminer_version to latest at the ftp site\n";
       }
    while (<currentver>)
    {
        chomp;

        @ver = split(/::/,"$_");
        if ($verbose) {print "@ver[0]  @ver[1]\n";}
        if ($debug) {print "-- internet ver=@ver[0]  @ver[1]  myversion=$emminer_version.\n";}

        $tv=@ver[0];

        $ltv=length($tv);
        $tv=lc($tv);
        $gotp1=0;
        $gotp2=0;
        $gotp3=0;
        $p1=$p2=$p3="";
        for ($sc=1;$sc <=$ltv;$sc++)
            {
                $nc=substr($tv,0,1);
                $tv=substr($tv,1);
                $nn="char";
                if ($nc =~ /^-?\d/) {$nn="numeric";}
                if ($nn eq "char") {$gotp1=1;}
                if ($gotp1 == 0) {$p1="$p1$nc";next;}
                if ($nc eq ".") {$gotp2=1;next;}
                if ($gotp2 == 0) {$p2="$p2$nc";next;}
                $p3="$p3$nc";
            }
        $mp1=$mp2=$mp3="";
        $lmv=length($emminer_version);
        $mv=lc($emminer_version);
        $gotp1=0;
        $gotp2=0;
        $gotp3=0;
        for ($sc=1;$sc <=$lmv;$sc++)
            {
                $nc=substr($mv,0,1);
                $mv=substr($mv,1);
                $nn="char";
                if ($nc =~ /^-?\d/) {$nn="numeric";}
                if ($nn eq "char") {$gotp1=1;}
                if ($gotp1 == 0) {$mp1="$mp1$nc";next;}
                if ($nc eq ".") {$gotp2=1;next;}
                if ($gotp2 == 0) {$mp2="$mp2$nc";next;}
                $mp3="$mp3$nc";
            }

        $newer=0;
        if ($p1 > $mp1)
           {
               if ($debug) {print "-- part 1 of version is higher on internet version ($p1 > $mp1)\n";}
               $newer=1;
           }
        if (($p1 eq $mp1) && ($p2 gt $mp2))
           {
               if ($debug) {print "-- part 1 equal but part 2 of version is higher on internet version (p1=$p1, mp2=$mp2, p2=$p2 > mp2=$mp2)\n";}
               $newer=1;
           }
        if (($p1 eq $mp1) && ($p2 eq $mp2) && ($p3 > $mp3))
           {
               if ($debug) {print "-- part 1 & 2 equal but part 3 of version is higher on internet version ($p1=$mp1, $p2=$mp2, $p3=$p3 > $mp3=$mp3)\n";}
               $newer=1;
           }

        if ($newer == 0)
           {
               print "Your version of EMminer is up to date\n\n";
               return;
           }
        else
           {
wantnv:
               print "A newer version (@ver[0]) of EMminer was released @ver[1], would you like it [ q, cancel, or (y/n)]? ";
               $ans=<STDIN>; chomp($ans);$ans=lc($ans);
                if (($ans eq "?") || ($ans eq "help"))
                     {
                     print "\nThe version of the EMminer routine your using has a new release that is available\n";
                      print "for download.  Would you like to have it automatically downloaded for you?\n";
                      goto wantnv;
                     }
               if ($ans ne "y")
                  {
                      $nop=1;
                      return;
                  }
               else {goto updver;}
           }


    }
return;  # don't know if this should ever be hit but to be safe I put it here

updver:
                if (-e "emminer_user_guide.doc")
                  {
                      system("$oserase emminer_user_guide.doc");
                  }
        if ($debug) {print " -- user $username requested download of newer version";}
&Openordie("ftpcommands:: $ftpcommands :: > :: Cannot access $ftpcommands\n");
    print ftpcommands "anonymous\n";
    print ftpcommands "emminer\n";
    print ftpcommands "cd pub\n";
    print ftpcommands "cd cannon\n";
    print ftpcommands "get emminer.pl emminer.pl.newer\n";
    print ftpcommands "bin\n";
    print ftpcommands "get emminer.exe emminer.exe.newer\n";
    print ftpcommands "get emminer_user_guide.doc.newer\n";
    print ftpcommands "bye\n";
    close ftpcommands;
    print "\naccessing site to download the newer version ... ";
    if ($verbose)
       {
           print "verbose is on, showing ftp commands which will download the new version\n";
           print "-----------------------------------------------------------------\n";
           print " ftpsite: $ftpversionsite\n";
           system ("$ostype $ftpcommands");
           print "-----------------------------------------------------------------\n";
       }
    system ("ftp -s:$ftpcommands $ftpversionsite > $tempfile");
    if (($debug) || ($verbose))
       {
          print "debug here are the results from the ftp attempt\n";
          system ("$ostype $tempfile");
          &Pauser(4842);
       }
    &Openordie("ftpresults:: $tempfile :: < :: Cannot access $tempfile\n");
    while (<ftpresults>)
       {
           if ((index($_,"Transfer OK") > -1) || (index($_,"Transfer complete")))
           {
               if ($debug) {print "user $username new version downloaded successfully";}
               print " Done \n";
               print "Now activating newer version...\n";
                   $|++;                                    # causes the perl print buffer to immediately flush

               sleep 2;
               &Openordie("tempfile:: emminer.activate.newversion.pl :: < :: Cannot access emminer.activate.newversion.pl for new version activation\n");
               print tempfile ("sleep 2;\n");
               print tempfile ("system $dq$osrename emminer.pl emminer.pl.olderversion.$emminer_version.txt $dq;\n");
               print tempfile ("system $dq$osrename emminer.exe emminer.exe.olderversion.$emminer_version.txt $dq;\n");
               print tempfile ("system $dq$osrename emminer.pl.newer emminer.pl$dq;\n");
               print tempfile ("system $dq$osrename emminer.exe.newer emminer.exe$dq;\n");
               print tempfile ("system $dq$osrename emminer_user_guide.doc.newer emminer_user_guide.doc$dq;\n");
#              print tempfile ("system $dq start emminer.pl$dq;\n");
               close tempfile;
               print "Hit enter to exit the active program, then just rerun emminer for the new version ...";
               $nop=<STDIN>;
               if ($iwin > -1)  # this is a windows machine
                  {
                    system("start perl emminer.activate.newversion.pl");
                  }
               else
                  {
                    system("emminer.activate.newversion.pl");
                  }
               exit 0;

           }
       }
       close ftpresults;
       if ($debug) {print " -- user $username download of newer version failed";}

       print " failed, sorry\n";
cmgs:  print "\nWould you like to see the messages back from the attempt (y/n)?\n";
       $ans=<STDIN>; $ans=lc($ans);
       if ($ans eq "y")
          {
              system ("$ostype $tempfile");
              print "\nHit enter to continue ...";
              $nop=<STDIN>;
          }
       if (($ans eq "?") || ($ans eq "help"))
         {
             print "\nLooks like the attempt to connect to the Internet to access the new version of\n";
             print "this routine has failed.  If you like, I will display the messages from the attempt.\n";
             goto cmgs;
         }

}

#--------------------------------------------#
# routine Openordie                          #
#--------------------------------------------#
# traditional open file commands look like: (mylabel,"< myfile") || die "my file did not open";
# and what happens is that if the open fails (does not return a value of 1 for success) you get
# the message "my file did not open" and your perl routine just ends.  Never checked but probably
# with a non zero return code.
#
# I wanted more control so that I could
#  - not only print a message but also put something in the History file about what occurred
#  - do a graceful cleanup of any temp files, etc
#  - then end with a return code of my choosing
#
# so the syntax when calling this routine would be
#    &Openordie("<label> :: <filename> :: <write or read direction symbol> :: <your message if it fails>");
# sample:  &Openordie("results :: $testfile :: < :: Could not open file $testfile to access DB dump values");

sub Openordie
{
    $topen=shift;
    @openline = split(/ :: /,"$topen");
    @openline[1]="@openline[1]";
#   print "debug openlineline[0]=@openline[0]\n";
#   print "      openlineline[1]=@openline[1]\n";
#   print "      openlineline[2]=@openline[2]\n";
    #$opengOpenordie=open (@openline[0],"@openline[2] @openline[1]")  ;
    #open A, "<", "/etc/motd";
    $opengOpenordie=open (@openline[0],"@openline[2]", "@openline[1]")  ;

    if ($fulldebug)
       {
           print "-- ".'open'." (@openline[0],$dq@openline[2] @openline[1]$dq)\n";
           print "-- Openordie file=@openline[1]";
           if ($opengOpenordie) {print " succeeded.\n"}
           else {print "failed.\n"}
           #&Pauser(4934); # commented this out.  if you were in debug, hit quit and got here, a quit from within pauser caused
           #                                       the config file (which had just been open for write, but nothing written) to be
           #                                       empty.  Simply removed this particular pause.
           #print "  @openline[3]\n";
       }

    if (!$opengOpenordie)
       {
           print "Could not ".'open'." file @openline[1], exiting\n";
           #&History("user $username open failure: $dq@openline[1]$dq @openline[3]"); # send the failure, file, and msg to the history file
           &Cleanup;
           exit 100;
       }

}
