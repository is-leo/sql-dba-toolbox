/* Purpose of this job is to secure that both nodes in the availability group has the same setup regarding:
	-SQL Logins
	-SQL Jobs
	-Linked Servers
	-Database Owners
	-Trace Flags
	-sp_configure values
	-Server Role Membership
	-Server Permissions
If there are diferences between the nodes it could lead into problems when databases failover. 

This job sends an email if it detects differences on these objects.

It helps DBA´s to uphold a good High Availability and keeping the nodes as equal as possible.



PREREQUISITES

- Database Mail needs to be activated and configured

How to set up AOAG Check:
1. On each replica Create User AOAG_Check from script.
2. On each replica Create Linked Servers to other replica with user AOAG_Check
3. On each replica Create Stored Procedure from script
4. On each replica Create SQL job from Script
5. On each replica Change mail-recipient in job to appropriate recipent(s).
*/

--Step 1: On each replica Create User AOAG_Check from script
-- Login: aoag_check
CREATE LOGIN [aoag_check] WITH PASSWORD = 0x0200620C1F49DF6F483D34FC2AEAEB9002EF70D55C0D108D35CB0B32A6C5AB5A078BEF604E588B9AD531B80CE7C036B94307BEEDBFCBA9CB940463469A866A518EEB68B3414A HASHED, SID = 0xEB860323DDEA6640A93238A1BDCE1748, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
USE [master]
GO
CREATE USER [aoag_check] FOR LOGIN [aoag_check]
GO
USE [master]
GO
ALTER ROLE [db_owner] ADD MEMBER [aoag_check]
GO
USE [msdb]
GO
CREATE USER [aoag_check] FOR LOGIN [aoag_check]
GO
USE [msdb]
GO
ALTER ROLE [db_owner] ADD MEMBER [aoag_check]
GO

--Step 2: On each replica Create Linked Servers to other replica with user AOAG_Check
USE [master]
GO

DECLARE @linkedserver varchar(100)
DECLARE @passw varchar(50)

set @linkedserver =''
set @passw = ''

/****** Object:  LinkedServer [SQLCLT02N1\ITKONTOR2012]    Script Date: 2016-08-08 10:53:31 ******/
EXEC master.dbo.sp_addlinkedserver @server = @linkedserver, @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@linkedserver,@useself=N'False',@locallogin=NULL,@rmtuser=N'aoag_check',@rmtpassword=@passw
EXEC master.dbo.sp_serveroption @server=@linkedserver, @optname=N'remote proc transaction promotion', @optvalue=N'false'
GO

--Step 3: On each replica Create Stored Procedure from script
USE [master]
GO
/****** Object:  StoredProcedure [dbo].[EmailReportOfMismatchForJobsAndLogins]    Script Date: 2018-04-03 08:11:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
/*********************************************************************************************************
2014-11-17 Jan Nieminen
Check if Logins and SQL Server Agent Jobs are not in sync between Primary and Secondary server(s)
Send email with report of all mismatchning objects.
 
2015-03-24 Jan Nieminen
Added logic for check of missing Linked Servers and adapted code to AlwaysOn
 
2015-11-24 Jan Nieminen
Added logic for check of Database Owner for all user databases

2016-07-13 Niklas Sternbrink
Changed to parameters for recipient

2016-08-23 Steinar Andersen
Added checks for Trace Flags and sp_configure values
 

2016-08-30 Steinar Andersen
Added checks for Server Role Membership and Server Permissions
EXEC dbo.EmailReportOfMismatchForJobsAndLogins N'steinar.andersen@sqlservice.se'

2018-04-03 Steinar Andersen
Fixed checks for Server Permissions, now uses openquery to make sure that suser_name() function executes at remote server when that is required

DROP TABLE #tmpMissingJobsOrLogins

**********************************************************************************************************/
ALTER PROCEDURE [dbo].[EmailReportOfMismatchForJobsAndLogins] @to nvarchar(500)
 
AS
BEGIN
SET NOCOUNT ON;

