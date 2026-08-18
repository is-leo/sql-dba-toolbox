/*
The column "blocked" shows 0 when a SPID isn't being blocked 
and shows the blocking SPID when it is being blocked. 
This query shows all processes that are blocked or
that are blocking someone.*/

SELECT * FROM sys.sysprocesses 
WHERE blocked > 0 
  OR SPID IN (SELECT Blocked FROM sys.sysprocesses);

--check if there are any open transactions

--USE RELEVANT DB
DBCC OPENTRAN()

--RECENT EXPENSIVE QUERIES
;WITH qs AS (
  SELECT TOP 10 
    total_worker_time/execution_count AvgCPU
  , total_elapsed_time/execution_count AvgDuration
  , (total_logical_reads + total_physical_reads)/execution_count AvgReads
  , execution_count
  , sql_handle
  , plan_handle
  , statement_start_offset
  , statement_end_offset
  FROM sys.dm_exec_query_stats
  WHERE execution_count > 5
    AND min_logical_reads > 100
    AND min_worker_time > 100
  ORDER BY (total_logical_reads + total_physical_reads)/execution_count DESC)
SELECT
  AvgCPU
, AvgDuration
, AvgReads
, execution_count
 ,SUBSTRING(st.TEXT, (qs.statement_start_offset/2) + 1, 
            ((CASE qs.statement_end_offset  
                WHEN -1 THEN DATALENGTH(st.TEXT)
                ELSE qs.statement_end_offset  
              END - qs.statement_start_offset)/2) + 1) StatementText
 ,query_plan ExecutionPlan
FROM 
  qs  
    CROSS APPLY
  sys.dm_exec_sql_text(qs.sql_handle) AS st  
    CROSS APPLY
  sys.dm_exec_query_plan (qs.plan_handle) AS qp 
ORDER BY 
  AvgDuration DESC;


/*
SQL Server tracks the waits experienced by every process running on the server.
Each wait type starts at 0ms whenever the service is started and counts up from there.
To get an idea of what is going on right now, you must compare the numbers from 
one point in time to another. 
This script will do just that by comparing the DMV to a snapshot of itself from
15 seconds earlier.
*/
SELECT 
  wait_type 
, waiting_tasks_count
, signal_wait_time_ms
, wait_time_ms
, SysDateTime() AS StartTime
INTO 
  #WaitStatsBefore 
FROM 
  sys.dm_os_wait_stats 
WHERE 
  wait_type NOT IN ('SLEEP_TASK','BROKER_EVENTHANDLER','XE_DISPATCHER_WAIT','BROKER_RECEIVE_WAITFOR', 'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT','REQUEST_FOR_DEADLOCK_SEARCH','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','SQLTRACE_BUFFER_FLUSH','LAZYWRITER_SLEEP','XE_TIMER_EVENT','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','LOGMGR_QUEUE','CHECKPOINT_QUEUE', 'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'BROKER_EVENTHANDLER', 'SLEEP_TASK', 'WAITFOR', 'DBMIRROR_DBM_MUTEX', 'DBMIRROR_EVENTS_QUEUE', 'DBMIRRORING_CMD', 'DISPATCHER_QUEUE_SEMAPHORE','BROKER_RECEIVE_WAITFOR', 'CLR_AUTO_EVENT', 'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'ONDEMAND_TASK_QUEUE', 'FT_IFTSHC_MUTEX', 'CLR_MANUAL_EVENT', 'SP_SERVER_DIAGNOSTICS_SLEEP', 'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','CLR_SEMAPHORE','DBMIRROR_WORKER_QUEUE','SP_SERVER_DIAGNOSTICS_SLEEP','HADR_CLUSAPI_CALL','HADR_LOGCAPTURE_WAIT','HADR_NOTIFICATION_DEQUEUE','HADR_TIMER_TASK','HADR_WORK_QUEUE','REDO_THREAD_PENDING_WORK','UCS_SESSION_REGISTRATION','BROKER_TRANSMITTER','SLEEP_SYSTEMTASK','QDS_SHUTDOWN_QUEUE');--These are a series of irrelevant wait stats.
 
