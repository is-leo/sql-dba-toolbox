-- DISABLE & RENAME JOBS 

DECLARE @SQLStatement VARCHAR(200)
DECLARE @jobName SYSNAME
DECLARE c1 CURSOR FOR
SELECT name FROM msdb.dbo.sysjobs_view 
WHERE name LIKE 'DBA - %' or name LIKE 'DData %'
OPEN c1
FETCH NEXT FROM c1 INTO @jobName
IF @@CURSOR_ROWS = 0
    PRINT 'No Job found! Please re-check LIKE operator.'
WHILE @@fetch_status = 0
BEGIN
    -- Disable the job before renaming it
    SET @SQLStatement = 'EXEC msdb.dbo.sp_update_job @job_name =''' + @jobName + ''', @enabled = 0'
    PRINT(@SQLStatement)
    EXEC (@SQLStatement)   -- Uncomment to Execute (disable the job)

    -- Rename the job
    SET @SQLStatement = 'EXEC msdb.dbo.sp_update_job @job_name =''' + @jobName + ''', @new_name =''OLD_' + @jobName + ''''
    PRINT(@SQLStatement)
    EXEC (@SQLStatement)   -- Uncomment to Execute (rename the job)

    FETCH NEXT FROM c1 INTO @jobName
END
CLOSE c1
DEALLOCATE c1


--sp_whoisactive