/*============================================================================
  File:     Autopilot

  Summary:  Will SQL Server use that index? 
			This is a great way of testing the usefulness of indexes 
			without actually creating them!

            This is the SAME example as the joins script but using 
            autopilot instead of creating the indexes!

  SQL Server Version: 2008+
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp & Paul S. Randal, SQLskills.com

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

EXEC [sp_helpindex] '[dbo].[charge]';
GO

------------------------------------------
-- Should we create the index?
-- These are the two indexes that we THINK might be useful
-- to the join from the demo:

-- Green hint's recommendation
/*
CREATE NONCLUSTERED INDEX GreenHintComesFromMissingIndexDMVs
ON [dbo].[charge] ([charge_amt])
INCLUDE ([member_no],[provider_no],[statement_no])
GO
*/

-- DTA's recommendation
/*
CREATE NONCLUSTERED INDEX [DTARec__K6_K7_K2_K3] ON [dbo].[charge]
(
	[charge_amt] ASC,
	[statement_no] ASC,
	[member_no] ASC,
	[provider_no] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
*/

-- But, how long does it take to create (and test)
-- What about autopilot?

-- Check out this great article on Simple Talk
-- "Hypothetical Indexes on SQL Server"
-- https://www.simple-talk.com/sql/database-administration/hypothetical-indexes-on-sql-server/
------------------------------------------

-- Imagine that these were TWO indexes you thought may help
-- (as opposed to just creating the ONE that DTA recommends).
-- Leveraging "auto pilot" to create JUST the statistics
-- and see which one the optimizer chooses, is SUPER COOL!!

CREATE NONCLUSTERED INDEX [GreenHintComesFromMissingIndexDMVs]
ON [dbo].[charge] ([charge_amt])
INCLUDE ([member_no],[provider_no],[statement_no])
WITH STATISTICS_ONLY = -1;
GO

CREATE NONCLUSTERED INDEX [DTARec__K6_K7_K2_K3] 
ON [dbo].[charge] ([charge_amt], [statement_no], [member_no], [provider_no] )
WITH STATISTICS_ONLY = -1;
GO

-- You can get my version of sp_helpindex from the SQLskillsIndex project
EXEC [sp_sqlskills_helpindex] 'dbo.charge';
GO

-- Or, if you don't have the sp_helpindex rewrite, run
-- this to get the index IDs.
SELECT db_id() AS Parameter2, 
	object_id('charge') AS Parameter3;
GO

SELECT [i].[name], [i].[index_id] AS Parameter4
FROM [sys].[indexes] AS [i]
WHERE [i].[object_id] = OBJECT_ID('charge');
GO

-- Params: 
--	  0 (Parameter 1 = 0, means just these indexes)
--	, DBID (Parameter2)
--  , ObjectID (Parameter3)
--  , IndexID (Parameter4) But, those that are just statistics!)

DBCC AUTOPILOT(0, 12, 229575856, 7);
DBCC AUTOPILOT(0, 12, 229575856, 8);
GO

SET AUTOPILOT ON;
GO

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
	AND [c].[charge_amt] > 1500
--OPTION (MAXDOP 1, QUERYTRACEON 9481);
GO

SET AUTOPILOT OFF;
GO

-- Note: the percentages of these "hypothetical
-- indexes" might not match the final execution as these
-- are likely to get created using sampling. 

-- You can confirm this by reviewing the statistic:
DBCC SHOW_STATISTICS ('charge', 'stats to review');
GO

-- Finally, this particular case - the indexes are almost
-- identical so it's not entirely strange that auto pilot
-- chose the DTA index while the green hint is almost identical
-- either is going to give the same perf for this query...
-- HOWEVER, the DMV index is more consolidateable that the DTA index.
-- That would actually be my choice to create!

-- These "hypothetical indexes are really just statistics:
DROP INDEX [charge].[GreenHintComesFromMissingIndexDMVs]; 
DROP INDEX [charge].[DTARec__K6_K7_K2_K3]; 
GO

-- Finally, you have finished QUERY TUNING... 
-- NEXT, you have to decide what you want in production!

-- Check existing indexes
-- Check missing indexes
-- Create a BETTER overall index for production

