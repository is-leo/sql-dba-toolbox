-- Demo script for DBCC CHECK* Options demo.

-- Run the Setup-DBCC-CHECKOptions.sql script.

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

-- Run DBCC CHECKDB on it with no options
DBCC CHECKDB (N'Company');
GO

-- Remove all the informational output (we'll talk about it
-- in Module 6).
DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO

-- Estimate of tempdb space
DBCC CHECKDB (N'Company') WITH ESTIMATEONLY;
GO

-- Using PHYSICAL_ONLY
DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS TIME ON;
GO
DBCC CHECKDB (N'SalesDB') WITH NO_INFOMSGS;
GO
SET STATISTICS TIME OFF;
GO

DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS TIME ON;
GO
DBCC CHECKDB (N'SalesDB') WITH NO_INFOMSGS, PHYSICAL_ONLY;
GO
SET STATISTICS TIME OFF;
GO

-- Checking for the DATA_PURITY bug
DBCC TRACEON (3604);
DBCC DBINFO (N'master');
GO

-- If zero on your server, do the following:
DBCC CHECKDB (N'master') WITH DATA_PURITY, NO_INFOMSGS;
DBCC CHECKDB (N'model') WITH DATA_PURITY, NO_INFOMSGS;
GO

-- Using TABLOCK

-- In another query window, use the Company database
DBCC CHECKDB (N'Company') WITH TABLOCK, NO_INFOMSGS;
GO

DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO
