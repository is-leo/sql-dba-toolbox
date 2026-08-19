/*
	Create a new database
	Create a 10MB "filler" table which we will drop later
	to create space that can be used by the shrink operation
*/
USE [master];
GO

IF DATABASEPROPERTYEX ('ShrinkTest', 'Version') > 0
	DROP DATABASE [ShrinkTest];

CREATE DATABASE [ShrinkTest];
GO

USE [ShrinkTest];
GO


/*
	Create and populate the filler table
*/
CREATE TABLE [dbo].[filler] (
	[c1] INT IDENTITY, 
	[c2] VARCHAR(8000));
GO

DECLARE @a INT;
SELECT @a = 1;
WHILE (@a < 1280) --insert 10MB
BEGIN
	INSERT INTO [dbo].[filler] VALUES (REPLICATE ('a', 5000));
	SELECT @a = @a + 1;
END;
GO


/*
	Now create the "production" table that we want to 
	optimize for performance
*/
CREATE TABLE [dbo].[Production] (
	[c1] INT IDENTITY, 
	[c2] VARCHAR (8000));

CREATE CLUSTERED INDEX [CL_Production] 
	ON [dbo].[Production] ([c1]);
GO

DECLARE @a INT;
SELECT @a = 1;
WHILE (@a < 1280) --insert 10MB
BEGIN
	INSERT INTO [dbo].[Production] VALUES (REPLICATE ('a', 5000));
	SELECT @a = @a + 1;
END;
GO 


/*
	Check table sizes for fun
*/
sp_spaceused 'dbo.filler'
GO
sp_spaceused 'dbo.Production'
GO


/*
	Use the sys.dm_db_index_physical_stats DMV to check 
	fragmentation of the clustered index
	for [dbo].[Production] - it should be almost 0
*/
SELECT 
	[avg_fragmentation_in_percent], 
	[fragment_count]
FROM [sys].[dm_db_index_physical_stats] (DB_ID(N'ShrinkTest'), OBJECT_ID(N'dbo.Production'), 1, NULL, 'LIMITED');
GO


/*
	Check space used within the file
*/
SELECT
	[file_id],
	[type],
	substring([physical_name],1,1),
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSize], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsed], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128.) [EmptySpace]
FROM [ShrinkTest].[sys].[database_files];
GO


/*
	Now drop the filler table
*/
DROP TABLE [dbo].[filler];
GO
CHECKPOINT;
GO


/*
	Check space used within the file again
*/
SELECT
	[file_id],
	[type],
	substring([physical_name],1,1),
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSize], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsed], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128.) [EmptySpace]
FROM [ShrinkTest].[sys].[database_files];
GO


/*
	There's free space, let's shrink the database!
*/
DBCC SHRINKDATABASE ([ShrinkTest]);
GO
     

/*
	Check index fragmentation again
*/
SELECT 
	[avg_fragmentation_in_percent], 
	[fragment_count]
FROM [sys].[dm_db_index_physical_stats] (DB_ID(N'ShrinkTest'), OBJECT_ID(N'dbo.Production'), 1, NULL, 'LIMITED');
GO


/*
	Check space used within the file
*/
SELECT
	[file_id],
	[type],
	substring([physical_name],1,1),
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSize], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsed], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128.) [EmptySpace]
FROM [ShrinkTest].[sys].[database_files];
GO


/*
	What happens if you rebuild the index?
*/
ALTER INDEX [CL_Production] ON [dbo].[Production] REBUILD;
GO


/*
	Check index fragmentation again
*/
SELECT 
	[avg_fragmentation_in_percent], 
	[fragment_count]
FROM [sys].[dm_db_index_physical_stats] (DB_ID(N'ShrinkTest'), OBJECT_ID(N'dbo.Production'), 1, NULL, 'LIMITED');
GO


