-- Every 8KB data file page is really 16 contigious 512-byt disk blocks.
-- For a page to be properly written out to disk
-- all 16 blocks have to be written out correctly
-- if not all blocks written due to f.ex. power outage 
--then TORN-PAGE occurs

--Demo script for Page Protection demo.

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

-- What is it's page protection setting?
SELECT
	[page_verify_option],
	[page_verify_option_desc]
FROM
	sys.databases
WHERE
	[name] = N'Company';
GO

-- Also look in Object Explorer and change
-- to TORN_PAGE_DETECTION

-- Check again here
SELECT
	[page_verify_option],
	[page_verify_option_desc]
FROM
	sys.databases
WHERE
	[name] = N'Company';
GO

-- Change back to CHECKSUM
ALTER DATABASE [Company]
SET PAGE_VERIFY CHECKSUM;
GO

-- New databases inherit from the model
-- database.
ALTER DATABASE [model]
SET PAGE_VERIFY TORN_PAGE_DETECTION;
GO

DROP DATABASE [Company];
GO

CREATE DATABASE [Company] ON PRIMARY (
    NAME = N'Company',
    FILENAME = N'D:\Pluralsight\Company.mdf')
LOG ON (
    NAME = N'Company_log',
    FILENAME = N'D:\Pluralsight\Company_log.ldf');
GO

SELECT
	[page_verify_option],
	[page_verify_option_desc]
FROM
	sys.databases
WHERE
	[name] = N'Company';
GO

-- Change model back again
ALTER DATABASE [model]
SET PAGE_VERIFY CHECKSUM;
GO