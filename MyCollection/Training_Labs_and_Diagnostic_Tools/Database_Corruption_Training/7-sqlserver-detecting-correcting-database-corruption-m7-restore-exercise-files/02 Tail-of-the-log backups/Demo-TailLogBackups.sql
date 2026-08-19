-- Demo script for Tail-of-the-Log Backups demo

USE [master];
GO

IF DATABASEPROPERTYEX (N'Company', N'Version') > 0
BEGIN
	ALTER DATABASE [Company] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Company];
END
GO

-- Create the database
CREATE DATABASE [Company] ON PRIMARY (
    NAME = N'Company',
    FILENAME = N'D:\Pluralsight\Company.mdf')
LOG ON (
    NAME = N'Company_log',
    FILENAME = N'D:\Pluralsight\Company_log.ldf');
GO

USE [Company];
GO

-- Create a table
CREATE TABLE [RandomData] (
	[c1] INT IDENTITY,
	[c2] VARCHAR (100));
GO

INSERT INTO [RandomData] VALUES
	('Initial data: transaction 1');
GO

-- And take a full backup
BACKUP DATABASE [Company]
TO DISK = N'D:\Pluralsight\Company_Full.bak'
WITH INIT;
GO

-- Now add some more data
INSERT INTO [RandomData] VALUES
	('Transaction 2');
GO
INSERT INTO [RandomData] VALUES
	('Transaction 3');
GO

-- And a log backup
BACKUP LOG [Company]
TO DISK = N'D:\Pluralsight\Company_Log1.bak'
WITH INIT;
GO

-- Now add some more data
INSERT INTO [RandomData] VALUES
	('Transaction 4');
GO
INSERT INTO [RandomData] VALUES
	('Transaction 5');
GO

-- Simulate a crash
ALTER DATABASE [Company] SET OFFLINE;
GO

-- Delete the data file

-- Try to bring the database online
ALTER DATABASE [Company] SET ONLINE;
GO

-- The backups we have don't have the most recent transactions
-- so if we restore the backups we'll lose those transactions.

-- Let's see...
RESTORE DATABASE [Company_Copy]
FROM DISK = N'D:\Pluralsight\Company_Full.bak'
WITH
    MOVE N'Company' TO N'D:\Pluralsight\Company_Copy.mdf',
	MOVE N'Company_log' TO N'D:\Pluralsight\Company_Copy_log.ldf',
	REPLACE, NORECOVERY;
GO

RESTORE LOG [Company_Copy]
FROM DISK = N'D:\Pluralsight\Company_Log1.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [Company_Copy] WITH RECOVERY;
GO

-- What data do we have?
SELECT * FROM [Company_Copy].[dbo].[RandomData];
GO

-- Take a log backup?
BACKUP LOG [Company]
TO DISK = N'D:\Pluralsight\Company_Log_Tail.bak'
WITH INIT;
GO

-- Use the special syntax!
BACKUP LOG [Company]
TO DISK = N'D:\Pluralsight\Company_Log_Tail.bak'
WITH INIT, NO_TRUNCATE;
GO

-- Now restore
RESTORE DATABASE [Company_Copy]
FROM DISK = N'D:\Pluralsight\Company_Full.bak'
WITH
    MOVE N'Company' TO N'D:\Pluralsight\Company_Copy.mdf',
	MOVE N'Company_log' TO N'D:\Pluralsight\Company_Copy_log.ldf',
	REPLACE, NORECOVERY;
GO

RESTORE LOG [Company_Copy]
FROM DISK = N'D:\Pluralsight\Company_Log1.bak'
WITH NORECOVERY;
GO

RESTORE LOG [Company_Copy]
FROM DISK = N'D:\Pluralsight\Company_Log_Tail.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [Company_Copy] WITH RECOVERY;
GO

-- Is everything there?
SELECT * FROM [Company_Copy].[dbo].[RandomData];
GO

