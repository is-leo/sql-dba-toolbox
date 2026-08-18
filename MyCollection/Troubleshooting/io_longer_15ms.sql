-- Look for I/O requests taking longer than 15 seconds in the six most 
--recent SQL Server Error Logs (Query 29) (IO Warnings)

/*Finding 15 second I/O warnings in the SQL Server Error Log is useful evidence 
of poor I/O performance (which might have many different causes) Look to see 
if you see any patterns in the results (same files, same drives, same time of day, etc.)*/

CREATE TABLE #IOWarningResults(LogDate datetime, ProcessInfo sysname, LogText nvarchar(1000));

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 0, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 1, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 2, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 3, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 4, 1, N'taking longer than 15 seconds';

	INSERT INTO #IOWarningResults 
	EXEC xp_readerrorlog 5, 1, N'taking longer than 15 seconds';

SELECT LogDate, ProcessInfo, LogText
FROM #IOWarningResults
ORDER BY LogDate DESC;

DROP TABLE #IOWarningResults;