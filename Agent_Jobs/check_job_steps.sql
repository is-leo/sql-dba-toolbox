 select j.name, step_id, step_name, command
 from msdb.dbo.sysjobsteps js
 inner join
 msdb.dbo.sysjobs j
 on js.job_id=j.job_id