/* Doorstop */
RAISERROR(N'Did you mean to run the whole thing?',20,1) WITH LOG;
GO

/**********************
Demo reset section 
**********************/

ALTER DATABASE StackOverflow2010 SET COMPATIBILITY_LEVEL = 160;
GO
ALTER DATABASE StackOverflow2010 SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
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


DROP INDEX IF EXISTS CX_HighImpactUsers_UserId ON dbo.HighImpactUsers;
GO
DROP VIEW IF EXISTS dbo.HighImpactUsers;
GO


/*************************************************
BREAKING THINGS WITH INDEXES
*************************************************/

EXEC sp_BlitzIndex @tableName = 'Posts';
GO


CREATE OR ALTER VIEW dbo.HighImpactUsers WITH SCHEMABINDING
AS
SELECT 
    p.OwnerUserId,
	u.DisplayName,
    COUNT_BIG(*) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AverageScore,
    MAX(p.Score) AS HighestPostScore
FROM dbo.Posts p
JOIN dbo.Users u on p.OwnerUserId = u.Id
WHERE p.OwnerUserId IS NOT NULL
GROUP BY p.OwnerUserId, u.DisplayName;
GO

-- Create a unique clustered index on the view.
CREATE UNIQUE CLUSTERED INDEX CX_HighImpactUsers_UserId ON dbo.HighImpactUsers(OwnerUserId);
GO

/*****
LOL, we didn't look at the limitations on indexed views:
https://learn.microsoft.com/sql/relational-databases/views/create-indexed-views

AVG needs to be done with SUM and COUNT_BIG.
MAX is not allowed.

Why?

From Reumus Rusanu: 
	"These aggregates are not allowed because they cannot be recomputed solely based on the changed values.

	Some aggregates, like COUNT_BIG() or SUM(), can be recomputed just by looking at the data that changed. 
	These are allowed within an indexed view because, if an underlying value changes, the impact of that change can be directly calculated.

	Other aggregates, like MIN() and MAX(), cannot be recomputed just by looking at the data that is being changed. 
	If you delete the value that is currently the max or min, then the new max or min has to be searched for and found in the entire table.

	The same principle applies to other aggregates, like AVG() or the standard variation aggregates. 
	SQL cannot recompute them just from the values changed, but needs to re-scan the entire table to get the new value."

	-- https://stackoverflow.com/a/2134890/557499

*****/

CREATE OR ALTER VIEW dbo.HighImpactUsers WITH SCHEMABINDING
AS
SELECT 
    p.OwnerUserId,
	u.DisplayName,
    COUNT_BIG(*) AS TotalPosts,
    SUM(p.Score) AS TotalScore
FROM dbo.Posts p
JOIN dbo.Users u on p.OwnerUserId = u.Id
WHERE p.OwnerUserId IS NOT NULL
GROUP BY p.OwnerUserId, u.DisplayName;
GO

-- Create a unique clustered index on the view.
CREATE UNIQUE CLUSTERED INDEX CX_HighImpactUsers_UserId ON dbo.HighImpactUsers(OwnerUserId);
GO


-- Retrieve total posts, total score, and average score of a specific user.
CREATE OR ALTER PROCEDURE dbo.usp_GetUserStats @userId INT
AS
BEGIN
    SELECT DisplayName, TotalPosts, TotalScore, TotalScore/(1.*TotalPosts) as AverageScore
    FROM HighImpactUsers
    WHERE OwnerUserId = @userId;
END;
GO

/* What happens here? */
/* User with one post */
EXEC dbo.usp_GetUserStats @userId=519251;
GO
/* Jon Skeet*/
EXEC dbo.usp_GetUserStats @userId=22656 WITH RECOMPILE;
GO


-- 2. Retrieve top 10 users with the highest total score.
CREATE OR ALTER PROCEDURE dbo.usp_GetTopUsersByTotalScore
AS
BEGIN
    SELECT TOP 10 DisplayName, TotalScore
    FROM HighImpactUsers
    ORDER BY TotalScore DESC;
END;
GO
EXEC usp_GetTopUsersByTotalScore;
GO


-- Retrieve users with a total score higher than a given value.
CREATE OR ALTER PROCEDURE dbo.usp_GetUsersByScoreThreshold @threshold INT
AS
BEGIN
    SELECT OwnerUserId, DisplayName
    FROM HighImpactUsers
    WHERE TotalScore > @threshold;
END;
GO

exec dbo.usp_GetUsersByScoreThreshold @threshold=5000;
GO


/*********************************
SEEMS GREAT

LETS SHIP IT!!!!!!

*********************************/







/* turn on actual execution plans */
BEGIN TRAN
INSERT dbo.Users ( [AboutMe], [Age], [CreationDate], [DisplayName], [DownVotes], [EmailHash], [LastAccessDate], [Location], [Reputation], [UpVotes], [Views], [WebsiteUrl], [AccountId])
SELECT 'boo',120, getdate(), 'hi', 1, null, getdate(), 'earth', 1, 0, 0, null, null;


ROLLBACK




/* 
	What happened there? 
	Review the indexed view definition
*/
CREATE OR ALTER VIEW dbo.HighImpactUsers WITH SCHEMABINDING
AS
SELECT 
    p.OwnerUserId,
	u.DisplayName,
    COUNT_BIG(*) AS TotalPosts,
    SUM(p.Score) AS TotalScore
FROM dbo.Posts p
JOIN dbo.Users u on p.OwnerUserId = u.Id
WHERE p.OwnerUserId IS NOT NULL
GROUP BY p.OwnerUserId, u.DisplayName;
GO


/* Every time a user is added or removed, we need to update the indexed view
The indexed view needs to know how many posts that user has and what the total score is
*/

/* You might wonder....
Do we allow OwnerUserIds to have posts if they don't have a related row in dbo.Users?
*/

/* sp_BlitzIndex has a section on Foreign Keys */
exec sp_BlitzIndex @tableName='Posts';
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.foreign_keys 
    WHERE name = 'FK_Posts_OwnerUserId_Users_Id' 
    AND parent_object_id = OBJECT_ID('Posts')
)
BEGIN
    ALTER TABLE Posts
    ADD CONSTRAINT FK_Posts_OwnerUserId_Users_Id
    FOREIGN KEY (OwnerUserId) REFERENCES Users(Id)
END



/* Oh, I see */
SELECT p.OwnerUserId, COUNT(*) as CT
FROM dbo.Posts as p
LEFT JOIN dbo.Users as u on 
	p.OwnerUserId = u.Id
WHERE u.Id is null
GROUP BY p.OwnerUserId
ORDER BY CT DESC;
GO


/* OK, so if we can't add a foreign key .. which would help with data integrity AND
help the optimizer under some scenarios.... we'll index our problem away.
*/

CREATE INDEX ix_Posts_HelpMyIndexedView 
	on dbo.Posts (OwnerUserID) INCLUDE (SCORE)
	WITH (ONLINE=ON);
GO



/* turn on actual execution plans */
BEGIN TRAN
INSERT dbo.Users ( [AboutMe], [Age], [CreationDate], [DisplayName], [DownVotes], [EmailHash], [LastAccessDate], [Location], [Reputation], [UpVotes], [Views], [WebsiteUrl], [AccountId])
SELECT 'boo',120, getdate(), 'hi', 1, null, getdate(), 'earth', 1, 0, 0, null, null;


ROLLBACK

GO


/************************************
Cleanup 
***************************************/

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


DROP INDEX IF EXISTS CX_HighImpactUsers_UserId ON dbo.HighImpactUsers;
GO
DROP VIEW IF EXISTS dbo.HighImpactUsers;
GO
