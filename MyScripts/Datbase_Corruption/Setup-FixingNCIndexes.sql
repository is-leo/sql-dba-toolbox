-- Setup script for Fixing Nonclustered Indexes demo.

-- Demo databases can be downloaded from
-- http://bit.ly/10fKpbS (that's a zero).

-- This setup script uses the undocumented DBCC WRITEPAGE
-- command to cause corruption. This command is explained
-- in detail in Module 3 of the course SQL Server: Advanced
-- Corruption Recovery Techniques.

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
FROM DISK = N'D:\Pluralsight\SalesDBOriginal.bak'
WITH
    MOVE N'SalesDBData' TO N'D:\Pluralsight\SalesDB.mdf',
	MOVE N'SalesDBLog' TO N'D:\Pluralsight\SalesDB.ldf';
GO

USE [SalesDB];
GO

-- Create the index we're going to break
CREATE NONCLUSTERED INDEX [CustomerName]
ON [Customers] ([LastName]);

-- What's the index ID?
SELECT
	[index_id]
FROM
	sys.indexes
WHERE
	[name] = N'CustomerName'
	AND [object_id] = OBJECT_ID (N'Customers');
GO

-- List the pages in the index
DBCC IND (N'SalesDB', N'Customers', 2);
GO

-- Corrupt some records
ALTER DATABASE [SalesDB] SET SINGLE_USER;
GO
DBCC WRITEPAGE (N'SalesDB', 1, 24600, 134, 1, 0x64);
DBCC WRITEPAGE (N'SalesDB', 1, 24600, 196, 1, 0x70);
DBCC WRITEPAGE (N'SalesDB', 1, 24600, 2396, 1, 0x74);
DBCC WRITEPAGE (N'SalesDB', 1, 24600, 2698, 1, 0x74);
DBCC WRITEPAGE (N'SalesDB', 1, 24600, 2748, 1, 0x70);
GO
ALTER DATABASE [SalesDB] SET MULTI_USER;
GO

-- Clean the error log and suspect_pages
DELETE FROM [msdb].[dbo].[suspect_pages];
EXEC sp_cycle_errorlog;
GO