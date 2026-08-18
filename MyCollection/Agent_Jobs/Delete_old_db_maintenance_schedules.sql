BEGIN TRAN
DECLARE @today DATETIME
SET @today = CONVERT(date, GETDATE())

DECLARE @scheduleName NVARCHAR(100)

DECLARE scheduleCursor CURSOR FOR
SELECT name
FROM msdb.dbo.sysschedules
WHERE name LIKE 'DBA - %' --or name LIKE 'DData %'
AND date_created < '20231009'

OPEN scheduleCursor

FETCH NEXT FROM scheduleCursor INTO @scheduleName

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = @scheduleName, @force_delete = 1
    FETCH NEXT FROM scheduleCursor INTO @scheduleName
END

CLOSE scheduleCursor
DEALLOCATE scheduleCursor


--COMMIT
--ROLLBACK
--sp_WhoIsActive


--DELETE FROM msdb.dbo.sysschedules
--SELECT schedule_id, name, active_start_date, active_start_time, date_created
--FROM msdb.dbo.sysschedules
--WHERE name LIKE 'DBA - %' --or name LIKE 'DData %'
--AND date_created < '20231009'
--order by active_start_time asc

--sp_whoisactive