DECLARE @subject nvarchar(500)
DECLARE @from nvarchar(500)
DECLARE @messages NVARCHAR(max)
DECLARE @jobdate int
DECLARE @jobname varchar(100)
DECLARE @jobstatus int
DECLARE @PrimaryReplica VARCHAR(200)
DECLARE @SecondaryReplica VARCHAR(200)
DECLARE @SQLText VARCHAR(1000)

 
SELECT @PrimaryReplica = AR.replica_server_name
FROM sys.availability_replicas AR inner join sys.dm_hadr_availability_replica_states ARS on ARS.replica_id = AR.replica_id
WHERE ARS.role_desc = 'PRIMARY'
 
SELECT @SecondaryReplica = AR.replica_server_name
FROM sys.availability_replicas AR inner join sys.dm_hadr_availability_replica_states ARS on ARS.replica_id = AR.replica_id
WHERE ARS.role_desc = 'SECONDARY' and availability_mode = 1



--Create temporary tables to hold resultset
CREATE TABLE #tmpMissingJobsOrLogins
(ID INT IDENTITY(1,1),
LoginName VARCHAR(500),
LoginSidPrimary VARBINARY(85),
LoginSidMirror VARBINARY(85),
JobName VARCHAR(500),
LinkedServerName VARCHAR(100),
MissingOnServer VARCHAR(200),
DBName VARCHAR(200),
OwnerOnPrimary VARCHAR(200),
OwnerOnSecondary VARCHAR(200),
TraceFlag INT,
ConfigName VARCHAR(200),
ConfigValue VARCHAR(200),
ServerRole VARCHAR(200),
ServerRoleMember VARCHAR(200),
Permission VARCHAR(200)
)



create table #traceprimary
(
TraceFlag INT
,Status INT
, Global INT
, Session INT
)

create table #tracesecondary
(
TraceFlag INT
,Status INT
, Global INT
, Session INT
)


-- Start DataCollection
 
--Get mismatching logins
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(LoginName, LoginSidPrimary, MissingOnServer) SELECT name, sid, ''' + QUOTENAME(@SecondaryReplica) + ''' AS LoginMissingOnServer FROM ' + QUOTENAME(@PrimaryReplica) + '.master.sys.server_principals WHERE name NOT IN (SELECT name FROM ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals)'
EXEC(@SQLText)
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(LoginName, LoginSidMirror, MissingOnServer) SELECT name, sid, ''' + QUOTENAME(@PrimaryReplica) + ''' AS LoginMissingOnServer FROM ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals WHERE name NOT IN (SELECT name FROM ' + QUOTENAME(@PrimaryReplica) + '.master.sys.server_principals)'
EXEC(@SQLText)
 
--Check mismatching sids
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(LoginName, LoginSidPrimary, LoginSidMirror) SELECT P.name, P.sid, SP.sid FROM master.sys.server_principals P
                                                  INNER JOIN ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals SP ON SP.name = P.name
                                                  WHERE P.sid <> SP.sid
                                                  AND P.type = ''S''
                                                  AND P.is_disabled = 0'
EXEC(@SQLText)
 
--Get mismatching jobs
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(JobName, MissingOnServer) SELECT name, ''' + QUOTENAME(@SecondaryReplica) + ''' AS JobMissingOnServer FROM ' + QUOTENAME(@PrimaryReplica) + '.msdb.dbo.sysjobs WHERE name NOT IN (SELECT name FROM ' + QUOTENAME(@SecondaryReplica) + '.msdb.dbo.sysjobs)'
EXEC(@SQLText)
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(JobName, MissingOnServer) SELECT name, ''' + QUOTENAME(@PrimaryReplica) + ''' AS JobMissingOnServer FROM ' + QUOTENAME(@SecondaryReplica) + '.msdb.dbo.sysjobs WHERE name NOT IN (SELECT name FROM ' + QUOTENAME(@PrimaryReplica) + '.msdb.dbo.sysjobs)'
EXEC(@SQLText)
 
