/* DEFINE VARIABLE TABLE FOR HEALTH CONTROLINFO. USE ON A SINGLE OR MULTIPLE SERVERS*/

DECLARE @HC TABLE (

[Server] NVARCHAR(100),
Instance NVARCHAR(100),
AG TINYINT,
Edition NVARCHAR (50),
[Version] NVARCHAR (50),
LatestPatchVersion NVARCHAR (100),
Collation NVARCHAR (50),
NumberOfDBs INT,
ServerMemoryGB NVARCHAR (50),
MaxMemorySettMB INT,
BackupCompression TINYINT,
CostThreshold SMALLINT,
[MaxDop] TINYINT,
OptimizeAdHoc TINYINT,
RemoteAdminConnection TINYINT,
SocketsCoresLogicalProcessors NVARCHAR (50),
LinkedServers NVARCHAR (50),
TraceFlags NVARCHAR (100),
FullBackupFreq SMALLINT,
DiffBackupFreq SMALLINT,
LogBackupFreq SMALLINT,
IndexStatsInfo NVARCHAR (100),
IntegrityCheck NVARCHAR (1000),
JobOwnedByADUser NVARCHAR (1000),
DBOwnedByADUser NVARCHAR (1000),
TempDBFiles NVARCHAR (50),
AutoGrowth NVARCHAR (500),
PageVerifyOption NVARCHAR (50),
AutoShrink  NVARCHAR (50),
AutoClose  NVARCHAR (50),
TopWaits NVARCHAR (500),
PLE INT ,
SQLAgentLog NVARCHAR(MAX),
SQLServerLog NVARCHAR(MAX),
DiskWaits15sec NVARCHAR(100),
--Om AG
OwnerOfAG NVARCHAR(500),
OwnerOfEndpoint NVARCHAR(100),
GranterOnEndpoint NVARCHAR(300),
AdminRolesInstance NVARCHAR(MAX),
PublicPermissionsInstance NVARCHAR(1000),
PublicPermissionsDB NVARCHAR(MAX),
GuestPermissions NVARCHAR(100)
)


/*DECLARE HEALTH CONTROL VARIABLES. VARIABLES CAN BE ADJUSTED AND NEW BE ADDED*/

--Number of databases
DECLARE @NumberOfDBs int

SELECT @NumberOfDBs = COUNT([name]) FROM sys.sysdatabases WITH (NOLOCK)
WHERE [name] NOT IN('master', 'msdb', 'model', 'tempdb') OPTION (RECOMPILE)

--Get sockets, cores, logical processors info 
DECLARE @SocketsCoresLogicalProcessors NVARCHAR(100) = ''

SELECT @SocketsCoresLogicalProcessors = @SocketsCoresLogicalProcessors +
    ISNULL(CONVERT(NVARCHAR, socket_count), '') + ' - ' +
    ISNULL(CONVERT(NVARCHAR, cores_per_socket), '') + ' - ' +
    ISNULL(CONVERT(NVARCHAR, cpu_count), '')
FROM sys.dm_os_sys_info


-- Are there any linked servers
DECLARE @ISLINKED NVARCHAR (50) = ''
IF EXISTS (SELECT 1 FROM sys.servers WHERE is_linked = 1)
   SET @ISLINKED = 'Linked servers exist'
ELSE
   SET @ISLINKED = 'No linked servers'

-- Get Trace Info 
DECLARE @TraceStatusT TABLE (TraceFlag INT, [Status] INT, [Global] INT, [Session] INT);
INSERT INTO @TraceStatusT (TraceFlag, [Status], [Global], [Session])
EXEC('DBCC TRACESTATUS (-1)');
DECLARE @TraceStatus NVARCHAR(500) = '';
SELECT @TraceStatus = @TraceStatus + CASE WHEN EXISTS (SELECT 1 FROM @TraceStatusT) THEN 
CONCAT(MAX(TraceFlag), '-', MAX([Status]), '-', MAX([Global]), '-', MAX([Session]))
ELSE 'No traces enabled' END
FROM @TraceStatusT;
-- to test DBCC TRACEON (3604) DBCC TRACESTATUS (-1);