/*
	Check space used within the file
*/
SELECT
	[file_id],
	[type],
	substring([physical_name],1,1),
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSize], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsed], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128.) [EmptySpace]
FROM [ShrinkTest].[sys].[database_files];


/*
	Clean up
*/
USE [master];
GO

DROP DATABASE [ShrinkTest];
GO


/*
	Example of shrinking a log file
	Assumes the [AdventureWorks2014] database exists
	Check recovery model first
*/
SELECT [name], [recovery_model_desc]
FROM [sys].[databases]
WHERE [name] = 'AdventureWorks2014'
GO

ALTER DATABASE [AdventureWorks2014] SET RECOVERY FULL;
GO


/*
	Make sure a full backup exists
*/
DECLARE @BackupPath NVARCHAR(100);
SET @BackupPath = 'C:\Backups\AW2014_' + 
	REPLACE(CONVERT(nvarchar(19),SYSDATETIME(), 126), ':','') + '.bak';

BACKUP DATABASE [AdventureWorks2014] 
	TO  DISK = @BackupPath
	WITH NOFORMAT, 
	INIT,   
	COMPRESSION,  
	STATS = 10;
GO


/*
	Set file growth low
*/
USE [master]
GO
ALTER DATABASE [AdventureWorks2014] MODIFY FILE ( NAME = N'AdventureWorks2014_Log', FILEGROWTH = 10%);
GO


/*
	Check the size of the log
*/
SELECT
	[file_id],
	[type],
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSizeMB], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsedMB], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') 
		AS DECIMAL(38,0))/128.) [EmptySpaceMB]
FROM [AdventureWorks2014].[sys].[database_files]
WHERE [type] = 1;


/*
	Modify data to grow the transaction log
*/
USE [AdventureWorks2014];
GO

UPDATE [Person].[Person]
SET [ModifiedDate] = GETDATE();
GO 

UPDATE [Sales].[SalesOrderDetail]
SET [ModifiedDate] = GETDATE();
GO


/*
	check the size of the log again
*/
SELECT
	[file_id],
	[type],
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSizeMB], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsedMB], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') 
		AS DECIMAL(38,0))/128.) [EmptySpaceMB]
FROM [AdventureWorks2014].[sys].[database_files]
WHERE [type] = 1;


/*
	Shrink the log file to 20MB
*/
USE [AdventureWorks2014];
GO
DBCC SHRINKFILE (N'AdventureWorks2014_log' , 20);
GO


/*
	Because shrink may not always shrink the file
	to the size specified, check to see
*/
SELECT
	[file_id],
	[type],
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSizeMB], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsedMB], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') 
		AS DECIMAL(38,0))/128.) [EmptySpaceMB]
FROM [AdventureWorks2014].[sys].[database_files]
WHERE [type] = 1;


/*
	We have active VLFs...the log cannot shrink until those are cleared
*/
DECLARE @BackupPath NVARCHAR(100);
SET @BackupPath = 'C:\Backups\AW2014_TLog_' + 
	REPLACE(CONVERT(nvarchar(19),SYSDATETIME(), 126), ':','') + '.bak';

BACKUP LOG [AdventureWorks2014] 
	TO  DISK = @BackupPath
	WITH INIT,  
	STATS = 10;
GO


/*
	Try to shrink again
*/
USE [AdventureWorks2014];
GO
DBCC SHRINKFILE (N'AdventureWorks2014_log' , 20);
GO


/*
	Check the log size again
*/
SELECT
	[file_id],
	[type],
	[name],
	[physical_name],
	CAST([size] as DECIMAL(38,0))/128. [FileSizeMB], 
	CAST(FILEPROPERTY([name],'SpaceUsed') AS DECIMAL(38,0))/128. [SpaceUsedMB], 
	(CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],'SpaceUsed') 
		AS DECIMAL(38,0))/128.) [EmptySpaceMB]
FROM [AdventureWorks2014].[sys].[database_files]
WHERE [type] = 1;


