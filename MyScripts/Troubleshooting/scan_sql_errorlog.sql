DROP TABLE IF EXISTS #errorLog;  -- this is new syntax in SQL 2016 and later
CREATE TABLE #errorLog (LogDate DATETIME, ProcessInfo VARCHAR(64), [Text] VARCHAR(MAX));

INSERT INTO #errorLog
EXEC sp_readerrorlog  -- specify the log number or use nothing for active error log

SELECT *
FROM #errorLog a
WHERE EXISTS (SELECT * 
              FROM #errorLog b
              WHERE [Text] like 'dbcc%'
                AND a.LogDate = b.LogDate
                AND a.ProcessInfo = b.ProcessInfo
				)
AND a.LogDate > DATEADD(dd, -4, GETDATE())
and [Text] not like '%found 0 errors and repaired 0 errors%'