--The code counts total number of fullbacks for all dbs within the last seven days.
--For details check individual dbs. 
DECLARE @FullBackupFrequencyInDays SMALLINT
SELECT @FullBackupFrequencyInDays = COUNT(DISTINCT CONVERT(DATE, backup_start_date))
FROM msdb.dbo.backupset WITH (NOLOCK)
WHERE type = 'D' -- Full backup type
    AND backup_start_date >= DATEADD(DAY, -7, GETDATE())
OPTION (RECOMPILE)

--The code counts total number of diff backups for all dbs within the last seven days.
--For details check individual dbs.
DECLARE @DiffBackupFrequencyInDays SMALLINT
SELECT @DiffBackupFrequencyInDays = COUNT(DISTINCT CONVERT(DATE, backup_start_date))
FROM msdb.dbo.backupset WITH (NOLOCK)
WHERE type = 'I' -- Diff backup type
    AND backup_start_date >= DATEADD(DAY, -7, GETDATE())
OPTION (RECOMPILE)

--The code counts total number of log backups for all dbs within the last hour.
--For details check individual dbs.
DECLARE @LogBackupFrequencyInHours SMALLINT
SELECT @LogBackupFrequencyInHours = COUNT(*)
FROM msdb.dbo.backupset WITH (NOLOCK)
WHERE type = 'L' -- Log backup type
    AND backup_start_date >= DATEADD(HOUR, -1, GETDATE())
OPTION (RECOMPILE)


-- Integrity Check Info 
IF OBJECT_ID('tempdb..#DBCCInfo', 'U') IS NOT NULL
    DROP TABLE #DBCCInfo;
CREATE TABLE #DBCCInfo (
	DBName NVARCHAR(255),
    ParentObject NVARCHAR(255),
    [Object] NVARCHAR(255),
    Field NVARCHAR(255),
    [VALUE] NVARCHAR(255));

-- Loop through each database
DECLARE @DBName2 NVARCHAR(128);

DECLARE DB_CURSOR2 CURSOR FOR
SELECT [name]
FROM sys.databases WITH (NOLOCK)
WHERE state_desc = 'ONLINE' -- Consider only online databases
OPTION (RECOMPILE)

OPEN DB_CURSOR2;

FETCH NEXT FROM DB_CURSOR2 INTO @DBName2;

WHILE @@FETCH_STATUS = 0
BEGIN
DECLARE @SqlStatement NVARCHAR(1000) =  N'USE ' + QUOTENAME(@DBName2) + ';
EXEC(''DBCC DBINFO(' + QUOTENAME(@DBName2) + ') WITH TABLERESULTS'')'
--table variable to hold data about last dbcc check
DECLARE @DBCCInfoTable TABLE (
    ParentObject NVARCHAR(255),
    [Object] NVARCHAR(255),
    Field NVARCHAR(255),
    [VALUE] NVARCHAR(255)
);

-- Execute the DBCC DBINFO command and store the results in #DBCCInfo table
INSERT INTO @DBCCInfoTable  
EXEC sp_executesql @SqlStatement;

INSERT INTO #DBCCInfo (DBName, ParentObject, [Object], Field, [VALUE])
SELECT  @DBName2, ParentObject, [Object], Field, [VALUE]
FROM @DBCCInfoTable;

    FETCH NEXT FROM DB_CURSOR2 INTO @DBName2;
END;

CLOSE DB_CURSOR2;
DEALLOCATE DB_CURSOR2;

DECLARE @DBCCInfo NVARCHAR(MAX) = '';
SELECT @DBCCInfo= @DBCCInfo + DBName  + ' - '
+  max([VALUE]) + ' - ' + Field  + ' | ' + CHAR(13)
FROM #DBCCInfo 
WHERE Field = 'dbi_dbccLastKnownGood'
GROUP BY DBName, Field;