--Get missing LinkedServers
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(LinkedServerName, MissingOnServer) SELECT srvname, ''' + QUOTENAME(@SecondaryReplica) + ''' AS LinkedServerMissingOnServer FROM ' + QUOTENAME(@PrimaryReplica) + '.master.sys.sysservers WHERE srvname NOT IN (SELECT srvname FROM ' + QUOTENAME(@SecondaryReplica) + '.master.sys.sysservers)'
EXEC(@SQLText)
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(LinkedServerName, MissingOnServer) SELECT srvname, ''' + QUOTENAME(@PrimaryReplica) + ''' AS LinkedServerMissingOnServer FROM ' + QUOTENAME(@SecondaryReplica) + '.master.sys.sysservers WHERE srvname NOT IN (SELECT srvname FROM ' + QUOTENAME(@PrimaryReplica) + '.master.sys.sysservers)'
EXEC(@SQLText)
 
 
--Get mismatching database owner
SET @SQLText = 'INSERT INTO #tmpMissingJobsOrLogins(DBName, OwnerOnPrimary, OwnerOnSecondary)
select SD.name, SP.name as OwnerOnPrimary, SSP.name as OwnerOnSecondary from sys.databases SD
inner join sys.server_principals SP on SP.sid = SD.owner_sid
inner join ' + QUOTENAME(@SecondaryReplica) + '.master.sys.databases SSD on SSD.name = SD.name
inner join ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals SSP on SSP.sid = SSD.owner_sid
where SD.name not in (''master'',''model'',''msdb'',''tempdb'')
and SP.name <> SSP.name'
EXEC(@SQLText)

--Get mismatching Trace Flags
SET @SQLText = 'INSERT INTO #traceprimary 
exec '+ QUOTENAME(@PrimaryReplica) + '.master.sys.sp_executesql N''dbcc tracestatus'''
EXEC(@SQLText)

SET @SQLText = 'INSERT INTO #tracesecondary
exec ' + QUOTENAME(@SecondaryReplica) + '.master.sys.sp_executesql N''dbcc tracestatus'''
EXEC(@SQLText)



;with cte as
(
 select 
 TraceFlag 
,Status 
, Global 
, Session  
from #traceprimary

except

 select 
 TraceFlag 
,Status 
, Global 
, Session 
from #tracesecondary
)

INSERT INTO #tmpMissingJobsOrLogins(TraceFlag, MissingOnServer)
select TraceFlag, @SecondaryReplica  from cte



;with cte as
(
 select 
 TraceFlag 
,Status 
, Global 
, Session  
from #tracesecondary

except

 select 
 TraceFlag 
,Status 
, Global 
, Session 
from #traceprimary
)

INSERT INTO #tmpMissingJobsOrLogins(TraceFlag, MissingOnServer)
select TraceFlag, @PrimaryReplica  from cte


-- Configuration values
;
SET @SQLText = 'with cte as
(
 select  name as Name,  cast(Value as varchar(8000)) as Value 
FROM 
   (SELECT cast(Name as varchar(8000)) as name 
   , cast(Value as varchar(8000)) as ConfigValue
   , cast(Value_in_use as varchar(8000)) as Value_in_use
    from '+ QUOTENAME(@PrimaryReplica) + '.master.sys.configurations) p
UNPIVOT
   (Value FOR Valuetype IN 
      (ConfigValue, Value_in_use)
)AS unpvt

EXCEPT

  select   name as Name,  cast(Value as varchar(8000)) as Value 
FROM 
   (SELECT cast(Name as varchar(8000)) as name 
   , cast(Value as varchar(8000)) as ConfigValue
   , cast(Value_in_use as varchar(8000)) as Value_in_use
    from ' + QUOTENAME(@SecondaryReplica) + '.master.sys.configurations) p
UNPIVOT
   (Value FOR Valuetype IN 
      (ConfigValue, Value_in_use)
)AS unpvt
)
INSERT INTO #tmpMissingJobsOrLogins(ConfigName, ConfigValue, MissingOnServer)
select Name, Value, '''  + @SecondaryReplica + '''  from cte'
EXEC(@SQLText)

;
SET @SQLText = 'with cte as
(
 select  name as Name,  cast(Value as varchar(8000)) as Value 
FROM 
   (SELECT cast(Name as varchar(8000)) as name 
   , cast(Value as varchar(8000)) as ConfigValue
   , cast(Value_in_use as varchar(8000)) as Value_in_use
    from '+ QUOTENAME(@SecondaryReplica) + '.master.sys.configurations) p
UNPIVOT
   (Value FOR Valuetype IN 
      (ConfigValue, Value_in_use)
)AS unpvt

EXCEPT

  select   name as Name,  cast(Value as varchar(8000)) as Value 
FROM 
   (SELECT cast(Name as varchar(8000)) as name 
   , cast(Value as varchar(8000)) as ConfigValue
   , cast(Value_in_use as varchar(8000)) as Value_in_use
    from ' + QUOTENAME(@PrimaryReplica) + '.master.sys.configurations) p
UNPIVOT
   (Value FOR Valuetype IN 
      (ConfigValue, Value_in_use)
)AS unpvt
)
INSERT INTO #tmpMissingJobsOrLogins(ConfigName, ConfigValue, MissingOnServer)
select Name, Value, '''  + @PrimaryReplica + '''  from cte'
EXEC(@SQLText)


