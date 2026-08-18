-- Setup script for Fixing Data Purity demo.

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

-- Change the column type and rebuild the index
USE [SalesDB];
GO

ALTER TABLE [products] ALTER COLUMN [price] FLOAT;
GO
ALTER INDEX [productsPK] ON [products] REBUILD;
GO

-- What pages are there?
DBCC IND (N'SalesDB', N'Products', -1);
GO

-- Pick the page two up from the bottom
-- Check slot 23 is product ID 306
DBCC TRACEON (3604)
DBCC PAGE (N'SalesDB', 1, xxx, 3);
GO

-- Take the slot 23 offset and add 8, covert to an int
SELECT CONVERT (INT, 0xXXX + 8);
GO

-- Corrupt slot 23's float value record
ALTER DATABASE [SalesDB] SET SINGLE_USER;
GO
DBCC WRITEPAGE (N'SalesDB', 1, xxx, offset, 8, 0xFFFFFFFFFFFFFFFF);
GO
ALTER DATABASE [SalesDB] SET MULTI_USER;
GO

-- Clean the error log and suspect_pages
DELETE FROM [msdb].[dbo].[suspect_pages];
EXEC sp_cycle_errorlog;
GO