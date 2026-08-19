USE [AdventureWorks2014];
GO


/*
	DBCC HELP example
*/
DBCC HELP(CHECKDB);
GO


/*
	List all* DBCC commands 
*/
DBCC HELP ('?');
GO


/*
	Cannot view syntax for undocumented commands
*/
DBCC HELP ('EXTENTINFO');
GO


DBCC EXTENTINFO;



/*
	List all trace flags enabled globally
*/ 
DBCC TRACESTATUS(-1); 
GO 


/*
	List all trace flags enabled just for this connection
*/
DBCC TRACESTATUS(); 
GO 


/*
	Set database to full recovery
*/
USE [master]
GO
ALTER DATABASE [AdventureWorks2014] SET RECOVERY FULL WITH NO_WAIT;
GO


/*
	Run a full backup 
*/
DECLARE @BackupPath NVARCHAR(100);
SET @BackupPath = 'C:\Backups\AW2014_' + 
	REPLACE(CONVERT(nvarchar(19),SYSDATETIME(), 126), ':','') + '.bak';

BACKUP DATABASE [AdventureWorks2014] 
	TO  DISK = @BackupPath
	WITH NOFORMAT, 
	INIT,   
	COMPRESSION,  
	STATS = 10;
GO


/*
	Run a log backup 
*/
DECLARE @BackupPath NVARCHAR(100);
SET @BackupPath = 'C:\Backups\AW2014_LOG_' + 
	REPLACE(CONVERT(nvarchar(19),SYSDATETIME(), 126), ':','') + '.trn';

BACKUP LOG [AdventureWorks2014] 
	TO  DISK = @BackupPath
	WITH NOFORMAT, 
	INIT,   
	COMPRESSION,  
	STATS = 10;
GO


/*
	Check the ERRORLOG

	Supress entries to the SQL Server error log for
	every successful backup operation (local connection)
*/
DBCC TRACEON(3226);
GO


/*
	Verify trace flag is enabled, can be done two ways
*/
DBCC TRACESTATUS(3226); 
GO 
DBCC TRACESTATUS(); 
GO 


/*
	Backup the transaction log and check the SQL Server log
	then, copy to another window and backup again,
	and verify the TF is not enabled there
*/
DECLARE @BackupPath NVARCHAR(100);
SET @BackupPath = 'C:\Backups\AW2014_LOG_' + 
	REPLACE(CONVERT(nvarchar(19),SYSDATETIME(), 126), ':','') + '.trn';

BACKUP LOG [AdventureWorks2014] 
	TO  DISK = @BackupPath
	WITH NOFORMAT, 
	INIT,   
	COMPRESSION,  
	STATS = 10;
GO

DBCC TRACESTATUS(); 
GO 


/*
	Turn off 3226 locally
*/
DBCC TRACEOFF(3226);
GO


/*
	You can supress entries to the SQL Server error log for every 
	successful backup operation globally instead.
	Realize that this will not be in effect when the instance restarts
	(better to add it as a trace flag through Configuration Manager...
	this is true for most TFs, but not all).
*/
DBCC TRACEON(3226, -1);
GO


/*
	Verify again that the trace flag is enabled
*/
DBCC TRACESTATUS(-1); 
GO 


/*
	These commands will not pick up QUERYTRACEON usage, as it's treated as a hint
	https://support.microsoft.com/en-us/kb/2801413
*/
USE [AdventureWorks2014]
GO

SELECT [h].[SalesOrderID], [d].[SalesOrderDetailID], [h].[OrderDate], [h].[CustomerID], [h].[SubTotal]
FROM [Sales].[SalesOrderHeader] [h]
JOIN [Sales].[SalesOrderDetail] [d] on [h].SalesOrderID = [d].SalesOrderID
WHERE [h].CustomerID > 100
OPTION (RECOMPILE, QUERYTRACEON 8649);
GO

DBCC TRACESTATUS(-1); 
GO 