-- ServerRole Membership
;
SET @SQLText = 'with cte as
(
SELECT  role.Name  as ServerRole , 
    Member.Name  as ServerRoleMember 
FROM ' + QUOTENAME(@PrimaryReplica) + '.master.sys.server_role_members AS members
JOIN ' + QUOTENAME(@PrimaryReplica) + '.master.sys.server_principals AS role
    ON members.role_principal_id = role.principal_id
JOIN ' + QUOTENAME(@PrimaryReplica) + '.master.sys.server_principals AS member
    ON members.member_principal_id = member.principal_id


EXCEPT

SELECT  role.Name  as ServerRole , 
    Member.Name  as ServerRoleMember 
FROM '+ QUOTENAME(@SecondaryReplica) + '.master.sys.server_role_members AS members
JOIN '+ QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals AS role
   ON members.role_principal_id = role.principal_id
JOIN '+ QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals AS member
   ON members.member_principal_id = member.principal_id
)
INSERT INTO #tmpMissingJobsOrLogins(ServerRole, ServerRoleMember, MissingOnServer)
select ServerRole, ServerRoleMember,  '''  + @SecondaryReplica + '''  from cte'
EXEC(@SQLText)


;
SET @SQLText = 'with cte as
(
SELECT  role.Name  as ServerRole , 
    Member.Name  as ServerRoleMember 
FROM ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_role_members AS members
JOIN ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals AS role
   ON members.role_principal_id = role.principal_id
JOIN ' + QUOTENAME(@SecondaryReplica) + '.master.sys.server_principals AS member
     ON members.member_principal_id = member.principal_id

EXCEPT

SELECT  role.Name  as ServerRole , 
    Member.Name  as ServerRoleMember  
FROM '+ QUOTENAME(@PrimaryReplica) + '.master.sys.server_role_members AS members
JOIN '+ QUOTENAME(@PrimaryReplica) + '.master.sys.server_principals AS role
   ON members.role_principal_id = role.principal_id
JOIN '+ QUOTENAME(@PrimaryReplica) + '.master.sys.server_principals AS member
     ON members.member_principal_id = member.principal_id
)
INSERT INTO #tmpMissingJobsOrLogins(ServerRole, ServerRoleMember, MissingOnServer)
select ServerRole, ServerRoleMember,  '''  + @PrimaryReplica + '''  from cte'
EXEC(@SQLText)




-- Server permissions

;
SET @SQLText = 'with cte as
(
select 
state_desc  +  '' '' + permission_name + '' TO '' + '' '' + 
suser_name(grantee_principal_id) + '' GRANTED BY '' + '' '' + suser_name(grantor_principal_id)  AS Permission
from master.sys.server_permissions


EXCEPT

SELECT * FROM OPENQUERY (['+@SecondaryReplica+'],
''select state_desc 
 + '''' ''''  + permission_name + '''' TO '''' + '''' '''' + suser_name(grantee_principal_id) + '''' GRANTED BY '''' + '''' '''' + suser_name(grantor_principal_id)  AS Permission
from master.sys.server_permissions''
))
INSERT INTO #tmpMissingJobsOrLogins(Permission, MissingOnServer)
select Permission,  '''  + @SecondaryReplica + '''  from cte'
EXEC(@SQLText)


;
SET @SQLText = 'with cte as
(SELECT * FROM OPENQUERY (['+@SecondaryReplica+'],
''select state_desc 
 + '''' ''''  + permission_name + '''' TO '''' + '''' '''' + suser_name(grantee_principal_id) + '''' GRANTED BY '''' + '''' '''' + suser_name(grantor_principal_id)  AS Permission
from master.sys.server_permissions''
)

EXCEPT

select 
state_desc  +  '' '' + permission_name + '' TO '' + '' '' + 
suser_name(grantee_principal_id) + '' GRANTED BY '' + '' '' + suser_name(grantor_principal_id)  AS Permission
from master.sys.server_permissions
)
INSERT INTO #tmpMissingJobsOrLogins(Permission, MissingOnServer)
select Permission,  '''  + @PrimaryReplica + '''  from cte'

