/* Doorstop */
RAISERROR(N'Did you mean to run the whole thing?',20,1) WITH LOG;
GO



ALTER DATABASE StackOverflow2010 SET COMPATIBILITY_LEVEL = 160;
GO
ALTER DATABASE StackOverflow2010 SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
GO

/*************************************************
INDEXING
*************************************************/


EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE
GO
EXEC sp_configure 'cost threshold for parallelism', 50;
GO
RECONFIGURE
GO


USE StackOverflow2010
GO


/* sp_BlitzIndex from Brent Ozar Unlimited is a handy tool for inspecting indexes on a table.
We want to start with only the clustered index on the Posts table. */
exec sp_BlitzIndex @TableName='Posts';
GO

/* Drop any nonclustered indexes on the Posts table */
DECLARE @schemaName NVARCHAR(256) = 'dbo',
	@tableName NVARCHAR(256) = 'Posts',
	@indexName NVARCHAR(256),
	@dropSql NVARCHAR(1000);
WHILE EXISTS (
    SELECT 1
    FROM sys.indexes i
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE i.type_desc = 'NONCLUSTERED'
    AND OBJECT_NAME(i.object_id) = @tableName
    AND s.name = @schemaName
)
BEGIN
    -- Get a nonclustered index for the table in the specified schema
    SELECT TOP 1 @indexName = i.name
    FROM sys.indexes i
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE i.type_desc = 'NONCLUSTERED' 
    AND OBJECT_NAME(i.object_id) = @tableName
    AND s.name = @schemaName

    -- Construct dynamic SQL to drop the index
    SET @dropSql = 'DROP INDEX ' + QUOTENAME(@indexName) + ' ON ' + QUOTENAME(@schemaName) + '.' + QUOTENAME(@tableName)
    EXEC sp_executesql @dropSql
END
GO


/* Look at the actual execution plan */
SELECT 
   COUNT(*)
FROM dbo.Posts
WHERE 
  PostTypeId = 1
  AND CreationDate >= '2009-12-30';
GO


/* This query is asking for this index.
In a production situation we should look at existing indexes on the table to see if we can combine, but in this case 
we are going to create the perfect nonclustered index for demonstration.
*/
CREATE NONCLUSTERED INDEX perfectIndexName on dbo.Posts (PostTypeId, CreationDate);
GO

/* Look at the plan now */
SELECT 
   COUNT(*)
FROM dbo.Posts
WHERE 
  PostTypeId = 1
  AND CreationDate >= '2009-12-30';
GO

/* What about this query?*/
SELECT 
   AVG(Score)
FROM dbo.Posts
WHERE 
  PostTypeId = 1
  AND CreationDate >= '2009-12-30';
GO

/* We can force it to use the index, but is this a good idea?*/
SELECT 
   AVG(Score)
FROM dbo.Posts WITH (INDEX([perfectIndexName]))
WHERE 
  PostTypeId = 1
  AND CreationDate >= '2009-12-30';
GO

/* However, the engine might decide to do this if we only are dealing with a small amount of rows */
SELECT 
   AVG(Score)
FROM dbo.Posts
WHERE 
  PostTypeId = 1
  AND CreationDate >= '2010-12-29' /* <--- Increased date by a year */;
GO

/**************************************************
Foreshadowing: the way I'm running this now with literal dates 
allows the optimzier to create a plan based just for those dates.

If we were to use a parameterized query, SQL Server would want to make a query plan that could be 
reused, and will "sniff" the parameters when it is first compiling the plan,
then allow that plan to be reused for other values.

Sometimes this is good and sometimes it is "bad parameter sniffing".

**************************************************/


/* If this query is also important, we can "cover" it by including Score in the nonclustered index */
CREATE NONCLUSTERED INDEX perfectIndexName on dbo.Posts (PostTypeId, CreationDate) INCLUDE (Score) WITH (DROP_EXISTING=ON, ONLINE=ON);
GO


