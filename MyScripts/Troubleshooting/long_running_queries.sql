--LONG RUNNING QUERIES
SELECT 	db_name(r.database_id), r.session_id, r.blocking_session_id, r.cpu_time,
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
	,	s.HOST_NAME, 	s.PROGRAM_NAME,	s.host_process_id, 
	r.status, 	r.wait_time,	wait_type, 	r.wait_resource,
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
