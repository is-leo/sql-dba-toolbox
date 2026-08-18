--os perfmormance counters
select * from sys.dm_os_performance_counters

--active sessions and slow queries 
SELECT sqltext.TEXT,
req.session_id,
req.status,
req.command,
req.cpu_time,req.database_id,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext 
WHERE sqltext.text like '%Your Target Key Word%'


SELECT
r.session_id,
s.TEXT,
r.[status],
r.blocking_session_id,
r.cpu_time,
r.total_elapsed_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s

 --sleeping user sessions that have been idle for over 15 minutes 
SELECT CURRENT_TIMESTAMP as currenttime, 
datediff(minute,last_batch,GETDATE()) as 'idletime_in_minute',
sp.status,sp.spid,sp.login_time,sp.program_name,sp.hostprocess,
sp.loginame,text FROM sys.sysprocesses sp 
CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) AS QT 
where sp.status = 'sleeping' and datediff(minute,last_batch,GETDATE()) >15 and spid>50

-- top 10 high memory usage queries that currently running in this SQL instance
SELECT mg.session_id, mg.granted_memory_kb, mg.requested_memory_kb, mg.ideal_memory_kb,
mg.request_time, mg.grant_time, mg.query_cost, mg.dop,st.[TEXT], qp.query_plan
FROM sys.dm_exec_query_memory_grants AS mg 
CROSS APPLY sys.dm_exec_sql_text(mg.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp 
ORDER BY mg.required_memory_kb DESC

--last execution plan for all cached queries as shown below:
SELECT *
FROM sys.dm_exec_cached_plans AS cp
    CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
    CROSS APPLY sys.dm_exec_query_plan_stats(plan_handle) AS qps; 
GO

--helps to identify active transactions that may be preventing log truncation.
DBCC opentran

--enable query store
ALTER DATABASE < database_name> SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);

-- to force a specific plan
EXEC sp_query_store_force_plan @query_id=73, @plan_id=79

--missing index
select * from sys.dm_db_index_physical_stats 
select * from sys.dm_db_missing_index_details
select * from sys.dm_db_index_usage_stats
select * from sys.dm_db_index_operational_stats -- Returns current lower-level I/O, locking, latching, and access method activity 
--for each partition of a table or index in the database.

select * from sys.dm_db_missing_index_group_stats
select * from sys.dm_db_missing_index_group_stats_query--Returns information about queries that needed a missing index from groups of missing indexes,
-- last time stas updtd
select * from sys.dm_db_stats_properties

--To see a text-based estimated plan
SET SHOWPLAN_ALL ON 

-- top 10 Active CPU Consuming Queries (aggregated)--';
SELECT TOP 10 GETDATE() runtime, *
FROM (SELECT query_stats.query_hash, SUM(query_stats.cpu_time) 'Total_Request_Cpu_Time_Ms', SUM(logical_reads) 'Total_Request_Logical_Reads', MIN(start_time) 'Earliest_Request_start_Time', COUNT(*) 'Number_Of_Requests', SUBSTRING(REPLACE(REPLACE(MIN(query_stats.statement_text), CHAR(10), ' '), CHAR(13), ' '), 1, 256) AS "Statement_Text"
    FROM (SELECT req.*, SUBSTRING(ST.text, (req.statement_start_offset / 2)+1, ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(ST.text)ELSE req.statement_end_offset END-req.statement_start_offset)/ 2)+1) AS statement_text
          FROM sys.dm_exec_requests AS req
                CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS ST ) AS query_stats
    GROUP BY query_hash) AS t
ORDER BY Total_Request_Cpu_Time_Ms DESC;

--top 10 Active CPU Consuming Queries by sessions--';
SELECT TOP 10 req.session_id, req.start_time, cpu_time 'cpu_time_ms', OBJECT_NAME(ST.objectid, ST.dbid) 'ObjectName', SUBSTRING(REPLACE(REPLACE(SUBSTRING(ST.text, (req.statement_start_offset / 2)+1, ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(ST.text)ELSE req.statement_end_offset END-req.statement_start_offset)/ 2)+1), CHAR(10), ' '), CHAR(13), ' '), 1, 512) AS statement_text
FROM sys.dm_exec_requests AS req
    CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS ST