IF @DBCCInfo = ''
BEGIN
    SET @DBCCInfo= 'No metadata found, check manually';
END

DROP TABLE #DBCCInfo

--Jobs owned by AD users 
DECLARE @JobOwnedByADUser NVARCHAR(4000) = '';

SELECT @JobOwnedByADUser = @JobOwnedByADUser + 'Job:' + j.name + ' - ' + 'Owner:'
+  s.name + ' | ' + CHAR(13)
FROM msdb.dbo.sysjobs j LEFT JOIN 
sys.server_principals s WITH (NOLOCK)
ON j.owner_sid = s.sid
WHERE s.type = 'U'
OPTION (RECOMPILE);

IF @JobOwnedByADUser = ''
BEGIN
    SET @JobOwnedByADUser = '0 jobs owned by AD users';
END


--DB owned by AD Groups or Users
DECLARE @DBOwnedByADUser NVARCHAR(4000) = '';

SELECT @DBOwnedByADUser = @DBOwnedByADUser + 'DB:' + d.name + ' - ' + 'Owner:'
+ s.name + ' | ' + CHAR(13)
FROM sys.databases AS d
INNER JOIN sys.server_principals AS s WITH (NOLOCK)
ON d.owner_sid = s.sid
WHERE s.type = 'U'
OPTION (RECOMPILE);

IF @DBOwnedByADUser = ''
BEGIN
    SET @DBOwnedByADUser = '0 dbs owned by AD users';
END

--Count number of TempDB files
DECLARE @TempdbFilesAmountAvgSizeAvgGrowth NVARCHAR(50) = '';
SELECT @TempdbFilesAmountAvgSizeAvgGrowth = CAST(COUNT(name) AS NVARCHAR) 
+ ' - ' + CAST(AVG(size) AS NVARCHAR) + ' - ' + CAST(AVG(growth) AS NVARCHAR)
FROM sys.master_files WITH (NOLOCK)
WHERE database_id = DB_ID('tempdb') AND type = 0
OPTION (RECOMPILE);

--Autogrowth in %
DECLARE @FileGrowthT TABLE (
[FileName] NVARCHAR(255),
Growth NVARCHAR(255)
)

INSERT INTO @FileGrowthT
SELECT [name],
    CASE WHEN is_percent_growth = 1 THEN CONVERT(NVARCHAR(50), growth) ELSE 'NO Percent Growth' END 
FROM sys.master_files WITH (NOLOCK)
WHERE is_percent_growth = 1;

DECLARE @FileGrowth NVARCHAR(2000) = '';
SELECT @FileGrowth = @FileGrowth + [FileName] + ' grows by ' + Growth + ' % | '
 FROM @FileGrowthT

IF @FileGrowth = ''
BEGIN
    SET @FileGrowth= 'Autogrowth by % not detected';
END

-- Is Page Verify Option ON (1) or OFF(0)
DECLARE @page_verify_option NVARCHAR (50) = ''
SELECT @page_verify_option = CASE WHEN MIN(page_verify_option) < '2' THEN 'NO CHECKSUM'
ELSE 'CHECKSUM' END FROM sys.databases WITH (NOLOCK)
OPTION (RECOMPILE);

-- Is Auto Shrink ON (1) or OFF(0)
DECLARE @is_auto_shrink_on NVARCHAR (50) = ''
SELECT @is_auto_shrink_on = CASE WHEN MAX(CAST(is_auto_shrink_on AS INT)) > '0' THEN 'AUTO-SHRINK IS ON'
ELSE 'AUTO-SHRINK OFF' END FROM sys.databases WITH (NOLOCK)
OPTION (RECOMPILE);

-- Is Auto Close ON (1) or OFF(0)
DECLARE @is_auto_close_on NVARCHAR (50) = ''
SELECT @is_auto_close_on = CASE WHEN MAX(CAST(is_auto_close_on AS INT)) > '0' THEN 'AUTO-CLOSE IS ON'
ELSE 'AUTO-CLOSE OFF' END FROM sys.databases WITH (NOLOCK)
OPTION (RECOMPILE);


