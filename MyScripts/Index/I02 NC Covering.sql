/*============================================================================
  File:     NC Covering.sql

  Summary:  Uses a series of options to return the data for a given range query.
			Create the indexes first (they're currently commented out) and then
			use the statistics io and showplan to see how the forced plans for
			each of the queries execute.
  
  SQL Server Version: SQL Server 2005+
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp, SYSolutions, Inc.

  For more scripts and sample code, check out 
    http://www.SQLskills.com
============================================================================*/

-- These samples use the Credit database. You can download and restore the
-- credit database from here:
-- http://www.sqlskills.com/resources/conferences/CreditBackup80.zip
-- See the "restore credit" script for help on restoring / automating the restore
-- as you go through scripts.

USE [Credit];
GO

sp_SQLskills_helpindex member;
go

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
go

-- No useful index for this query, must table scan
SELECT [m].[LastName], [m].[FirstName], [m].[Phone_No]
FROM [dbo].[Member] AS [m] 
WHERE [m].[LastName] LIKE '[S-Z]%';
go


-- Create an index on the search column
CREATE INDEX [MemberLastName] 
	ON [dbo].[Member]([LastName]);
go

-- Interestingly, still no useful index for this query
SELECT [m].[LastName], [m].[FirstName], [m].[Phone_No]
FROM [dbo].[Member] AS [m] 
WHERE [m].[LastName] LIKE '[S-Z]%';
go

SELECT [m].[LastName], [m].[FirstName], [m].[Phone_No]
FROM [dbo].[Member] AS [m] WITH (INDEX (MemberLastName))
WHERE [m].[LastName] LIKE '[S-Z]%';
go


-- This query is not selective enough for seek plus lookups, 
-- must consider covering
CREATE INDEX [NCLastNameCombo]
	ON [dbo].[Member]([LastName], [FirstName], [Phone_No]);
go

SELECT [m].[LastName], [m].[FirstName], [m].[Phone_No]
FROM [dbo].[Member] AS [m] 
WHERE [m].[LastName] LIKE '[S-Z]%';
go


-- What about covering without the ability to seek?
CREATE INDEX [NCLastNameCombo2] 
	ON [dbo].[Member]([FirstName], [LastName], [Phone_No]);
go

SELECT [m].[LastName], [m].[FirstName], [m].[Phone_No]
FROM [dbo].[Member] AS [m] WITH (INDEX (NCLastNameCombo2))
WHERE [m].[LastName] LIKE '[S-Z]%';
go


-- What about comparing all four - run all four at the same time!
SELECT m.LastName, m.FirstName, m.Phone_No
FROM dbo.Member AS m WITH (INDEX (0))
WHERE m.LastName LIKE '[S-Z]%'
go

SELECT m.LastName, m.FirstName, m.Phone_No
FROM dbo.Member AS m WITH (INDEX (MemberLastName))
WHERE m.LastName LIKE '[S-Z]%'
go

SELECT m.LastName, m.FirstName, m.Phone_No
FROM dbo.Member AS m
WHERE m.LastName LIKE '[S-Z]%'
go

SELECT m.LastName, m.FirstName, m.Phone_No
FROM dbo.Member AS m WITH (INDEX (NCLastNameCombo2))
WHERE m.LastName LIKE '[S-Z]%'
go


-- If you want to clean up the indexes:
--DROP INDEX [Member].[MemberLastName]
--DROP INDEX [Member].[NCLastNameCombo]
--DROP INDEX [Member].[NCLastNameCombo2]