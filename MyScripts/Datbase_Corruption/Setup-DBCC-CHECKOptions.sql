 -- Setup script for DBCC CHECK* Options demo.

-- Demo databases can be downloaded from
-- http://bit.ly/10fKpbS (that's a zero).

-- Download the 2008 SalesDB Sample Database from the link above
-- and unzip into D:\Pluralsight.

-- Restore as follows:
USE [master];
GO

IF DATABASEPROPERTYEX (N'SalesDB', N'Version') > 0
BEGIN
	ALTER DATABASE [SalesDB] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [SalesDB];
END
GO

RESTORE DATABASE [SalesDB]
FROM DISK = N'C:\Pluralsight\SalesDBOriginal.bak'
WITH
    MOVE N'SalesDBData' TO N'c:\Pluralsight\SalesDB.mdf',
	MOVE N'SalesDBLog' TO N'c:\Pluralsight\SalesDB_log.ldf';
GO

