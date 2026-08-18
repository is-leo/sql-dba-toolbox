--By checking only for the restore and backup command lines you will be able to quickly identify your session id
--and get an  approximate ETA and percentage complete. you can tinker of course with the estimations
--if you’d like or pull back more fields. This is just a simple technique in utilizing a helpful DMV to provide info quickly.
SELECT  r.session_id
      , r.command
      , r.start_time
      , r.status
      , CONVERT(NUMERIC(6, 2), r.percent_complete) AS [Percent Complete]
      , CONVERT(VARCHAR(20), DATEADD(ms, r.estimated_completion_time , GETDATE()), 20) AS [ETA Completion Time]
      , CONVERT(NUMERIC(10, 2), r.total_elapsed_time / 1000.0 / 60.0) AS [Elapsed Min]
      , CONVERT(NUMERIC(10, 2), r.total_elapsed_time / 1000.0 / 60.0 / 60.0) AS [Elapsed Hours]
      , CONVERT(NUMERIC(10, 2), r.estimated_completion_time / 1000.0 / 60.0) AS [ETA Min]
      , CONVERT(NUMERIC(10, 2), r.estimated_completion_time / 1000.0 / 60.0/ 60.0) AS [ETA Hours]
      , CONVERT(VARCHAR(1000), (
                 SELECT SUBSTRING(TEXT, r.statement_start_offset / 2, CASE
                             WHEN r.statement_end_offset = -1
                                 THEN 1000
                             ELSE (r.statement_end_offset - r.statement_start_offset) / 2
                             END)
                 FROM   sys.dm_exec_sql_text(sql_handle)
                 )) AS TSQLStatement
FROM sys.dm_exec_requests r
WHERE command IN (
        'RESTORE DATABASE'
        , 'BACKUP DATABASE'
        );


-- backup & restore progress

SELECT 
   session_id as SPID, 
   command, 
   a.text AS Query, 
   start_time,
   percent_complete,
   dateadd(second,
   estimated_completion_time/1000, 
   getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r 
   CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE') 

--ALTERNATIVE 1
SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete, 
  dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE r.command in ('BACKUP DATABASE', 'BACKUP LOG', 'RESTORE DATABASE', 'RESTORE HEADERONLY');


--ALTERNATIVE 2
SELECT
  r.session_id,
  r.command,CONVERT(NUMERIC(6,2),r.percent_complete) AS [Percent Complete],
  CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
  CONVERT(NUMERIC(10,2),r.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
  CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0) AS [ETA Min],
  CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours],
  CONVERT(VARCHAR(1000),
   (SELECT SUBSTRING(text,r.statement_start_offset/2,
     CASE 
      WHEN r.statement_end_offset = -1 
      THEN 1000 
      ELSE (r.statement_end_offset-r.statement_start_offset)/2 END)
     FROM sys.dm_exec_sql_text(sql_handle)))
FROM sys.dm_exec_requests r 
WHERE command IN ('BACKUP DATABASE', 'BACKUP LOG', 'RESTORE DATABASE', 'RESTORE HEADERONLY');


--ALTERNATIVE 3
USE master
GO
SELECT
   A.session_id As [Session ID]
 , login_name As [Login Name]
 , [command] As [Command]
 , [text] AS [Script]
 , [start_time] As [Start Time]
 , [percent_complete] AS [Percentage]
 , DATEADD(SECOND,estimated_completion_time/1000, GETDATE())
 as [Estimated Completion time]
 , [program_name] As [Program Name]
FROM sys.dm_exec_requests A
CROSS APPLY sys.dm_exec_sql_text(A.sql_handle) B
INNER JOIN sys.dm_exec_sessions C ON A.session_id=C.session_id
WHERE A.command in ('BACKUP DATABASE', 'BACKUP LOG', 'RESTORE DATABASE', 'RESTORE HEADERONLY')
GO

--ALTERNATIVE 4
SELECT r.session_id,r.command,CONVERT(NUMERIC(6,2),r.percent_complete)
AS [Percent Complete],CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
CONVERT(NUMERIC(10,2),r.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0) AS [ETA Min],
CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours],
CONVERT(VARCHAR(1000),(SELECT SUBSTRING(text,r.statement_start_offset/2,
CASE WHEN r.statement_end_offset = -1 THEN 1000 ELSE (r.statement_end_offset-r.statement_start_offset)/2 END)
FROM sys.dm_exec_sql_text(sql_handle)))
FROM sys.dm_exec_requests r WHERE command IN ('RESTORE DATABASE','BACKUP DATABASE','RESTORE HEADERONLY')


--ALTERNATIVE 5
SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE','RESTORE HEADERONLY') 