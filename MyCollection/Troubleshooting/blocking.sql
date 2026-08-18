--alternative 1
SELECT      db_name(r.database_id), r.session_id, r.blocking_session_id, r.cpu_time,
                         SUBSTRING(qt.text,(r.statement_start_offset/2) +1,
                         (CASE WHEN r.statement_end_offset = -1
                                                  THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
                         ELSE 
                                                  r.statement_end_offset
                         END -r.statement_start_offset)/2) AS stmt_executing,
            s.login_name, r.percent_complete, r.start_time, 
            CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
                  + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
                  + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,       dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time 
            ,CASE s.transaction_isolation_level
                         WHEN 0 THEN 'Unspecified'
                         WHEN 1 THEN 'ReadUncomitted'
                         WHEN 2 THEN 'ReadComitted'
                         WHEN 3 THEN 'Repeatable'
                         WHEN 4 THEN 'Serializable'
                         WHEN 5 THEN 'Snapshot'
            END as 'Isolation level'
            ,           s.HOST_NAME,             s.PROGRAM_NAME,          s.host_process_id, 
            r.status,   r.wait_time, wait_type, r.wait_resource,
            r.total_elapsed_time,r.reads,r.writes, r.logical_reads, r.plan_handle
            --Comment out below if you don't need the plan
            , (select query_plan from sys.dm_exec_query_plan(r.plan_handle)) as xml_plan
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(sql_handle) as qt, 
                                     sys.dm_exec_sessions s
WHERE r.session_id > 50 
and r.session_id=s.session_id
and r.session_id <> @@SPID
ORDER BY r.cpu_time desc

--alternative 2
--View Blocking in Current Database 
--Author: Timothy Ford 
--http://thesqlagentman.com 
--============================================ 
SELECT DTL.resource_type,  
   CASE   
       WHEN DTL.resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN DTL.resource_type  
       WHEN DTL.resource_type = 'OBJECT' THEN OBJECT_NAME(DTL.resource_associated_entity_id)  
       WHEN DTL.resource_type IN ('KEY', 'PAGE', 'RID') THEN   
           (  
           SELECT OBJECT_NAME([object_id])  
           FROM sys.partitions  
           WHERE sys.partitions.hobt_id =   
           DTL.resource_associated_entity_id  
           )  
       ELSE 'Unidentified'  
   END AS requested_object_name, DTL.request_mode, DTL.request_status,    
   DOWT.wait_duration_ms, DOWT.wait_type, DOWT.session_id AS [blocked_session_id],  
   sp_blocked.[loginame] AS [blocked_user], DEST_blocked.[text] AS [blocked_command], 
   DOWT.blocking_session_id, sp_blocking.[loginame] AS [blocking_user],  
   DEST_blocking.[text] AS [blocking_command], DOWT.resource_description     
FROM sys.dm_tran_locks DTL  
   INNER JOIN sys.dm_os_waiting_tasks DOWT   
       ON DTL.lock_owner_address = DOWT.resource_address   
   INNER JOIN sys.sysprocesses sp_blocked  
       ON DOWT.[session_id] = sp_blocked.[spid] 
   INNER JOIN sys.sysprocesses sp_blocking  
       ON DOWT.[blocking_session_id] = sp_blocking.[spid] 
   CROSS APPLY sys.[dm_exec_sql_text](sp_blocked.[sql_handle]) AS DEST_blocked 
   CROSS APPLY sys.[dm_exec_sql_text](sp_blocking.[sql_handle]) AS DEST_blocking 
WHERE DTL.[resource_database_id] = DB_ID()

--ALTERNATIVE 3
WITH [Blocking]
AS (SELECT w.[session_id]
   ,s.[original_login_name]
   ,s.[login_name]
   ,w.[wait_duration_ms]
   ,w.[wait_type]
   ,r.[status]
   ,r.[wait_resource]
   ,w.[resource_description]
   ,s.[program_name]
   ,w.[blocking_session_id]
   ,s.[host_name]
   ,r.[command]
   ,r.[percent_complete]
   ,r.[cpu_time]
   ,r.[total_elapsed_time]
   ,r.[reads]
   ,r.[writes]
   ,r.[logical_reads]
   ,r.[row_count]
   ,q.[text]
   ,q.[dbid]
   ,p.[query_plan]
   ,r.[plan_handle]
 FROM [sys].[dm_os_waiting_tasks] w
 INNER JOIN [sys].[dm_exec_sessions] s ON w.[session_id] = s.[session_id]
 INNER JOIN [sys].[dm_exec_requests] r ON s.[session_id] = r.[session_id]
 CROSS APPLY [sys].[dm_exec_sql_text](r.[plan_handle]) q
 CROSS APPLY [sys].[dm_exec_query_plan](r.[plan_handle]) p
 WHERE w.[session_id] > 50
  AND w.[wait_type] NOT IN ('DBMIRROR_DBM_EVENT'
      ,'ASYNC_NETWORK_IO'))
SELECT b.[session_id] AS [WaitingSessionID]
      ,b.[blocking_session_id] AS [BlockingSessionID]
      ,b.[login_name] AS [WaitingUserSessionLogin]
      ,s1.[login_name] AS [BlockingUserSessionLogin]
      ,b.[original_login_name] AS [WaitingUserConnectionLogin] 
      ,s1.[original_login_name] AS [BlockingSessionConnectionLogin]
      ,b.[wait_duration_ms] AS [WaitDuration]
      ,b.[wait_type] AS [WaitType]
      ,t.[request_mode] AS [WaitRequestMode]
      ,UPPER(b.[status]) AS [WaitingProcessStatus]
      ,UPPER(s1.[status]) AS [BlockingSessionStatus]
      ,b.[wait_resource] AS [WaitResource]
      ,t.[resource_type] AS [WaitResourceType]
      ,t.[resource_database_id] AS [WaitResourceDatabaseID]
      ,DB_NAME(t.[resource_database_id]) AS [WaitResourceDatabaseName]
      ,b.[resource_description] AS [WaitResourceDescription]
      ,b.[program_name] AS [WaitingSessionProgramName]
      ,s1.[program_name] AS [BlockingSessionProgramName]
      ,b.[host_name] AS [WaitingHost]
      ,s1.[host_name] AS [BlockingHost]
      ,b.[command] AS [WaitingCommandType]
      ,b.[text] AS [WaitingCommandText]
      ,b.[row_count] AS [WaitingCommandRowCount]
      ,b.[percent_complete] AS [WaitingCommandPercentComplete]
      ,b.[cpu_time] AS [WaitingCommandCPUTime]
      ,b.[total_elapsed_time] AS [WaitingCommandTotalElapsedTime]
      ,b.[reads] AS [WaitingCommandReads]
      ,b.[writes] AS [WaitingCommandWrites]
      ,b.[logical_reads] AS [WaitingCommandLogicalReads]
      ,b.[query_plan] AS [WaitingCommandQueryPlan]
      ,b.[plan_handle] AS [WaitingCommandPlanHandle]
FROM [Blocking] b
INNER JOIN [sys].[dm_exec_sessions] s1
ON b.[blocking_session_id] = s1.[session_id]
INNER JOIN [sys].[dm_tran_locks] t
ON t.[request_session_id] = b.[session_id]
WHERE t.[request_status] = 'WAIT'
GO