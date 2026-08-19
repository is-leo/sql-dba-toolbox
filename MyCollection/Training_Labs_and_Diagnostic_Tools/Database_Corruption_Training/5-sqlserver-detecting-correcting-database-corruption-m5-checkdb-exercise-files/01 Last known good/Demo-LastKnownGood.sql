-- Demo script for Viewing Last-Known-Good Time demo.

-- Cleanup from any previous demo
USE [master];
GO

IF DATABASEPROPERTYEX (N'Company', N'Version') > 0
BEGIN
	ALTER DATABASE [Company] SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Company];
END
GO

-- Create a new database
CREATE DATABASE [Company] ON PRIMARY (
    NAME = N'Company',
    FILENAME = N'D:\Pluralsight\Company.mdf')
LOG ON (
    NAME = N'Company_log',
    FILENAME = N'D:\Pluralsight\Company_log.ldf');
GO

-- Run DBCC CHECKDB on it
DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO

-- View the last-known-good time
DBCC TRACEON (3604);
DBCC DBINFO (N'Company');
GO

-- Another option
EXEC sp_cycle_errorlog;
GO

ALTER DATABASE [Company] SET OFFLINE;
ALTER DATABASE [Company] SET ONLINE;

-- Look in the errorlog



