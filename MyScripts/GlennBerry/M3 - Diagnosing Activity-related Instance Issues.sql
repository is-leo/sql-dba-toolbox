-- M3 - Instance Activity Queries ***********************************************************************
-- Glenn Berry


-- Make sure you are using the correct version of these diagnostic queries for your version of SQL Server


-- Check the major product version to see if it is SQL Server 2017 CTP 1 or greater
IF NOT EXISTS (SELECT * WHERE CONVERT(varchar(128), SERVERPROPERTY('ProductVersion')) LIKE '14%')
	BEGIN
		DECLARE @ProductVersion varchar(128) = CONVERT(varchar(128), SERVERPROPERTY('ProductVersion'));
		RAISERROR ('Script does not match the ProductVersion [%s] of this instance. 
		            Many of these queries may not work on this version.' , 18 , 16 , @ProductVersion);
	END
	ELSE
		PRINT N'You have the correct major version of SQL Server for this diagnostic information script';
GO


-- SQL and OS Version information for current instance  (Query 1) (Version Info)
SELECT @@SERVERNAME AS [Server Name], @@VERSION AS [SQL Server and OS Version Info];
------


-- Hardware information from SQL Server 2017  (Query 2) (Hardware Info)
SELECT cpu_count AS [Logical CPU Count], scheduler_count, 
       (socket_count * cores_per_socket) AS [Physical Core Count], 
       socket_count AS [Socket Count], cores_per_socket, numa_node_count,
       physical_memory_kb/1024 AS [Physical Memory (MB)], 
       max_workers_count AS [Max Workers Count], 
	   affinity_type_desc AS [Affinity Type], 
       sqlserver_start_time AS [SQL Server Start Time], 
	   virtual_machine_type_desc AS [Virtual Machine Type], 
       softnuma_configuration_desc AS [Soft NUMA Configuration], 
	   sql_memory_model_desc, process_physical_affinity -- New in SQL Server 2017
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);
----
-- Gives you some good basic hardware information about your database server
-- Note: virtual_machine_type_desc of HYPERVISOR does not automatically mean 
--       you are running SQL Server inside of a VM
-- It merely indicates that you have a hypervisor running on your host
-- In NUMA systems, the memory is divided into multiple nodes, and each node is associated with a specific set of processor cores.


-- sys.dm_os_sys_info (Transact-SQL)
-- https://bit.ly/2pczOYs

-- Soft NUMA configuration was a new column for SQL Server 2016
-- OFF = Soft-NUMA feature is OFF
-- ON = SQL Server automatically determines the NUMA node sizes for Soft-NUMA
-- MANUAL = Manually configured soft-NUMA

-- Configure SQL Server to Use Soft-NUMA (SQL Server)
-- https://bit.ly/2HTpKJt

-- sql_memory_model_desc values (Added in SQL Server 2016 SP1)
-- CONVENTIONAL
-- LOCK_PAGES
-- LARGE_PAGES



-- Get Average Task Counts  (Query 3) (Avg Task Counts)
-- (run multiple times) 
SELECT AVG(current_tasks_count) AS [Avg Task Count: relates to magnitude of workload or locking/blocking], 
AVG(work_queue_count) AS [Avg Work Queue Count: reflects magnitude of workload],
AVG(runnable_tasks_count) AS [Avg Runnable Task Count: represents tasks waiting for CPU time],
AVG(pending_disk_io_count) AS [Avg Pending DiskIO Count: represents tasks waiting for I/O to complete]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255 OPTION (RECOMPILE);
------

-- Sustained values above 10 suggest further investigation in that area
-- High Avg Task Counts are often caused by blocking/deadlocking 
-- or other resource contention

-- Sustained values above 1 suggest further investigation in that area
-- High Avg Runnable Task Counts are a good sign of CPU pressure
-- High Avg Pending DiskIO Counts are a sign of disk pressure

-- How to Do Some Very Basic SQL Server Monitoring
-- https://bit.ly/2q3Btgt


-- Clear Wait Stats with this command
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