-- TOP 5 cumulative wait events
DECLARE @topwaits NVARCHAR(500) = ' ' 
SELECT TOP 5  @topwaits = @topwaits + wait_type + ' | '
FROM sys.dm_os_wait_stats WITH (NOLOCK)
WHERE wait_time_ms > 0 -- remove zero wait_time
 AND wait_type NOT IN -- filter out additional irrelevant waits
(N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE', N'CXCONSUMER',
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 
		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', 
		N'MEMORY_ALLOCATION_EXT', N'ONDEMAND_TASK_QUEUE',
		N'PARALLEL_REDO_DRAIN_WORKER', N'PARALLEL_REDO_LOG_CACHE', N'PARALLEL_REDO_TRAN_LIST',
		N'PARALLEL_REDO_WORKER_SYNC', N'PARALLEL_REDO_WORKER_WAIT_WORK',
		N'PREEMPTIVE_HADR_LEASE_MECHANISM', N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
		N'PREEMPTIVE_OS_LIBRARYOPS', N'PREEMPTIVE_OS_COMOPS', N'PREEMPTIVE_OS_CRYPTOPS',
		N'PREEMPTIVE_OS_PIPEOPS', N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
		N'PREEMPTIVE_OS_GENERICOPS', N'PREEMPTIVE_OS_VERIFYTRUST',
		N'PREEMPTIVE_OS_FILEOPS', N'PREEMPTIVE_OS_DEVICEOPS', N'PREEMPTIVE_OS_QUERYREGISTRY',
		N'PREEMPTIVE_OS_WRITEFILE', N'PREEMPTIVE_OS_WRITEFILEGATHER',
		N'PREEMPTIVE_XE_CALLBACKEXECUTE', N'PREEMPTIVE_XE_DISPATCHER',
		N'PREEMPTIVE_XE_GETTARGETSTATE', N'PREEMPTIVE_XE_SESSIONCOMMIT',
		N'PREEMPTIVE_XE_TARGETINIT', N'PREEMPTIVE_XE_TARGETFINALIZE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
		N'PWAIT_EXTENSIBILITY_CLEANUP_TASK',
		N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SOS_WORK_DISPATCHER',
		N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
		N'STARTUP_DEPENDENCY_MANAGER',
		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'WAIT_XTP_RECOVERY',
		N'XE_BUFFERMGR_ALLPROCESSED_EVENT', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_LIVE_TARGET_TVF', N'XE_TIMER_EVENT') 
ORDER BY wait_time_ms DESC
OPTION (RECOMPILE);

-- Info about Page Life Expectansy
DECLARE @PLE INT
SELECT @PLE = cntr_value
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE counter_name = 'Page life expectancy' 
AND object_name LIKE '%Buffer Manager%' 
OPTION (RECOMPILE);

-- Agent Errors
DECLARE  @AgentErrorLog TABLE(
LogDate DATETIME, 
ProcessInfo NVARCHAR(50), 
[Text] NVARCHAR(4000));

INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'error'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'failed'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'canceled'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'disabled'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'stopped'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'refused'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'unable'-- specify the log number 
INSERT INTO @AgentErrorLog
EXEC sp_readerrorlog 0,2, 'not enabled'-- specify the log number 


DECLARE @agenterrors NVARCHAR (MAX) = ''
SELECT @agenterrors = CASE WHEN COUNT(Text) = 0 THEN 'No errors were found'
 ELSE @agenterrors + [Text] + ' - ' + CONVERT(NVARCHAR, MIN(LogDate)) + ' - ' + CONVERT(NVARCHAR, MAX(LogDate)) +
 ' - Encountered:' + CONVERT(NVARCHAR,COUNT([Text])) + ' times | '
    END
FROM @AgentErrorLog
GROUP BY [Text]


--SQL Server Errors
DECLARE @ErrorLogs TABLE (
    LogDate DATETIME,
    ProcessInfo NVARCHAR(50),
    [Text] NVARCHAR(4000)
)

--Search messages
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Login failed'
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'SQL Server shutdown' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'deadlock' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'insufficient resources' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Failed' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Long-running query' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'High resource consumption' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Disk failure' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Network connectivity issue' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Operating system error' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Memory error' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Password expired' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Authentication failure' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Security configuration issue' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Job execution failure' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Automatic failover' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Synchronization issue' 
INSERT INTO @ErrorLogs
EXEC sp_readerrorlog 0, 1, 'Cluster warning' 


DECLARE @sqlerrors NVARCHAR(MAX) = ''
SELECT @sqlerrors = CASE
        WHEN COUNT(DISTINCT [Text]) = 0 THEN 'No errors were found'
        ELSE @sqlerrors + [Text] + ' - ' + CONVERT(NVARCHAR, MIN(LogDate)) + ' - ' + CONVERT(NVARCHAR, MAX(LogDate)) +
		+ ' - Failed:' + CONVERT(NVARCHAR,COUNT([Text])) + ' times | '
    END
FROM @ErrorLogs
GROUP BY [Text]

--I/O requests taking longer than 15 seconds
DECLARE  @DiskWaits15secT TABLE
(LogDate DATETIME, ProcessInfo NVARCHAR(50) ,[Text] NVARCHAR(4000))

INSERT INTO @DiskWaits15secT
EXEC sp_readerrorlog  0, 1, 'I/O requests taking longer than 15 seconds'

DECLARE @DiskWait15sec NVARCHAR (500) = ''
SELECT @DiskWait15sec = @DiskWait15sec + CASE WHEN COUNT(Text)  > 0
THEN CONVERT(NVARCHAR, COUNT(Text)) + ' encounters of ''I/O requests exceeding 15 secs'' between '
	+ CONVERT(NVARCHAR, MIN(LogDate)) + ' - '+ CONVERT(NVARCHAR, MAX(LogDate)) 
ELSE ' 0 encounters of ''I/O requests exceeding 15 secs'' ' END
FROM @DiskWaits15secT

/* AG VARIABLES */

-- AG Owner
DECLARE @AGOwner NVARCHAR(100) = '';
SELECT @AGOwner = @AGOwner + ar.replica_server_name + ' - ' + ag.name + ' - ' + sp.name + ' | '
FROM sys.availability_replicas ar WITH (NOLOCK)
LEFT JOIN sys.server_principals sp WITH (NOLOCK)
ON sp.sid = ar.owner_sid 
INNER JOIN sys.availability_groups ag WITH (NOLOCK)
ON ag.group_id = ar.group_id
WHERE ar.replica_server_name =  SERVERPROPERTY('ServerName')
OPTION (RECOMPILE);

IF @AGOwner = ''
BEGIN
    SET @AGOwner = 'No AG found';
END

-- Endpoint Owner
DECLARE @AGEndpointOwner NVARCHAR (100) = '';;
SELECT @AGEndpointOwner = @AGEndpointOwner + sp.name
FROM sys.database_mirroring_endpoints dme WITH (NOLOCK)
INNER JOIN sys.server_principals sp WITH (NOLOCK)
ON sp.principal_id = dme.principal_id
WHERE dme.type_desc = 'DATABASE_MIRRORING'
OPTION (RECOMPILE);

IF @AGEndpointOwner = ''
BEGIN
    SET @AGEndpointOwner = 'No Hadr_endpoint found';
END

--Endpoint grants 
DECLARE @EndpointGrants NVARCHAR (500) = '';

SELECT @EndpointGrants = @EndpointGrants + e.[name]
+ ' - Grantor:' + pr.[name] + ' - Grantee:' + gr.[name] 
+ ' - Permission:'  +  pm.[permission_name]  + ' - State:' + pm.state_desc + ' | '
FROM sys.server_permissions pm WITH (NOLOCK)
JOIN sys.server_principals pr WITH (NOLOCK)
ON pm.grantor_principal_id = pr.principal_id
JOIN sys.server_principals gr WITH (NOLOCK)
ON pm.grantee_principal_id = gr.principal_id
JOIN sys.endpoints e WITH (NOLOCK)
ON pm.grantor_principal_id = e.principal_id 
AND pm.major_id = e.endpoint_id
WHERE e.[name] = 'Hadr_endpoint'
OPTION (RECOMPILE);

IF @EndpointGrants = ''
BEGIN
    SET @EndpointGrants = 'No Endpoint grants found';
END

-- SQL Instance admin roles
DECLARE @AdminRolesInstance NVARCHAR(MAX);
SELECT @AdminRolesInstance = COALESCE(@AdminRolesInstance +  ' | ' , '') +
sp.[name] + ' - ' +  rp.[name] + ' - ' + CASE WHEN
CONVERT(NVARCHAR, sp.is_disabled) = 1 THEN 'disabled' ELSE 'enabled' END + CHAR(13)
FROM sys.server_role_members rm WITH (NOLOCK)
INNER JOIN sys.server_principals sp WITH (NOLOCK)
ON rm.member_principal_id = sp.principal_id
INNER JOIN sys.server_principals rp WITH (NOLOCK)
ON rm.role_principal_id = rp.principal_id
WHERE rp.NAME NOT IN ('public')
OPTION (RECOMPILE);

--Public permissions at the server level
DECLARE @PublicPermissionsInstance NVARCHAR(500);

SELECT @PublicPermissionsInstance = COALESCE(@PublicPermissionsInstance +  ' | ' , '') + 
                spe.permission_name + ' - ' + spe.class_desc + ' - ' + spe.state_desc + ' - ' +
                grantor.name + ' - ' + grantee.name + CHAR(13)
FROM sys.server_permissions AS spe WITH (NOLOCK)
INNER JOIN sys.server_principals AS grantor WITH (NOLOCK)
    ON grantor.principal_id = spe.grantor_principal_id
INNER JOIN sys.server_principals AS grantee WITH (NOLOCK)
    ON grantee.principal_id = spe.grantee_principal_id
WHERE grantee.name = 'public'
OPTION (RECOMPILE);


-- Check Public & Guest permissions at the db level
IF OBJECT_ID('tempdb..#PermissionResult', 'U') IS NOT NULL
    DROP TABLE #PermissionResult;
CREATE TABLE #PermissionResult (
	UserN NVARCHAR(100),
    DatabaseName NVARCHAR(100),
    ObjectName NVARCHAR(100),
    PermissionName NVARCHAR(200),
    StateDesc NVARCHAR(100)
);

