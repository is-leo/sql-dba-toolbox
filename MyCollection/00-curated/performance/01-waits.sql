/* FELSÖKNING METOD 
1. Look at the wait stats. (ex. high PAGEIOLATCH_SH = IO issue)
2. Validate any possible issue with other methods: dmvs & perfmon counters
3. Idnetify & adress queries causing high IO  

The cause and length of the various waits that SQL Server is experiencing
can provide significant insight into the cause of the performance problems, 
as long as you understand exactly what the wait statistics are telling you, 
and know how to correlate the wait information with the additional troubleshooting
information such as the PerfMon counters, and other DMVs.
Waits can be resource  (i.e. traceable to a hardware resource) and non-resource.
*/

select * from sys.dm_os_wait_stats 
order by waiting_tasks_count  desc-- wait stats, aggregated across all sessions since last restart or last clear DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR)

select * from sys.dm_exec_session_wait_stats -- active waiting sessions 

--Azure SQL DB & MI
select * from sys.dm_db_wait_stats -- azure sql db returns information about all the waits encountered by threads 
select * from sys.dm_db_resource_stats -- returns CPU, I/O, and memory consumption

--see system (non-problematic) waits 
SELECT DISTINCT
 wt.wait_type
FROM sys.dm_os_waiting_tasks AS wt
 JOIN sys.dm_exec_sessions AS s ON wt.session_id = s.session_id
WHERE s.is_user_process = 0


select * from sys.dm_exec_requests

-- top 10 missing idexes with the highest anticipated improvement for user queries
select top 10 *
from sys.dm_db_missing_index_group_stats
order by avg_total_user_cost * avg_user_impact *(user_seeks + user_scans) desc;