-- Isolate top waits for server instance since last restart or wait statistics clear  
-- (Query 4) (Top Waits)
WITH [Waits] 
AS (SELECT wait_type, wait_time_ms/ 1000.0 AS [WaitS],
          (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],
           signal_wait_time_ms / 1000.0 AS [SignalS],
           waiting_tasks_count AS [WaitCount],
           100.0 *  wait_time_ms / SUM (wait_time_ms) OVER() AS [Percentage],
           ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats WITH (NOLOCK)
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
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
		N'PREEMPTIVE_OS_WRITEFILE',
		N'PREEMPTIVE_XE_CALLBACKEXECUTE', N'PREEMPTIVE_XE_DISPATCHER',
		N'PREEMPTIVE_XE_GETTARGETSTATE', N'PREEMPTIVE_XE_SESSIONCOMMIT',
		N'PREEMPTIVE_XE_TARGETINIT', N'PREEMPTIVE_XE_TARGETFINALIZE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
		N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
		N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'WAIT_XTP_RECOVERY',
		N'XE_BUFFERMGR_ALLPROCESSED_EVENT', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_LIVE_TARGET_TVF', N'XE_TIMER_EVENT')
    AND waiting_tasks_count > 0)
SELECT
    MAX (W1.wait_type) AS [WaitType],
	CAST (MAX (W1.Percentage) AS DECIMAL (5,2)) AS [Wait Percentage],
	CAST ((MAX (W1.WaitS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgWait_Sec],
    CAST ((MAX (W1.ResourceS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgRes_Sec],
    CAST ((MAX (W1.SignalS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgSig_Sec], 
    CAST (MAX (W1.WaitS) AS DECIMAL (16,2)) AS [Wait_Sec],
    CAST (MAX (W1.ResourceS) AS DECIMAL (16,2)) AS [Resource_Sec],
    CAST (MAX (W1.SignalS) AS DECIMAL (16,2)) AS [Signal_Sec],
    MAX (W1.WaitCount) AS [Wait Count],
	CAST (N'https://www.sqlskills.com/help/waits/' + W1.wait_type AS XML) AS [Help/Info URL]
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.RowNum <= W1.RowNum
GROUP BY W1.RowNum, W1.wait_type
HAVING SUM (W2.Percentage) - MAX (W1.Percentage) < 99 -- percentage threshold
OPTION (RECOMPILE);
------

-- Cumulative wait stats are not as useful on an idle instance 
-- that is not under load or performance pressure

-- SQL Server Wait Types Library (Paul Randal)
-- https://bit.ly/2ePzYO2

-- The SQL Server Wait Type Repository
-- https://bit.ly/1afzfjC

-- Wait statistics, or please tell me where it hurts
-- https://bit.ly/2wsQHQE

-- SQL Server 2005 Performance Tuning using the Waits and Queues
-- https://bit.ly/1o2NFoF

-- sys.dm_os_wait_stats (Transact-SQL)
-- https://bit.ly/2Hjq9Yl



-- Detect blocking (run multiple times)  (Query 5) (Detect Blocking)
SELECT t1.resource_type AS [lock type], 
DB_NAME(resource_database_id) AS [database],
t1.resource_associated_entity_id AS [blk object],
t1.request_mode AS [lock req],										-- lock requested
t1.request_session_id AS [waiter sid],								-- spid of waiter 
t2.wait_duration_ms AS [wait time], 
(SELECT [text] FROM sys.dm_exec_requests AS r WITH (NOLOCK)         -- get sql for waiter
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) 
WHERE r.session_id = t1.request_session_id) AS [waiter_batch],
(SELECT SUBSTRING(qt.[text],r.statement_start_offset/2, 
    (CASE WHEN r.statement_end_offset = -1 
    THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
    ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
FROM sys.dm_exec_requests AS r WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(r.[sql_handle]) AS qt
WHERE r.session_id = t1.request_session_id) AS [waiter_stmt],		-- statement blocked
t2.blocking_session_id AS [blocker sid],							-- spid of blocker
(SELECT [text] FROM sys.sysprocesses AS p							-- get sql for blocker
CROSS APPLY sys.dm_exec_sql_text(p.[sql_handle]) 
WHERE p.spid = t2.blocking_session_id) AS [blocker_batch]
FROM sys.dm_tran_locks AS t1 WITH (NOLOCK)
INNER JOIN sys.dm_os_waiting_tasks AS t2 WITH (NOLOCK)
ON t1.lock_owner_address = t2.resource_address OPTION (RECOMPILE);
------

-- Helps troubleshoot blocking and deadlocking issues
-- The results will change from second to second on a busy system
-- You should run this query multiple times when you see signs of blocking



-- Get tempdb version store space usage by database (Query 6) (Version Store Space Usage)
SELECT DB_NAME(database_id) AS [Database Name],
       reserved_page_count AS [Version Store Reserved Page Count], 
	   reserved_space_kb/1024 AS [Version Store Reserved Space (MB)] 
FROM sys.dm_tran_version_store_space_usage WITH (NOLOCK) 
ORDER BY reserved_space_kb/1024 DESC OPTION (RECOMPILE);
------  

-- sys.dm_tran_version_store_space_usage (Transact-SQL)
-- https://bit.ly/2vh3Bmk




-- Get top average elapsed time (in MICROSECONDS) queries for entire instance (Query 7) (Top Avg Elapsed Time Queries)
SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name],   
qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time],
qs.min_elapsed_time, qs.max_elapsed_time, qs.last_elapsed_time,
qs.execution_count AS [Execution Count],  
qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads], 
qs.total_physical_reads/qs.execution_count AS [Avg Physical Reads], 
qs.total_worker_time/qs.execution_count AS [Avg Worker Time],
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%<MissingIndexes>%' 
THEN 1 ELSE 0 END AS [Has Missing Index],
qs.creation_time AS [Creation Time],
t.[text] AS [Complete Query Text], qp.query_plan AS [Query Plan] 
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
ORDER BY qs.total_elapsed_time/qs.execution_count DESC OPTION (RECOMPILE);
------

-- Helps you find the highest average elapsed time queries across the entire instance
-- Can also help track down parameter sniffing issues



-- Look at scalar UDF (user-defined functions) execution statistics (Query 8) (UDF Stats by DB)
SELECT TOP (25) DB_NAME(database_id) AS [Database Name], 
		   OBJECT_NAME(object_id, database_id) AS [Function Name],
		   total_worker_time, execution_count, total_elapsed_time,  
           total_elapsed_time/execution_count AS [avg_elapsed_time],  
           last_elapsed_time, last_execution_time, cached_time
FROM sys.dm_exec_function_stats WITH (NOLOCK) 
ORDER BY total_worker_time DESC OPTION (RECOMPILE);
------

-- scalar UDFs are well-known performance issue
-- sys.dm_exec_function_stats (Transact-SQL)
-- https://bit.ly/2q1Q6BM



-- Missing Indexes for all databases by Index Advantage  (Query 9) (Missing Indexes All Databases)
SELECT CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage],
FORMAT(migs.last_user_seek, 'yyyy-MM-dd HH:mm:ss') AS [last_user_seek], 
mid.[statement] AS [Database.Schema.Table],
COUNT(1) OVER(PARTITION BY mid.[statement]) AS [missing_indexes_for_table],
COUNT(1) OVER(PARTITION BY mid.[statement], equality_columns) AS [similar_missing_indexes_for_table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, 
CONVERT(decimal(18,2), migs.avg_total_user_cost) AS [avg_total_user_cost], migs.avg_user_impact 
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
ORDER BY index_advantage DESC OPTION (RECOMPILE);
------

-- Getting missing index information for all of the databases on the instance is very useful
-- Look at last user seek time, number of user seeks to help determine source and importance
-- Also look at avg_user_impact (of how cost will be reduced when index created) and avg_total_user_cost (cost of not creating the index) to help determine importance.
-- SQL Server is overly eager to add included columns, so beware
-- Do not just blindly add indexes that show up from this query!!!
-- Equality columns appear in where clause or join clauses & inequality are <, >

-- SQL Server Index Design Guide
-- https://bit.ly/2qtZr4N



-- Get a count of SQL connections by IP address (Query 10) (Connection Counts by IP Address)
SELECT ec.client_net_address, es.[program_name], es.[host_name], es.login_name, 
COUNT(ec.session_id) AS [connection count] 
FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 
ON es.session_id = ec.session_id 
GROUP BY ec.client_net_address, es.[program_name], es.[host_name], es.login_name  
ORDER BY ec.client_net_address, es.[program_name] OPTION (RECOMPILE);
------

-- This helps you figure where your database load is coming from
-- and verifies connectivity from other machines

-- Solving Connectivity errors to SQL Server
-- https://bit.ly/2EgzoD0