ORDER BY cpu_time DESC;
GO

--fragmentation
SELECT i.name Index_Name
 , avg_fragmentation_in_percent
 , db_name(database_id)
 , i.object_id 
 , i.index_id
 , index_type_desc
FROM sys.dm_db_index_physical_stats(db_id('AdventureWorks2017'),object_id('person.address'),NULL,NULL,'DETAILED') ps
 INNER JOIN sys.indexes i ON ps.object_id = i.object_id 
 AND ps.index_id = i.index_id
order by avg_fragmentation_in_percent desc

--analyze indexes
select * from sys.dm_db_index_usage_stats
select * from sys.dm_db_index_operational_stats( NULL, NULL, NULL, NULL)
DBCC SHOWCONTIG

-- updates all stats on the server
Sp_updatestats

--To monitor open transactions awaiting commit or rollback run the following query
SELECT tst.session_id, [database_name] = db_name(s.database_id)
    , tat.transaction_begin_time
    , transaction_duration_s = datediff(s, tat.transaction_begin_time, sysdatetime()) 
    , transaction_type = CASE tat.transaction_type  WHEN 1 THEN 'Read/write transaction'
        WHEN 2 THEN 'Read-only transaction'
        WHEN 3 THEN 'System transaction'
        WHEN 4 THEN 'Distributed transaction' END
    , input_buffer = ib.event_info, tat.transaction_uow     
    , transaction_state  = CASE tat.transaction_state    
        WHEN 0 THEN 'The transaction has not been completely initialized yet.'
        WHEN 1 THEN 'The transaction has been initialized but has not started.'
        WHEN 2 THEN 'The transaction is active - has not been committed or rolled back.'
        WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
        WHEN 4 THEN 'The commit process has been initiated on the distributed transaction.'
        WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
        WHEN 6 THEN 'The transaction has been committed.'
        WHEN 7 THEN 'The transaction is being rolled back.'
        WHEN 8 THEN 'The transaction has been rolled back.' END 
    , transaction_name = tat.name, request_status = r.status
    , tst.is_user_transaction, tst.is_local
    , session_open_transaction_count = tst.open_transaction_count  
    , s.host_name, s.program_name, s.client_interface_name, s.login_name, s.is_user_process
FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN Sys.dm_exec_sessions s on s.session_id = tst.session_id 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
CROSS APPLY sys.dm_exec_input_buffer(s.session_id, null) AS ib
ORDER BY tat.transaction_begin_time DESC;


-- extended event to track blockings 
USE MASTER
GO

CREATE EVENT SESSION [Blocking] ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

-- Start the event session 
ALTER EVENT SESSION [Blocking] ON SERVER 
STATE = start; 
GO

/* 
The above T-SQL code will create an Extended Event session that will capture blocking events. 
The data will contain the following elements:

Client application name
Client host name
Database ID
Database name
NT Username
Session ID
T-SQL Text
Username
*/

select * from sys.query_store_query_text
--db lever configurations
select * from sys.database_scoped_configurations
--server lever configurations
select * from sys.configurations

-- if you think tasks waiting for tempdb

select * from sys.dm_exec_requests
select * from sys.dm_os_waiting_tasks

/*
Whether on-premises or in the cloud, automatic tuning allows you to identify 
issues caused by query execution plan regression.
Additionally, in Azure SQL Database you can improve query performance by index tuning. */

ALTER DATABASE [AdventureWorks2017] SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON);

--Check recommendations
select * from sys.dm_db_tuning_recommendations
--Check if enabled 
select * from sys.database_automatic_tuning_options

-- Get VLF Counts for all databases on the instance (Query 34) (VLF Counts)
SELECT db.[name] AS [Database Name], li.[VLF Count]
FROM sys.databases AS db WITH (NOLOCK)
CROSS APPLY (SELECT file_id, COUNT(*) AS [VLF Count]
             FROM sys.dm_db_log_info (db.database_id)
	     GROUP BY file_id) AS li
ORDER BY li.[VLF Count] DESC OPTION (RECOMPILE);