DECLARE @DatabaseName NVARCHAR(128);
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases WITH (NOLOCK)
WHERE database_id > 4-- Exclude system databases
OPTION (RECOMPILE);

OPEN db_cursor;

FETCH NEXT FROM db_cursor INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @SqlStatement2 NVARCHAR(1000) =
        N'USE ' + QUOTENAME(@DatabaseName) + ';
        INSERT INTO #PermissionResult (UserN, DatabaseName, ObjectName, PermissionName, StateDesc)
        SELECT
			dp.name,
            DB_NAME(),
            OBJECT_NAME(major_id),
            perm.permission_name,
            perm.state_desc
        FROM sys.database_permissions AS perm WITH (NOLOCK)
        INNER JOIN sys.database_principals AS dp WITH (NOLOCK)
            ON perm.grantee_principal_id = dp.principal_id
        WHERE dp.name IN (''public'', ''guest'')
		AND perm.permission_name NOT IN (''CONNECT'',''SELECT'')
		AND perm.state_desc != ''DENY''
		OPTION (RECOMPILE)';

    EXEC sp_executesql @SqlStatement2;
    FETCH NEXT FROM db_cursor INTO @DatabaseName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

DECLARE @PublicPermissionsDB NVARCHAR(MAX) = '';
SELECT @PublicPermissionsDB = @PublicPermissionsDB + UserN  + ' - '
+ DatabaseName + ' - ' +  PermissionName + ' - ' +  StateDesc + ' | '
FROM #PermissionResult 
WHERE UserN = 'public'