/* Aside: notice how I only remembered to specify ONLINE=ON in one of those commands?
There is a database scoped property you can set to automatically elevate DDL commands to online unless you specify OFFLINE.
This can prevent blocking when indexes are created, as creating a nonclustered index offline makes the entire table unavailable for the duration of the operation.*/

SELECT * 
FROM sys.database_scoped_configurations
WHERE name = 'ELEVATE_ONLINE';

ALTER DATABASE SCOPED CONFIGURATION SET ELEVATE_ONLINE = WHEN_SUPPORTED;
GO
/* I am going to leave this off for the purposes of my demo machine.
This is only so I don't end up accidentally confused in some demo down the road.
*/
ALTER DATABASE SCOPED CONFIGURATION SET ELEVATE_ONLINE = OFF;
GO


/***** 
OK, let's partition posts 
Credits: chatgpt generated code
******/

SELECT  * 
FROM dbo.PostTypes;
GO

-- Create a Partition Function

/*
When you define a partition function, you specify how boundary values are treated
That's where RANGE RIGHT and RANGE LEFT come into play.
RANGE RIGHT:

    The boundary value belongs to the right-side partition.
    This means when a row with a value equal to the boundary value is inserted, 
		it goes to the partition on the right of the boundary value.

For example, given a partition function with RANGE RIGHT FOR VALUES (10, 20), we get three partitions:

    Values less than 10.
    Values from 10 to 19.
    Values 20 and greater.

RANGE LEFT:

    The boundary value belongs to the left-side partition.
    When a row with a value equal to the boundary value is inserted, it goes to the partition on the left
	of the boundary value.

For the same values (10, 20) with RANGE LEFT, the partitions would be:

    Values less than or equal to 10.
    Values from 11 to 20.
    Values greater than 20.
*/


-- Idempotent checks and drops

-- Drop the partitioned table if it exists
IF OBJECT_ID('dbo.Posts_Partitioned', 'U') IS NOT NULL
    DROP TABLE dbo.Posts_Partitioned;

-- Drop the partition scheme if it exists
IF EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PostTypePartitionScheme')
    DROP PARTITION SCHEME PostTypePartitionScheme;

-- Drop the partition function if it exists
IF EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PostTypePartitionFunction')
    DROP PARTITION FUNCTION PostTypePartitionFunction;



-- Create Partition Function and Scheme

-- Assuming 8 PostTypeIds
CREATE PARTITION FUNCTION PostTypePartitionFunction (int)
AS RANGE RIGHT FOR VALUES (1, 2, 3, 4, 5, 6, 7, 8);

CREATE PARTITION SCHEME PostTypePartitionScheme 
AS PARTITION PostTypePartitionFunction 
ALL TO ([PRIMARY]);  -- Storing all partitions in the PRIMARY filegroup.



-- Create the partitioned table
CREATE TABLE dbo.Posts_Partitioned
(
    Id INT NOT NULL,
    PostTypeId INT NOT NULL,
    CreationDate DATETIME NOT NULL,
    AcceptedAnswerId INT,
    AnswerCount INT,
    Body NVARCHAR(MAX),
    ClosedDate DATETIME,
    CommentCount INT,
    CommunityOwnedDate DATETIME,
    FavoriteCount INT,
    LastActivityDate DATETIME,
    LastEditDate DATETIME,
    LastEditorDisplayName NVARCHAR(100),
    LastEditorUserId INT,
    OwnerUserId INT,
    ParentId INT,
    Score INT,
    Tags NVARCHAR(255),
    Title NVARCHAR(255),
    ViewCount INT,
    CONSTRAINT PK_Posts_Partitioned PRIMARY KEY CLUSTERED (PostTypeId, CreationDate, Id) 
) ON PostTypePartitionScheme(PostTypeId);