WAITFOR DELAY '00:00:15'; --15 seconds
 
SELECT 
  a.wait_type 
, a.signal_wait_time_ms - b.signal_wait_time_ms AS CPUDiff 
, (a.wait_time_ms - b.wait_time_ms) - (a.signal_wait_time_ms - b.signal_wait_time_ms) AS ResourceDiff
, a.waiting_tasks_count - b.waiting_tasks_count AS waiting_tasks_diff
, CAST(CAST(a.wait_time_ms - b.wait_time_ms AS FLOAT) / (a.waiting_tasks_count - b.waiting_tasks_count) AS DECIMAL(10,1)) AS AverageDurationMS
, a.max_wait_time_ms max_wait_all_timeMS
, DATEDIFF(ms,StartTime, SysDateTime()) AS DurationSeconds
FROM 
  sys.dm_os_wait_stats a 
    INNER JOIN 
  #WaitStatsBefore b ON a.wait_type = b.wait_type 
WHERE 
  a.signal_wait_time_ms <> b.signal_wait_time_ms
    OR 
  a.wait_time_ms <> b.wait_time_ms
ORDER BY 3 DESC;

/*
SQL Server tracks the delays it experiences when interacting with data and log files.
Like wait stats, these counters start at 0 whenever the service is started.
This next script will create a temp table to store a snapshot of the numbers,
wait 15 seconds, then see what has changed. 
I usually combine this with the wait stats query, so I only need one delay.*/
SELECT 
  b.name
, a.database_id
, a.[FILE_ID]
, a.num_of_reads
, a.num_of_bytes_read
, a.io_stall_read_ms
, a.num_of_writes
, a.num_of_bytes_written
, a.io_stall_write_ms
, a.io_stall
, GetDate() AS StartTime
INTO
  #IOStatsBefore
FROM 
  sys.dm_io_virtual_file_stats(NULL, NULL) a 
    INNER JOIN 
  sys.databases b ON a.database_id = b.database_id;
 
 
WAITFOR DELAY '00:00:5'
 
SELECT
  a.name DatabaseName
, a.[FILE_ID]
, (b.io_stall_read_ms - a.io_stall_read_ms)/ CAST(1000 as DECIMAL(10,1)) io_stall_read_Diff 
, (b.io_stall_write_ms - a.io_stall_write_ms)/ CAST(1000 as DECIMAL(10,1)) io_stall_write_Diff 
, (b.io_stall - a.io_stall)/ CAST(1000 as DECIMAL(10,1)) io_stall_Diff 
, DATEDIFF(s,StartTime, GETDATE()) AS DurationSeconds
FROM 
  #IOStatsBefore a
    INNER JOIN 
  sys.dm_io_virtual_file_stats(NULL, NULL) b ON a.database_id = b.database_id AND a.[file_id] = b.[file_id]
ORDER BY
  a.name
, a.[FILE_ID];

drop table #IOStatsBefore

/*
SQL Server natively tracks the CPU utilization history of an instance 
once per minute for the last 250 minutes. You can get those readings
using the following query. If performance is off, compare the last
30 minutes to the 220 before it to see if CPU utilization has increased
while the users complained of performance issues.
*/
;WITH XMLRecords AS (
SELECT 
         DATEADD (ms, r.[timestamp] - sys.ms_ticks,SYSDATETIME()) AS record_time
       , CAST(r.record AS XML) record
       FROM 
         sys.dm_os_ring_buffers r  
           CROSS JOIN 
         sys.dm_os_sys_info sys  
       WHERE   
         ring_buffer_type='RING_BUFFER_SCHEDULER_MONITOR' 
 [Person].[EmailAddress]          AND 
         record LIKE '%<SystemHealth>%')
 SELECT 
   100-record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemUtilization
 , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization
 , record_time
 FROM XMLRecords;

 /*
Use the following query to record the page life expectancy of 
the SQL Server. If you use named instances, your object_name column
will need to be modified with the instance name in place of "SQLServer."
Remember -- Bigger is better with page life expectancy, but without
a baseline, it's hard to tell what is good versus bad for you.
*/