IF @PublicPermissionsDB = ''
BEGIN
    SET @PublicPermissionsDB = 'Public has only connect & select permissions';
END

DECLARE @GuestPermissionsDB NVARCHAR(MAX) = '';
SELECT @GuestPermissionsDB = @GuestPermissionsDB + UserN  + ' - ' + DatabaseName + ' - ' 
+  PermissionName + ' - ' +  StateDesc + ' | ' + CHAR(13)
FROM #PermissionResult WHERE UserN = 'guest'

IF @GuestPermissionsDB = ''
BEGIN
    SET @GuestPermissionsDB = 'Guest has no permissions';
END

 DROP TABLE #PermissionResult

/* INSERT THE DIFINED VARIABLES INTO TABLE HC */

INSERT INTO @HC ([Server], 
Instance, AG, 
Edition, [Version], 
LatestPatchVersion, 
Collation, NumberOfDBs, 
				ServerMemoryGB, MaxMemorySettMB, BackupCompression, CostThreshold, [MaxDop], OptimizeAdHoc, 
				RemoteAdminConnection, SocketsCoresLogicalProcessors, LinkedServers, TraceFlags, FullBackupFreq,
				DiffBackupFreq, LogBackupFreq, IndexStatsInfo, IntegrityCheck,JobOwnedByADUser, DBOwnedByADUser,
				TempDBFiles, AutoGrowth, PageVerifyOption, AutoClose, AutoShrink, TopWaits, PLE, SQLAgentLog,
				SQLServerLog, DiskWaits15sec, OwnerOfAG, OwnerOfEndpoint, GranterOnEndpoint, AdminRolesInstance,
				PublicPermissionsInstance, PublicPermissionsDB, GuestPermissions)