-- Step 4: Insert data from the original table to the new partitioned table
-- This takes ~90 seconds on my laptop
INSERT INTO dbo.Posts_Partitioned 
(
    Id, PostTypeId, CreationDate, AcceptedAnswerId, AnswerCount, Body, 
    ClosedDate, CommentCount, CommunityOwnedDate, FavoriteCount, 
    LastActivityDate, LastEditDate, LastEditorDisplayName, LastEditorUserId, 
    OwnerUserId, ParentId, Score, Tags, Title, ViewCount
)
SELECT 
    Id, PostTypeId, CreationDate, AcceptedAnswerId, AnswerCount, Body, 
    ClosedDate, CommentCount, CommunityOwnedDate, FavoriteCount, 
    LastActivityDate, LastEditDate, LastEditorDisplayName, LastEditorUserId, 
    OwnerUserId, ParentId, Score, Tags, Title, ViewCount
FROM dbo.Posts;
GO


/* The table is partitioned on PostTypeId. */
/*Enable actual plans */
SET STATISTICS TIME, IO ON;
GO
--Logical reads to scan the table
--Table 'Posts_Partitioned'. Scan count 9, logical reads 803605
SELECT COUNT(*)
FROM dbo.Posts_Partitioned;
GO

/* Compare this plan */
SELECT COUNT(*)
FROM dbo.Posts_Partitioned OPTION (USE HINT ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_140'))
GO



/* How do these queries do? */
create or alter proc #testquery1
	@PostTypeId int,
	@CreationDate DATETIME
AS
	SELECT 
	   COUNT(*)
	FROM dbo.Posts_Partitioned
	WHERE 
	  PostTypeId =  @PostTypeId
	  AND CreationDate >= @CreationDate;
GO

/* Run with actual plans enabled
Look in the seek predicates*/

exec #testquery1 @PostTypeId = 1, @CreationDate='2009-12-30';
GO

create or alter proc #testquery2
	@PostTypeId int,
	@CreationDate DATETIME
AS
	SELECT 
	   AVG(Score)
	FROM dbo.Posts_Partitioned
	WHERE 
	  PostTypeId = @PostTypeId
	  AND CreationDate >= @CreationDate;
GO
exec #testquery2 @PostTypeId = 1, @CreationDate='2009-12-30';
GO


 
/* What about a query that only searches by CreationDate?
It doesn't care about PostTypeId.*/
create or alter proc #testquery3
	@CreationDate DATETIME
AS
	SELECT 
	   AVG(Score)
	FROM dbo.Posts_Partitioned
	WHERE 
	 CreationDate >= @CreationDate;
GO
exec #testquery3 @CreationDate='2009-12-30';
GO


/* We can create a nonclustered index for these queries
We are using an Included column to "cover" the query 

When creating a nonclustered index on a partitioned table, it will be created on
the partition scheme unless specified otherwise
*/
CREATE NONCLUSTERED INDEX [DoesThisWork]
ON [dbo].[Posts_Partitioned] ([CreationDate])
INCLUDE ([Score])
GO

/* This goes row mode, so we see actual partition count
How many partitions did it check?*/
exec #testquery3 @CreationDate='2009-12-30';
GO

create or alter proc #testquery3
	@CreationDate DATETIME
AS
	SELECT 
		TOP 1 Score
	FROM dbo.Posts_Partitioned
	WHERE 
	 CreationDate >= @CreationDate
	ORDER BY CreationDate DESC;
GO
exec #testquery3 @CreationDate='2009-12-30';
GO

/* To not check every partition, we would have to create a 
"non-aligned" nonclustered index, like this.
*/
CREATE NONCLUSTERED INDEX [DoesThisWork_NonAligned]
ON [dbo].[Posts_Partitioned] ([CreationDate])
INCLUDE ([Score])
	ON [PRIMARY] /* I'm specifying a filegroup, not a partition scheme */
GO


exec #testquery3 @CreationDate='2009-12-30';
GO