EXEC(@SQLText)




-- Debug
Select * from #tmpMissingJobsOrLogins
-- End Debug





-- End DataCollection

-- Build the mail
--Set subject
SET @subject = 'Warning! - Object mismatch between Primary and Secondary replica(s)'
SET @from = 'Dustinmail' -- Mailprofile name on SQL instance

 
-- Build HTML table

-- Print replica names


SET @messages = '</table><BR><BR>'
SET @messages = @messages + '</table>'

SET @messages = @messages + '<h3>Replicas in this Availability Group</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Primary Replica</b></td></tr>'

SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + @PrimaryReplica + '</td></tr></b>'

SET @messages = @messages + '</table><BR>'

SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Secondary Replica</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>'  + @SecondaryReplica + '</td></tr></b>'


--Logins
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'

SET @messages = @messages  +'<h3>SQL Logins mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>Login name&nbsp;&nbsp;</b></td><td><b>Login SID Primary&nbsp;&nbsp;</b></td><td><b>Login SID Secondary&nbsp;&nbsp;</b></td><td><b>Missing On Server&nbsp;&nbsp;</b></td><td><b>Comment&nbsp;&nbsp;</b></td></tr>'
 
SELECT @messages = @messages + ISNULL('<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10))
                             + '</td><td>' + LoginName + '</td><td>'
                             + ISNULL(CONVERT(NVARCHAR(100), LoginSidPrimary, 1), '-') + '</td><td>'
                             + ISNULL(CONVERT(NVARCHAR(100), LoginSidMirror, 1), '-') + '</td><td>'
                             + ISNULL(MissingOnServer, '-') + '</td><td>'
                             + CASE WHEN LoginSidPrimary <> LoginSidMirror
                             THEN 'SID Mismatch on login between servers.' + CHAR(13) + CHAR(10) + 'Drop and recreate login on Mirror server with sid=' + convert(nvarchar(200), LoginSidPrimary, 1)
                             WHEN MissingOnServer = @SecondaryReplica
                             THEN 'Create login on ' + @SecondaryReplica + ' with sid=' + CONVERT(NVARCHAR(200), LoginSidPrimary, 1)
                             WHEN MissingOnServer = @PrimaryReplica
                             THEN 'Create login on ' + @PrimaryReplica + ' with sid=' + CONVERT(NVARCHAR(200), LoginSidMirror, 1)
                             ELSE '--'
                             END + '</td></tr></b>', '')
FROM #tmpMissingJobsOrLogins
ORDER BY ID
 
--Jobs
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>SQL Agent Jobs mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>Job name&nbsp;&nbsp;</b></td><td><b>Missing On Server&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + JobName + '</td><td>' + MissingOnServer + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE JobName IS NOT NULL AND MissingOnServer IS NOT NULL
 
--LinkedServers
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>Linked Servers mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>Linked Server&nbsp;&nbsp;</b></td><td><b>Missing On Server&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + LinkedServerName + '</td><td>' + MissingOnServer + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE LinkedServerName IS NOT NULL AND MissingOnServer IS NOT NULL
 
--DatabaseOwner
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>Database Owner mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>Database&nbsp;&nbsp;</b></td><td><b>OwnerOnPrimary&nbsp;&nbsp;</b></td><td><b>OwnerOnSecondary&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + DBName + '</td><td>' + OwnerOnPrimary + '</td><td>' + OwnerOnSecondary + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE DBName IS NOT NULL
 
 
--Trace Flags
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>Trace Flag mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>Trace Flag&nbsp;&nbsp;</b></td><td><b>Missing On Server&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + CAST(TraceFlag as VARCHAR(10)) + '</td><td>' + MissingOnServer + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE TraceFlag IS NOT NULL AND MissingOnServer IS NOT NULL

--Config Values
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>Configuration (sp_configure) mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>ConfigName&nbsp;&nbsp;</b></td><td><b>ConfigValue&nbsp;&nbsp;</b></td><td><b>DifferentOnServer&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + ConfigName + '</td><td>' + ConfigValue + '</td><td>' + MissingOnServer + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE ConfigName IS NOT NULL


