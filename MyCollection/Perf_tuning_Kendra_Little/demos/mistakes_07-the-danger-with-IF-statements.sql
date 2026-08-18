/* Doorstop */
RAISERROR(N'Did you mean to run the whole thing?',20,1) WITH LOG;
GO


USE StackOverflow2010;
GO

ALTER DATABASE StackOverflow2010 SET COMPATIBILITY_LEVEL = 160;
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

ALTER DATABASE CURRENT SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
GO


/**************************************************************************
Demo begins here
**************************************************************************/

-- Create a nonclustered index on PostTypeId
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Posts_PostTypeId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Posts_PostTypeId ON Posts(PostTypeId);
END
GO

CREATE OR ALTER PROCEDURE dbo.FetchPostsByType @PostTypeId INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @i int, @t nvarchar(256);

    IF @PostTypeId = 1 -- Fetch questions
        SELECT TOP 100000  @i=Id, @t=Title
        FROM Posts
        WHERE PostTypeId = @PostTypeId
        ORDER BY CreationDate DESC;
    ELSE IF @PostTypeId = 2 -- Fetch answers
        SELECT TOP 10000 @i=Id, @i=ParentId
        FROM Posts
        WHERE PostTypeId = @PostTypeId
        ORDER BY CreationDate DESC;
    ELSE IF @PostTypeId > 2 and @PostTypeId < 8 
        SELECT TOP 100 @i=Id, @t=Title
        FROM Posts
        WHERE PostTypeId = @PostTypeId
        ORDER BY CreationDate DESC;
    ELSE  /* Other cases */
		RETURN 0
END;
GO

SET STATISTICS IO, TIME ON;
GO

/* This first gets run as a "small" value
Look at the parameter compiled value
Examine the row estimates
*/
EXEC dbo.FetchPostsByType 3;
GO

/* This will re-use the plan. How does that go? */
/* Look at the parameter compiled value...
This branch of the plan was compiled on the FIRST run
Compare estimated vs actual rows coming out fo the nested loop.
*/
/* This takes around 25 seconds on our demo machine */
EXEC dbo.FetchPostsByType 2;
GO


/* What if this was to run first? */
EXEC sp_recompile 'FetchPostsByType';
GO
EXEC dbo.FetchPostsByType 2;
GO

/* Now if it reruns for 3.... */
EXEC dbo.FetchPostsByType 3;
GO


/* What if we supply 100 ? 
This is a time when it will only return 0*/
EXEC sp_recompile 'FetchPostsByType';
GO
EXEC dbo.FetchPostsByType 100;
GO

/* What was this compiled for and what does it estimate? 
Why is it SO slow*/
EXEC dbo.FetchPostsByType 2;
GO


/******************************************************************
Takeaways:
The whole procedure will be compiled when you first run it
This includes branches of IF/ELSE statements even if that statement is not executed based on the parameter values provided.

Fixes:
	* Insert the data into temporary tables and leverage temp table statistics for natural recompiles when you query it
	* Use dynamic sql or sub-procedures to execute the calling code in a separate "module"
		* sub-procedures or dynamic sql will only be compiled when it is executed.
*******************************************************************/


/* This could be rewritten in a shorter way, going for simplicity and
also preserving the IF /ELSE structure to show that it is no longer a factor
because the code is being executed in a separate context by sp_ExecuteSQL
*/
CREATE OR ALTER PROCEDURE dbo.FetchPostsByType @PostTypeId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i int, @t nvarchar(256);
    DECLARE @sql nvarchar(max), @params nvarchar(500);

    -- Define the parameters for dynamic SQL
    SET @params = N'@PostTypeId INT, @i INT OUTPUT, @t NVARCHAR(256) OUTPUT';

    IF @PostTypeId = 1 -- Questions
    BEGIN
        SET @sql = N'SELECT TOP 100000 @i=Id, @t=Title
                     FROM dbo.Posts
                     WHERE PostTypeId = @PostTypeId  
                     ORDER BY CreationDate DESC;';
    END
    ELSE IF @PostTypeId = 2 -- Answers still is selecting a different column than the others
    BEGIN
        SET @sql = N'SELECT TOP 10000 @i=Id, @i=ParentId
                     FROM dbo.Posts
                     WHERE PostTypeId = @PostTypeId
                     ORDER BY CreationDate DESC;';
    END
    ELSE IF @PostTypeId > 2 and @PostTypeId < 8 
    BEGIN
        SET @sql = N'SELECT TOP 100 @i=Id, @t=Title
                     FROM dbo.Posts
                     WHERE PostTypeId = @PostTypeId
                     ORDER BY CreationDate DESC;';
    END
    ELSE 
        RETURN 0;

    -- Execute the dynamic SQL
    EXEC sp_executesql @sql, @params, @PostTypeId=@PostTypeId, @i=@i OUTPUT, @t=@t OUTPUT;

END;
GO

EXEC dbo.FetchPostsByType 3;
GO

EXEC dbo.FetchPostsByType 2;
GO

EXEC dbo.FetchPostsByType 100;
GO

EXEC dbo.FetchPostsByType 2;
GO