SELECT 
    CONVERT(NVARCHAR, SERVERPROPERTY('ComputerNamePhysicalNetBIOS')),
    CONVERT(NVARCHAR, ISNULL(SERVERPROPERTY('InstanceName'), 'DEFAULT')), 
    CONVERT(TINYINT, SERVERPROPERTY('IsClustered')),
	CONVERT(NVARCHAR, SERVERPROPERTY('Edition')),
    CONVERT(NVARCHAR, SERVERPROPERTY('ProductVersion')), -- versions (11=2012;12=2014;13=2016;14=2017;15=2019)
   'Check in: https://sqlserverbuilds.blogspot.com/',
    CONVERT(NVARCHAR,SERVERPROPERTY('Collation')), 
    @NumberOfDBs,
    CONVERT(NVARCHAR,(SELECT FORMAT(total_physical_memory_kb/1024.0/1024.0, 'N2') FROM sys.dm_os_sys_memory)),
    CONVERT(INT, (SELECT value_in_use FROM sys.configurations WHERE name = 'max server memory (MB)')),
    CONVERT(TINYINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'backup compression default')),
    CONVERT(SMALLINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'cost threshold for parallelism')),
    CONVERT(TINYINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'max degree of parallelism')),
    CONVERT(TINYINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'optimize for ad hoc workloads')),
    CONVERT(TINYINT, (SELECT value_in_use FROM sys.configurations WHERE name = 'remote admin connections')),
	@SocketsCoresLogicalProcessors,
	@ISLINKED,
	@TraceStatus,
	@FullBackupFrequencyInDays,
	@DiffBackupFrequencyInDays,
	@LogBackupFrequencyInHours,
	'Run the query separetly',
	@DBCCInfo,
	@JobOwnedByADUser,
	@DBOwnedByADUser, 
	@TempdbFilesAmountAvgSizeAvgGrowth,
	@FileGrowth,
	@page_verify_option,
	@is_auto_close_on,
	@is_auto_shrink_on,
	@topwaits,
	@PLE,
	@agenterrors,
	@sqlerrors,
	@DiskWait15sec,
	@AGOwner,
	@AGEndpointOwner,
	@EndpointGrants,
	@AdminRolesInstance,
	@PublicPermissionsInstance,
	@PublicPermissionsDB,
	@GuestPermissionsDB


