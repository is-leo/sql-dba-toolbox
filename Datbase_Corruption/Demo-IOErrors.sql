-- Demo script for I/O Errors demo.

-- Run the Setup-IOErrors.sql script

-- Trip the I/O error
SELECT
	*
FROM
	[Company].[dbo].[RandomData];
GO

-- Look in error log using Object Explorer.

-- Look in the Windows Application event log.

-- Look in suspect_pages table.
SELECT
	*
FROM
	[msdb].[dbo].[suspect_pages];
GO

-- Trigger the error again, and recheck.
SELECT
	*
FROM
	[Company].[dbo].[RandomData];
GO

SELECT
	*
FROM
	[msdb].[dbo].[suspect_pages];
GO