SELECT  
  LEFT(counter_name, 25) CounterName
, CASE counter_name 
    WHEN 'Stolen pages' THEN cntr_value/128 --8kb pages/128 = MB 
    WHEN 'Stolen Server Memory (KB)' THEN cntr_value/1024 --kb/1024 = MB 
    ELSE cntr_value
  END CounterValue_converted_to_MB
FROM 
  sys.dm_os_performance_counters
WHERE 
  OBJECT_NAME = N'SQLServer:Buffer Manager' 
    AND 
  counter_name = 'Page life expectancy';

--DISK CAPACITY
SELECT DISTINCT 
  vs.volume_mount_point Drive
, vs.logical_volume_name
, vs.total_bytes/1024/1024/1024 CapacityGB
, vs.available_bytes/1024/1024/1024 FreeGB
, CAST(vs.available_bytes * 100. / vs.total_bytes AS DECIMAL(4,1)) FreePct 
FROM 
  sys.master_files mf
    CROSS APPLY 
  sys.dm_os_volume_stats(mf.database_id, mf.file_id) AS vs;


--WAITS TYPES, since the last SQL Server services restart
WITH Waits AS 
 ( 
 SELECT  
   wait_type,  
   wait_time_ms / 1000. AS wait_time_s, 
   100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct, 
   ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn 
 FROM sys.dm_os_wait_stats 
 WHERE wait_type  
   NOT IN 
     ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
   'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
   'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT') 
   ) -- filter out additional irrelevant waits 
    
SELECT W1.wait_type, 
 CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s, 
 CAST(W1.pct AS DECIMAL(12, 2)) AS pct, 
 CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct 
FROM Waits AS W1 
 INNER JOIN Waits AS W2 ON W2.rn <= W1.rn 
GROUP BY W1.rn,  
 W1.wait_type,  
 W1.wait_time_s,  
 W1.pct 
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold;


-- TO COLLECT WAITS IN A TABLE 
USE DBA; 
--Create table to persist wait stats information: 

CREATE TABLE dbo.dm_os_wait_stats 
( 
 [wait_type] [nvarchar](60) NOT NULL, 
 [waiting_tasks_count] [bigint] NOT NULL, 
 [wait_time_ms] [bigint] NOT NULL, 
 [max_wait_time_ms] [bigint] NOT NULL, 
 [signal_wait_time_ms] [bigint] NOT NULL, 
 [capture_time] [datetime] NOT NULL, 
 [increment_id] [int] NOT NULL 
); 

ALTER TABLE dbo.dm_os_wait_stats  
 ADD  DEFAULT (GETDATE()) FOR [capture_time]; 

--Insert wait stats info in a datestamped format for later querying: 
DECLARE @DT DATETIME ; 
SET @DT = GETDATE() ; 
DECLARE @increment_id INT; 

SELECT @increment_id = MAX(increment_id) + 1 FROM dbo.dm_os_wait_stats; 
SELECT @increment_id = ISNULL(@increment_id, 1) 
  

INSERT INTO DBA.dbo.dm_os_wait_stats 
 ([wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], 
 [signal_wait_time_ms], [capture_time], [increment_id]) 
SELECT [wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms],  
 [signal_wait_time_ms], @DT, @increment_id 
FROM sys.dm_os_wait_stats;

--QUERY THE TABLE
--Return persisted information from table 
USE [DBA]; 

DECLARE @max_increment_id INT 