SELECT * FROM @hc




--------------------------------STATS INFO---------------------------------RUN SEPARETLLY--------------------------------------------
--IF OBJECT_ID('tempdb..#StatsLastUpdated', 'U') IS NOT NULL
--    DROP TABLE #StatsLastUpdated;
---- Create a temporary table to store the results
--CREATE TABLE #StatsLastUpdated
--(	
--	DBName NVARCHAR(128),
--    ObjectName NVARCHAR(128),
--    ObjectType NVARCHAR(128),
--    IndexName NVARCHAR(128),
--    LastUpdated NVARCHAR(128)
--);

---- Loop through each database
--DECLARE @DBName NVARCHAR(128);
--DECLARE @SQL NVARCHAR(MAX);

--DECLARE DB_CURSOR CURSOR FOR
--SELECT [name]
--FROM sys.databases WITH (NOLOCK)
--WHERE state_desc = 'ONLINE' -- Consider only online databases 
--OPTION (RECOMPILE)

--OPEN DB_CURSOR;

--FETCH NEXT FROM DB_CURSOR INTO @DBName;

--WHILE @@FETCH_STATUS = 0
--BEGIN
---- When were Statistics last updated on all indexes?  (Query 71) (Statistics Update), Glen Berry
--    SET @SQL = 'USE [' + @DBName + '];
--					SELECT SCHEMA_NAME(o.Schema_ID) + N''.'' + o.[NAME] AS [Object Name], o.[type_desc] AS [Object Type],
--						  i.[name] AS [Index Name], STATS_DATE(i.[object_id], i.index_id) AS [Stats Update]
--					FROM sys.objects AS o WITH (NOLOCK)
--					INNER JOIN sys.indexes AS i WITH (NOLOCK)
--					ON o.[object_id] = i.[object_id]
--					INNER JOIN sys.stats AS s WITH (NOLOCK)
--					ON i.[object_id] = s.[object_id] 
--					AND i.index_id = s.stats_id
--					WHERE o.[type] IN (''U'', ''V'')
--					ORDER BY STATS_DATE(i.[object_id], i.index_id) DESC OPTION (RECOMPILE);';

----table variable to hold data about last update stats
--DECLARE @StatsInfoTable TABLE (
--   ObjectName NVARCHAR(128),
--    ObjectType NVARCHAR(128),
--    IndexName NVARCHAR(128),
--    LastUpdated NVARCHAR(128));

--INSERT INTO @StatsInfoTable
--EXEC sp_executesql @SQL;

----include respective db name into temporary table
--INSERT INTO #StatsLastUpdated (DBName, ObjectName, ObjectType, IndexName, LastUpdated)
--SELECT  @DBName, ObjectName, ObjectType, IndexName, CASE WHEN LastUpdated IS NULL THEN 'statistics blob not created' ELSE LastUpdated END 
--FROM @StatsInfoTable;

--    FETCH NEXT FROM DB_CURSOR INTO @DBName;
--END;

--CLOSE DB_CURSOR;
--DEALLOCATE DB_CURSOR;

----Select the results
--DECLARE @IndexStatsInfosInfo NVARCHAR(MAX) = '';
--SELECT @IndexStatsInfosInfo = @IndexStatsInfosInfo + DBName + ' - ' + ObjectName + ' - ' + ObjectType + ' - ' + 
--IndexName + ' - ' +  LastUpdated  + ' | '+ CHAR(13)
--FROM #StatsLastUpdated
--WHERE DBName NOT IN ('master', 'model', 'msdb', 'tempdb')
--ORDER BY DBName DESC, LastUpdated DESC

--DROP TABLE #StatsLastUpdated

---------------------------------------------COPY & PASTE IN A SPERATE QUERY SESSION AND RUN------------------------------