USE [msdb]
GO
-- replace JOB_Name & AG_Name
EXEC msdb.dbo.sp_add_jobstep @job_name=N'JOB_Name', @step_name=N'AG_Primary_or_secondary', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=1, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF 
 (select role_desc from sys.dm_hadr_availability_replica_states
where group_id = (select m.ag_id from sys.dm_hadr_name_id_map m where m.ag_name = N''AG_Name'' )
AND is_local = 1
) = N''PRIMARY''
SELECT ''PRIMARY, please execute job''
ELSE
RAISERROR (''SECONDARY, do not execute'', 16,1)', 
		@database_name=N'master', 
		@flags=0
GO