------------------------------------------------------------------ 
--Determine most-recent increment_id 
------------------------------------------------------------------ 
SELECT @max_increment_id = MAX(increment_id) 
FROM dbo.dm_os_wait_stats 
    
------------------------------------------------------------------ 
--Present Waits results for period 
------------------------------------------------------------------ 
SELECT DOWS1.wait_type,  
 (DOWS1.waiting_tasks_count - DOWS2.waiting_tasks_count) AS [waiting_tasks_count], 
 (DOWS1.wait_time_ms - DOWS2.wait_time_ms) AS [wait_time_ms], 
 DOWS1.max_wait_time_ms,  
 (DOWS1.signal_wait_time_ms - DOWS2.signal_wait_time_ms) AS [signal_wait_time_ms], 
 DATEDIFF(ms, DOWS2.capture_time, DOWS1.capture_time) AS [elapsed_time_ms], 
 DOWS1.capture_time AS [last_time_stamp], DOWS2.capture_time AS [previous_time_stamp] 
FROM  
 ( 
 SELECT  wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, 
         signal_wait_time_ms, capture_time, increment_id 
 FROM dbo.dm_os_wait_stats 
 WHERE increment_id = @max_increment_id 
 )AS DOWS1  
 INNER JOIN  
 ( 
 SELECT  wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, 
         signal_wait_time_ms, capture_time, increment_id 
 FROM dbo.dm_os_wait_stats 
 WHERE increment_id = (@max_increment_id - 1) 
 )AS DOWS2 ON DOWS1.wait_type = DOWS2.wait_type 
WHERE (DOWS1.wait_time_ms - DOWS2.wait_time_ms) > 0  
 /* 
 This can technically be eliminated because we're not persisting these waits: 
 AND DOWS1.wait_type NOT IN  
   ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
   'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
   'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT') 
 */ 
ORDER BY (DOWS1.wait_time_ms - DOWS2.wait_time_ms) DESC

--QUERY THE TABLE 2

--Return persisted information from table 
USE [DBA]; 

DECLARE @max_increment_id INT 

------------------------------------------------------------------ 
--Determine most-recent increment_id 
------------------------------------------------------------------ 
SELECT @max_increment_id = MAX(increment_id) 
FROM dbo.dm_os_wait_stats 
    
------------------------------------------------------------------ 
--Present Waits results for period 
------------------------------------------------------------------ 
SELECT DOWS1.wait_type,  
 (DOWS1.waiting_tasks_count - DOWS2.waiting_tasks_count) AS [waiting_tasks_count], 
 (DOWS1.wait_time_ms - DOWS2.wait_time_ms) AS [wait_time_ms], 
 DOWS1.max_wait_time_ms,  
 (DOWS1.signal_wait_time_ms - DOWS2.signal_wait_time_ms) AS [signal_wait_time_ms], 
 DATEDIFF(ms, DOWS2.capture_time, DOWS1.capture_time) AS [elapsed_time_ms], 
 DOWS1.capture_time AS [last_time_stamp], DOWS2.capture_time AS [previous_time_stamp] 
FROM  
 ( 
 SELECT  wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, 
         signal_wait_time_ms, capture_time, increment_id 
 FROM dbo.dm_os_wait_stats 
 WHERE increment_id = @max_increment_id 
 )AS DOWS1  
 INNER JOIN  
 ( 
 SELECT  wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, 
         signal_wait_time_ms, capture_time, increment_id 
 FROM dbo.dm_os_wait_stats 
 WHERE increment_id = (@max_increment_id - 1) 
 )AS DOWS2 ON DOWS1.wait_type = DOWS2.wait_type 
WHERE (DOWS1.wait_time_ms - DOWS2.wait_time_ms) > 0  
 /* 
 This can technically be eliminated because we're not persisting these waits: 
 AND DOWS1.wait_type NOT IN  
   ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 
   'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 
   'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT') 
 */ 
ORDER BY (DOWS1.wait_time_ms - DOWS2.wait_time_ms) DESC;