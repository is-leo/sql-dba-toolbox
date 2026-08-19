USE [AdventureWorks2014];
GO


/*
	Create a table for testing and populate
*/
CREATE TABLE [dbo].[IdentTest] (
	[ID] INT IDENTITY (1,1), 
	[Info] VARCHAR(20));
GO 

SET NOCOUNT ON;
GO

INSERT INTO [dbo].[IdentTest] ([Info])
VALUES ('test data');
GO 500


/*
	Check the data
*/
SELECT *
FROM [dbo].[IdentTest];
GO


/*
	Current identity value
*/
SELECT 
	TABLE_NAME,
	IDENT_SEED(TABLE_NAME) AS OriginalSeed,
	IDENT_INCR(TABLE_NAME) AS IncrementValue,
	IDENT_CURRENT(TABLE_NAME) AS CurrentIdentity
FROM INFORMATION_SCHEMA.TABLES
WHERE OBJECTPROPERTY(OBJECT_ID(TABLE_NAME), 'TableHasIdentity') = 1
AND TABLE_TYPE = 'BASE TABLE';
GO


/*
	The statement you might run by default
*/
DBCC CHECKIDENT ('dbo.IdentTest');
GO


/*
	Reseed the identity
*/
DBCC CHECKIDENT ('dbo.IdentTest', RESEED, 10);
GO


/*
	Check where we are
*/
SELECT 
	TABLE_NAME,
	IDENT_SEED(TABLE_NAME) AS OriginalSeed,
	IDENT_INCR(TABLE_NAME) AS IncrementValue,
	IDENT_CURRENT(TABLE_NAME) AS CurrentIdentity
FROM INFORMATION_SCHEMA.TABLES
WHERE OBJECTPROPERTY(OBJECT_ID(TABLE_NAME), 'TableHasIdentity') = 1
AND TABLE_TYPE = 'BASE TABLE';
GO


/*
	Insert a few rows
*/
INSERT INTO [dbo].[IdentTest] ([Info])
VALUES ('test data');
GO 10


/*
	Do not fix identity if it is wrong 
*/
DBCC CHECKIDENT ('dbo.IdentTest', NORESEED);
GO


/*
	Again, the statement you might run by default.
	Note that it will FIX the identity if it is wrong...
	and it does TELL you that in the output!
*/
DBCC CHECKIDENT ('dbo.IdentTest');
GO


/*
	Check where we are again
*/
SELECT 
	TABLE_NAME,
	IDENT_SEED(TABLE_NAME) AS OriginalSeed,
	IDENT_INCR(TABLE_NAME) AS IncrementValue,
	IDENT_CURRENT(TABLE_NAME) AS CurrentIdentity
FROM INFORMATION_SCHEMA.TABLES
WHERE OBJECTPROPERTY(OBJECT_ID(TABLE_NAME), 'TableHasIdentity') = 1
AND TABLE_TYPE = 'BASE TABLE';
GO


/*
	clean up
*/
DROP TABLE [dbo].[IdentTest];
GO