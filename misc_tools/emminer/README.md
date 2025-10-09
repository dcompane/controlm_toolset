# [Data Collection for Distributed systems]()

- Run this on all your prod and non-prod environments.
- The XML output can be opened as an MS-Excel worksheet. (use Open with, if needed))

## [Produce the **EMMiner** output for all your EMs]()

You can find the EMMiner [here](emminer.pl)

1. Run the emminer as the Linux `<emuser>`
1. Windows: Run as a user that has access to the Enterprise Manager

NOTE: The credentials (user and password) the program asks for are the DBO ones

You can open the resulting XML file with Excel.

## [Troubleshooting the EMMiner run]()

### You may need to run the emminer by prefacing it with em

```bash
em ./emminer.pl
```

You can use the BMC provided perl by using the one in the emuser directory. For v21, you can use the following example paths (logged in as the emuser)

For Linux

```bash
% em ~/bmcperl/bmcperl_V1/perl emminer.pl
```

For Windows

```cmd
C:\Program Files\BMC Server\Control-M Common\bmcperl\bmcperl_V1>perl c:\Users\dcompane1\Documents\emminer2.08.pl
```

### For Oracle Users: If you receive a database error when connecting to the database, please try using the Oracle Service Name instead of  the database server. The Oracle Service Name can be found in the DBUStatus command.

```vim
% em DBUStatus
Database Owner Password:*********
DB=Oracle
Current DB status=Up
Up Time=18-SEP-21 11.18.28 AM
Port Number= 1521
Oracle Service Name= CTMPRESP.bmc.com
Server Host Name= aus-oraprd-06a.bmc.com
Server Host Version=AIX-Based Systems (64-bit)
Client Host Name=vl-aus-ctm-em01
Client Host Version=Linux vl-aus-ctm-em01 3.10.0-1160.31.1.el7.x86_64 #1 SMP Thu Jun 10 13:32:12 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux
Is DB Remote=True
DB Server Version=19.0.0.0.0
DB Client Version=18.0.0.0.0
```

### Security issue (fixed in v2.11)

Some files may be written to /tmp. Please check and protect as needed as they may contain the password in clear text and other information.