-- ServerRole Membership

SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>Serverrole membership mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>ServerRole&nbsp;&nbsp;</b></td><td><b>ServerRoleMember&nbsp;&nbsp;</b></td><td><b>MissingOnServer&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + ServerRole + '</td><td>' + ServerRoleMember + '</td><td>' + MissingOnServer + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE ServerRole IS NOT NULL


--Server Permissions
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'
 
SET @messages = @messages + '<h3>Server Permissions mismatch between Primary and Secondary replica(s)</h3>'
SET @messages = @messages  +'<table style="font-family:Arial;font-size:10pt"; table border="1";><tr><td><b>Id&nbsp;&nbsp;</b></td><td><b>ServerPermission&nbsp;&nbsp;</b></td><td><b>Missing On Server&nbsp;&nbsp;</b></td></tr>'
SELECT @messages = @messages + '<tr bgcolor=#E6F7F6><td>' + CAST(ID as VARCHAR(10)) + '</td><td>' + Permission + '</td><td>' + MissingOnServer + '</td></tr></b>'
FROM #tmpMissingJobsOrLogins WHERE Permission IS NOT NULL


--Footer
SET @messages = @messages + '</table><BR><BR>'
SET @messages = @messages + '</table>'

-- END email build 

-- Send Mail if mismatches found
IF (SELECT COUNT(*) FROM #tmpMissingJobsOrLogins) > 0
BEGIN
            --Email result if resultset not empty
            EXEC msdb.dbo.sp_send_dbmail @profile_name = @from, @recipients = @to, @subject = @subject, @body = @messages, @body_format= 'HTML'
	PRINT ' 


	--- Mismatches found. See mail for details ---
	
	
	'

END

ELSE	
	PRINT ' 
	

	-----  No Mismatches found ----- 
	

	'
      
 
DROP TABLE #tmpMissingJobsOrLogins
DROP TABLE #traceprimary
DROP TABLE #tracesecondary
 
END
 
 --Step 4: On each replica Create SQL job from Script
 USE [msdb]
GO

/****** Object:  Job [AOAG_Checkconfigreplicas]    Script Date: 2016-08-08 13:29:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 2016-08-08 13:29:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'AOAG_Checkconfigreplicas', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check AOAG Config replicas]    Script Date: 2016-08-08 13:29:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check AOAG Config replicas', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec [dbo].[EmailReportOfMismatchForJobsAndLogins] @to = ''DLA456gxfoodIXTSQLS5f4erver@axfood.se''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'AOAG Check', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160714, 
		@active_end_date=99991231, 
		@active_start_time=42500, 
		@active_end_time=235959, 
		@schedule_uid=N'd6268d00-d1fb-45f0-adb9-184e674a2b6d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


--Step 5: On each replica Change mail-recipient in job to appropriate recipent(s).

--Remove AOAG
/*
USE [master]
GO
/****** Object:  LinkedServer [sqlcl2n2\inst03]    Script Date: 11/19/2020 10:00:44 AM ******/
EXEC master.dbo.sp_dropserver @server=N'sqlcl2n1\inst03', @droplogins='droplogins'
GO


USE [master]
GO
/****** Object:  Login [aoag_check]    Script Date: 11/19/2020 10:01:08 AM ******/
DROP LOGIN [aoag_check]
GO


USE [master]
GO
/****** Object:  StoredProcedure [dbo].[EmailReportOfMismatchForJobsAndLogins]    Script Date: 11/19/2020 10:01:33 AM ******/
DROP PROCEDURE [dbo].[EmailReportOfMismatchForJobsAndLogins]
GO


USE [master]
GO
/****** Object:  User [aoag_check]    Script Date: 11/19/2020 10:01:50 AM ******/
DROP USER [aoag_check]
GO


USE [msdb]
GO
/****** Object:  User [aoag_check]    Script Date: 11/19/2020 10:02:07 AM ******/
DROP USER [aoag_check]
GO

USE [msdb]
GO
/****** Object:  Job [AOAG_Checkconfigreplicas]    Script Date: 11/19/2020 10:09:35 AM ******/
EXEC msdb.dbo.sp_delete_job @job_name=N'AOAG_Checkconfigreplicas', @delete_unused_schedule=1
GO
*/
