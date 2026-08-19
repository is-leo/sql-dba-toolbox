-- Demo script for Restore Sequences demo

-- Cleanout the backup history
USE [msdb];
GO

DECLARE @dateStr VARCHAR (20);

SELECT @dateStr = CONVERT (VARCHAR, GETDATE ());

EXEC sp_delete_backuphistory @datestr;
GO

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

-- Create a table that will grow large quickly
CREATE TABLE [RandomData] (
	[c1] INT IDENTITY,
	[c2] CHAR (8000) DEFAULT 'a');
GO
SET NOCOUNT ON;
GO

INSERT INTO [RandomData] DEFAULT VALUES;
GO 1000

-- And take Sunday full backup
BACKUP DATABASE [Company]
TO DISK = N'D:\Pluralsight\Company_Full_Sunday.bak'
WITH INIT;
GO

-- And start a file for Monday's log backups
BACKUP LOG [Company]
TO DISK = N'D:\Pluralsight\Company_Log_Monday.bak'
WITH INIT;
GO

-- Now add more data, hourly log backups
-- and 6-hr differential backups for Monday
DECLARE @count INT;
SELECT @count = 1;
WHILE @count < 25
BEGIN
	INSERT INTO [RandomData] DEFAULT VALUES;

	BACKUP LOG [Company]
	TO DISK = N'D:\Pluralsight\Company_Log_Monday.bak';

	IF (@count % 6 = 0)
	BEGIN
		BACKUP DATABASE [Company]
		TO DISK = N'D:\Pluralsight\Company_Diff_Monday.bak'
		WITH DIFFERENTIAL;
	END

	SELECT @count = @count + 1;

	WAITFOR DELAY '00:00:01';
END
GO
	
-- And start a file for Tuesday's log backups
BACKUP LOG [Company]
TO DISK = N'D:\Pluralsight\Company_Log_Tuesday.bak'
WITH INIT;
GO

-- Now add more data and hourly log backups for Tuesday,
-- but we crash just after the 3am backup
DECLARE @count INT;
SELECT @count = 1;
WHILE @count < 4
BEGIN
	INSERT INTO [RandomData] DEFAULT VALUES;

	BACKUP LOG [Company]
	TO DISK = N'D:\Pluralsight\Company_Log_Tuesday.bak';

	SELECT @count = @count + 1;

	WAITFOR DELAY '00:00:01';
END
GO
	
-- Now we simulate a crash
ALTER DATABASE [Company] SET OFFLINE;
GO

-- Delete the data file

-- Bring the database online again
ALTER DATABASE [Company] SET ONLINE;
GO

-- First thing - tail-of-the-log backup
BACKUP LOG [Company]
TO DISK = N'D:\Pluralsight\Company_Log_Tail.bak'
WITH INIT, NO_TRUNCATE;
GO

-- Now we have to restore. What backups do we have?

-- We need the most recent full backup, the most recent
-- differential backup, and then all the log backups after
-- that.

-- What about from the backup files themselves?
RESTORE HEADERONLY
FROM DISK =	N'D:\Pluralsight\Company_Full_Sunday.bak'

RESTORE HEADERONLY
FROM DISK =	N'D:\Pluralsight\Company_Diff_Monday.bak'

RESTORE HEADERONLY
FROM DISK =	N'D:\Pluralsight\Company_Log_Monday.bak';
GO

RESTORE HEADERONLY
FROM DISK =	N'D:\Pluralsight\Company_Log_Tuesday.bak';
GO

-- A little ungainly. How about from the backup history tables?
SELECT
	[backup_start_date],
	(CASE [type]
		WHEN N'D' THEN N'Full'
		WHEN N'I' THEN N'Diff'
		WHEN N'L' THEN N'Log'
		ELSE N'Unknown'
	END) AS N'Type',
	[position],
	[name],
	[description],
	[first_lsn], 
	[last_lsn], 
	[backup_finish_date]
FROM
	[msdb].[dbo].[backupset] AS [s]
JOIN
	[msdb].[dbo].[backupmediafamily] AS [m]
ON
	[s].[media_set_id] = [m].[media_set_id]
WHERE
	[database_name] = N'Company'
ORDER BY 1 ASC;
GO

-- Now do the restore
USE [master];
GO

-- Start with the most recent full backup
RESTORE DATABASE [Company]
FROM DISK = N'D:\Pluralsight\Company_Full_Sunday.bak'
WITH NORECOVERY, REPLACE;

-- Then the most recent differential backup
RESTORE DATABASE [Company]
FROM DISK =	N'D:\Pluralsight\Company_Diff_Monday.bak'
WITH FILE = 4, NORECOVERY;

-- And finally all the log backups after that, including the
-- tail-of-the-log backup
RESTORE DATABASE [Company]
FROM DISK =	N'D:\Pluralsight\Company_Log_Tuesday.bak'
WITH FILE = 2, NORECOVERY;
GO

RESTORE DATABASE [Company]
FROM DISK =	N'D:\Pluralsight\Company_Log_Tuesday.bak'
WITH FILE = 3, NORECOVERY;
GO

RESTORE DATABASE [Company]
FROM DISK = N'D:\Pluralsight\Company_Log_Tuesday.bak'
WITH FILE = 4, NORECOVERY;
GO

RESTORE DATABASE [Company]
FROM DISK = N'D:\Pluralsight\Company_Log_Tail.bak'
WITH NORECOVERY;
GO

RESTORE DATABASE [Company] WITH RECOVERY;
GO

USE [Company];
GO

SELECT COUNT (*) FROM [RandomData];
GO

-- Now suppose Monday's last diff is bad... if we
-- didn't have the backup history tables it could take
-- a while to figure out all the backups

-- Things to do to help:
-- 1) name backups with date and time
-- 2) figure out automated scripts to work out the restore
--    sequence from your backups
-- 3) use Recovery Advisor in SQL Server 2012

