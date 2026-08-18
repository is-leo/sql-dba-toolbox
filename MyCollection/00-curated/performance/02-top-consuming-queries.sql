--  *_worker_time columns represent the time spent on the CPU
--  *_elapsed_time columns show the total execution time
-- A logical read occurs every time the Database Engine requests a page from the buffer 
--cache. If the page is not currently in the buffer cache, a physical read first copies the page from disk into the cache
-- check execution plans and if neccessary add index

SELECT TOP ( 10 ) 
 SUBSTRING(ST.text, ( QS.statement_start_offset / 2 ) + 1, 
 ( ( CASE statement_end_offset
 WHEN -1 THEN DATALENGTH(st.text) 
 ELSE QS.statement_end_offset
 END - QS.statement_start_offset ) / 2 ) + 1)
 AS statement_text , execution_count , 
 total_worker_time / 1000 AS total_worker_time_ms , 
 ( total_worker_time / 1000 ) / execution_count
 AS avg_worker_time_ms , 
 total_logical_reads , 
 total_logical_reads / execution_count AS avg_logical_reads , 
 total_elapsed_time / 1000 AS total_elapsed_time_ms , 
 ( total_elapsed_time / 1000 ) / execution_count
 AS avg_elapsed_time_ms , 
 qp.query_plan
FROM sys.dm_exec_query_stats qs
 CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
 CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_worker_time DESC

