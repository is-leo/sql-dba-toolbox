SELECT 
    j.name AS 'JobName',
    msdb.dbo.agent_datetime(run_date, run_time) AS 'StartTime',
    DATEADD(SECOND, run_duration, msdb.dbo.agent_datetime(run_date, run_time)) AS 'EndTime',
    -- Calculate RunDuration in the HH:MM:SS format
    STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS 'RunDurationSec',
	((run_duration / 10000 * 3600 + (run_duration / 100) % 100 * 60 + run_duration % 100 + 31) / 60) AS 'RunDurationMinutes'
FROM msdb.dbo.sysjobs j WITH (NOLOCK)
INNER JOIN msdb.dbo.sysjobsteps s WITH (NOLOCK)
	ON j.job_id = s.job_id
INNER JOIN msdb.dbo.sysjobhistory h WITH (NOLOCK)
	ON j.job_id = h.job_id 
    AND s.step_id = h.step_id 
    AND h.step_id <> 0
WHERE j.enabled = 1  
-- Uncomment below line to filter for specific jobs by name
AND j.name LIKE '%IntegrityCheck - USER_DATABASES%' 
-- AND j.name NOT LIKE '%DatabaseBackup - USER_DATABASES - LOG' 
-- Uncomment for date range queries
   AND msdb.dbo.agent_datetime(run_date, run_time) BETWEEN '2023-10-01 17:00:00' AND '2023-11-03 07:00:00'
ORDER BY 'RunDurationSec' DESC;
