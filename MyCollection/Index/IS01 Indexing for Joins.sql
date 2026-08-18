/*============================================================================
  File:     Indexing for Joins - Credit.sql

  Summary:  Various tests and index access patterns using 5 table joins.
  
  SQL Server Version: 2005+
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

SELECT [sd].[compatibility_level], [sd].* 
FROM sys.databases AS [sd]
WHERE [sd].[name] = db_name();
go

--If you want to change the compat level 
--ALTER DATABASE [Credit]
--	SET COMPATIBILITY_LEVEL = 140; -- SQL Server 2017 
GO

SELECT [sc].* 
FROM sys.database_scoped_configurations AS [sc]
WHERE [sc].[name] = N'LEGACY_CARDINALITY_ESTIMATION';
go

--If you want to change the the CE (2016+)
--ALTER DATABASE SCOPED CONFIGURATION 
--		SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO

--SELECT [sc].* 
--FROM sys.database_scoped_configurations AS [sc]
--WHERE [sc].[name] = N'BATCH_MODE_ADAPTIVE_JOINS';
--go

--ALTER DATABASE SCOPED CONFIGURATION 
--	SET BATCH_MODE_ADAPTIVE_JOINS = ON;
--GO

-------------------------------------------------------------------------------
-- Let's get this plan as our base test case... review the 
-- showplan and FORCE every single index listed.
-------------------------------------------------------------------------------

-- USE:
--	0 = Table Scan
--	1 = Clustered Index Seek/Scan
--	name = for all non-clustered indexes 
--		(name is a bit safer)

-- This one is hardcoded for testing / comparing against the next query
SELECT [c].[statement_no]
		, [s].[statement_dt]
		, [c].[charge_amt]
		, [p].[provider_name]
		, [m].[lastname]
	FROM [dbo].[charge] AS [c] WITH (INDEX (1))
		INNER JOIN [dbo].[provider] AS [p] WITH (INDEX (1))
			ON [p].[provider_no] = [c].[provider_no]
		INNER JOIN [dbo].[member] AS [m] WITH (INDEX (1))
			ON [c].[member_no] = [m].[member_no]
		INNER JOIN [dbo].[statement] AS [s] WITH (INDEX (1))
			ON [c].[statement_no] = [s].[statement_no]
		INNER JOIN [dbo].[region] AS [r] WITH (INDEX (region_ident))
			ON [r].[region_no] = [m].[region_no]
WHERE [r].[region_name] = 'Japan'
	AND [c].[charge_amt] > 10
OPTION (MAXDOP 1)
GO

--This is the version where SQL Server can "do whatever it wants"
SELECT [c].[statement_no]
		, [s].[statement_dt]
		, [c].[charge_amt]
		, [p].[provider_name]
		, [m].[lastname]
	FROM [dbo].[charge] AS [c]
		INNER JOIN [dbo].[provider] AS [p]
			ON [p].[provider_no] = [c].[provider_no]
		INNER JOIN [dbo].[member] AS [m] 
			ON [c].[member_no] = [m].[member_no]
		INNER JOIN [dbo].[statement] AS [s] 
			ON [c].[statement_no] = [s].[statement_no]
		INNER JOIN [dbo].[region] AS [r] 
			ON [r].[region_no] = [m].[region_no]
WHERE [r].[region_name] = 'Japan'
	AND [c].[charge_amt] > 10
OPTION (MAXDOP 1);
go

-- Try the green hint

/*
CREATE NONCLUSTERED INDEX GreenHintComesFromMissingIndexDMVs
ON [dbo].[charge] ([charge_amt])
INCLUDE ([member_no],[provider_no],[statement_no]);
go
*/

-- Try DTA...

/*
CREATE NONCLUSTERED INDEX [DTARec__K2_K6_K3_K7] ON [dbo].[charge]
(
	[member_no] ASC,
	[charge_amt] ASC,
	[provider_no] ASC,
	[statement_no] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY];
go
*/

-- Find out that the green hint is the one chosen... why? Because
-- charge_amt is a range search, we just don't need all of those
-- other columns in the key!

-- TRY ALL THREE

-- This one is hardcoded for testing / comparing against the next query
SELECT [c].[statement_no]
		, [s].[statement_dt]
		, [c].[charge_amt]
		, [p].[provider_name]
		, [m].[lastname]
	FROM [dbo].[charge] AS [c] WITH (INDEX (1))
		INNER JOIN [dbo].[provider] AS [p] WITH (INDEX (1))
			ON [p].[provider_no] = [c].[provider_no]
		INNER JOIN [dbo].[member] AS [m] WITH (INDEX (1))
			ON [c].[member_no] = [m].[member_no]
		INNER JOIN [dbo].[statement] AS [s] WITH (INDEX (1))
			ON [c].[statement_no] = [s].[statement_no]
		INNER JOIN [dbo].[region] AS [r] WITH (INDEX (region_ident))
			ON [r].[region_no] = [m].[region_no]
WHERE [r].[region_name] = 'Japan'
	AND [c].[charge_amt] > 10
OPTION (MAXDOP 1)
GO

--Force the Green Hint
SELECT [c].[statement_no]
		, [s].[statement_dt]
		, [c].[charge_amt]
		, [p].[provider_name]
		, [m].[lastname]
	FROM [dbo].[charge] AS [c] WITH (INDEX (GreenHintComesFromMissingIndexDMVs))
		INNER JOIN [dbo].[provider] AS [p]
			ON [p].[provider_no] = [c].[provider_no]
		INNER JOIN [dbo].[member] AS [m] 
			ON [c].[member_no] = [m].[member_no]
		INNER JOIN [dbo].[statement] AS [s] 
			ON [c].[statement_no] = [s].[statement_no]
		INNER JOIN [dbo].[region] AS [r] 
			ON [r].[region_no] = [m].[region_no]
WHERE [r].[region_name] = 'Japan'
	AND [c].[charge_amt] > 10
OPTION (MAXDOP 1);
go


--This is the version where SQL Server can "do whatever it wants"
SELECT [c].[statement_no]
		, [s].[statement_dt]
		, [c].[charge_amt]
		, [p].[provider_name]
		, [m].[lastname]
	FROM [dbo].[charge] AS [c]
		INNER JOIN [dbo].[provider] AS [p]
			ON [p].[provider_no] = [c].[provider_no]
		INNER JOIN [dbo].[member] AS [m] 
			ON [c].[member_no] = [m].[member_no]
		INNER JOIN [dbo].[statement] AS [s] 
			ON [c].[statement_no] = [s].[statement_no]
		INNER JOIN [dbo].[region] AS [r] 
			ON [r].[region_no] = [m].[region_no]
WHERE [r].[region_name] = 'Japan'
	AND [c].[charge_amt] > 10
OPTION (MAXDOP 1);
go
