USE [AdventureWorks2014];
GO


/*	
	Verify indexes for the table
*/
EXEC sp_SQLskills_SQL2012_helpindex N'HumanResources.Employee';
GO


/*
	How many rows in the table?
*/
SELECT COUNT(*) 
FROM [HumanResources].[Employee];


/*
	Using DBCC IND
*/
DBCC IND ('AdventureWorks2014', 'HumanResources.Employee', 1);
GO


/*
	Using DBCC IND to see ALL index pages
*/
DBCC IND ('AdventureWorks2014', 'HumanResources.Employee', -1);
GO


/*
	We can manage our view of the output
	if we save this information to a table.
	Script from SQL Server 2008 Internals book
*/
CREATE TABLE [dbo].[sp_tablepages] (
	[PageFID] TINYINT,
	[PagePID] INT,
	[IAMFID] TINYINT,
	[IAMPID] INT,
	[ObjectID] INT,
	[IndexID] TINYINT,
	[PartitionNumber] TINYINT,
	[PartitionID] BIGINT,
	[iam_chain_type] VARCHAR(30),
	[PageType] TINYINT,
	[IndexLevel] TINYINT,
	[NextPageFID] TINYINT,
	[NextPagePID] INT,
	[PrevPageFID] TINYINT,
	[PrevPagePID] INT,
	PRIMARY KEY (
		[PageFID], [PagePID])
	);
GO


/*
	Capture DBCC IND output
*/
INSERT INTO [dbo].[sp_tablepages]
	EXEC ('DBCC IND (AdventureWorks2014, [HumanResources.Employee], 1)');
GO

SELECT * 
FROM [dbo].[sp_tablepages];
GO


/*
	PageType
		1 = data page
		2 = index page
		10 = IAM page

	IndexLevel
		0 = leaf
		highest = root
*/
SELECT
	[PageType],
	[IndexLevel],
	[PageFID],
	[PagePID],
	[PrevPageFID],
	[PrevPagePID],
	[NextPageFID],
	[NextPagePID],
	[IAMPID]
FROM [dbo].[sp_tablepages]
ORDER BY 
	[IndexLevel] DESC, 
	CAST([PrevPageFID] AS VARCHAR(10)) + ':' + CAST(PrevPagePID AS VARCHAR(10));
GO


/*
	find IAM pages
*/
SELECT * 
FROM [dbo].[sp_tablepages] 
WHERE [IndexLevel] IS NULL;
GO


/*
	In SQL 2012, you can use sys.dm_db_database_page_allocations
	to get this same information (and more)
		-shows unallocated pages
		-system pages like PFS, GAM, IAM, and SGAM pages
		-pages allocated to a table or index 
	DBCC IND only shows pages allocated to the table in question, 
	so the results will not be one-to-one. 
	The DMF returns information from the extent and can include pages still 
	not allocated, because the extent is dedicated to the object.
*/
SELECT * 
FROM [sys].[dm_db_database_page_allocations] 
	(DB_ID(N'AdventureWorks2014'),OBJECT_ID(N'HumanResources.Employee'),1,NULL,'DETAILED');
GO


/*
	USE DBCC PAGE to look at data on a specific page
*/
DBCC TRACEON (3604);
GO
DBCC PAGE('AdventureWorks2014', 1, 1427, 2);
GO


/*
	DBCC PAGE with more readable output (different print option)
*/
DBCC TRACEON (3604);
GO
DBCC PAGE('AdventureWorks2014', 1, 1427, 3);
GO


/*
	Reading the boot page of the database
*/
DBCC TRACEON (3604);
GO
DBCC DBINFO(AdventureWorks2014) 
	WITH TABLERESULTS;
GO


/*
	You can also use DBCC PAGE
*/
DBCC PAGE('AdventureWorks2014', 1, 9, 3)
	WITH TABLERESULTS;
GO


/*
	Clean up
*/
DROP TABLE [dbo].[sp_tablepages];
GO