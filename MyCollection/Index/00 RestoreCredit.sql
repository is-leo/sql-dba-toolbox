/*============================================================================
  File:     RestoreCredit.sql

  Summary:  Restore the Credit Database to give us a clean start between demos.
			THIS IS A SQLCMD SCRIPT! Be sure to turn that on before running.
  
  SQL Server Version: 2008+
------------------------------------------------------------------------------
  Written by Kimberly L. Tripp, SYSolutions, Inc.

  For more scripts and sample code, check out http://www.SQLskills.com

  This script is intended only as a supplement to demos and lectures
  given by Kimberly L. Tripp.  
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

-- These samples use the Credit database. You can download and restore the
-- credit database from here:
-- http://www.sqlskills.com/sql-server-resources/sql-server-demos/ 

-- There's also a 2008 backup that you can restore to any version of 2008 and higher
--   (definitely 2008, 2008R2, 2012, 2014, 2016, 2017, 2019, 2022)


-- IMPORTANT NOTES: 
-- 1) This is a compressed SQL Server 2008 backup.
-- 2) All examples expect a database name of Credit. However, if you
--    already have a database with this name, you can change it. In all other
--    scripts, you'll need to be sure to continue to change this based on your
--    new database name. (LINE 51)
-- 3) Be sure to set your complete path\file based on where the 
--    CreditBackup100.BAK is located. (LINE 52)
-- 4) Be sure to set the server/instance name for restore. (LINES 54-57)
-- 5) Be sure to set your instance directory structure based on your
--    installation. (LINES 59-60)
-- 6) Be sure to set your COMPATIBILITY LEVEL to the correct instance-level
--    if you want to test things that are version specific! (LINE 97)


-- In general, this script should take less than 30 seconds to execute.

:ON ERROR EXIT
go

:SETVAR DB Credit
:SETVAR CreditBackup "D:\SQLskills\CreditBackup100.BAK"

:SETVAR RestoreToServer (local)\SQL2022Dev01

:SETVAR RestoreToDirectory "D:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022Dev01\MSSQL\data"
go

:CONNECT $(RestoreToServer)
go

SET NOCOUNT ON;
go

USE master;
go

IF DATABASEPROPERTYEX('$(DB)', 'Collation') IS NOT NULL
	ALTER DATABASE [$(DB)]
		SET RESTRICTED_USER 
		WITH ROLLBACK AFTER 5;
go

IF substring(convert(varchar, SERVERPROPERTY('ProductVersion')), 1, 2) >= '10' 
	RESTORE DATABASE [$(DB)] 
	FROM  DISK = N'$(CreditBackup)' 
	WITH  FILE = 1,  
		MOVE N'CreditData' 
			TO N'$(RestoreToDirectory)\CreditData.mdf',  
		MOVE N'CreditLog' 
			TO N'$(RestoreToDirectory)\CreditLog.ldf',
	STATS = 10, REPLACE;
go

IF DATABASEPROPERTYEX('$(DB)', 'Collation') IS NOT NULL
	ALTER DATABASE [$(DB)]
		SET MULTI_USER 
		WITH ROLLBACK IMMEDIATE;
go

IF DATABASEPROPERTYEX('$(DB)', 'Collation') IS NOT NULL
	ALTER DATABASE [$(DB)]
		SET COMPATIBILITY_LEVEL = 110; -- Legacy CE by default
go

--Here are the valid values for Compatibility Level
--110	SQL Server 2012
--120	SQL Server 2014
--130	SQL Server 2016
--140	SQL Server 2017
--150	SQL Server 2019
--160	SQL Server 2022

-- Or, if you're on 2016 and higher, use the CURRENT compat mode:
-- So you get optimizer enhancements. Often, you might want to use 
-- the legacy CE (either with some queries or at the database level).

-- NOTE: You only get QE fixes up to RTM unless you ALSO turn on
-- QUERY_OPTIMIZER_HOTFIXES [IMO - TEST FIRST])

-- In 2016 and higher, we'll set the compat mode to the CURRENT 
-- version (for optimizer fixes) and then use the scoped configuration 
-- to set the database's CE to the legacy CE.

DECLARE @ServerVersion		char(3) = '100'
		, @LegacyCEScoped	bit = 0;

SELECT  @ServerVersion = CONVERT(char(2), SERVERPROPERTY('ProductMajorVersion')) + '0';

IF CONVERT(TINYINT, SERVERPROPERTY('ProductMajorVersion')) > 12
	SET @LegacyCEScoped = 1;

-- Testing
-- SELECT @ServerVersion, @LegacyCEScoped

DECLARE @ExecStr varchar(512) = ('ALTER DATABASE ' 
						+ QUOTENAME('$(DB)', N']') 
						+ ' SET COMPATIBILITY_LEVEL = ' 
						+ @ServerVersion);
EXEC (@ExecStr);

USE [$(DB)];

IF @LegacyCEScoped = 1
	ALTER DATABASE SCOPED CONFIGURATION 
		SET LEGACY_CARDINALITY_ESTIMATION = ON;
go

SELECT [sc].* 
FROM sys.database_scoped_configurations AS [sc]
WHERE [sc].[name] = N'LEGACY_CARDINALITY_ESTIMATION';
go

SELECT [sd].[compatibility_level], [sd].* 
FROM sys.databases AS [sd]
WHERE [sd].[name] = N'$(DB)'