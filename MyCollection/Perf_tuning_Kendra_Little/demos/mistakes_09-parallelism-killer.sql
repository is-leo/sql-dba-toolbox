/* Doorstop */
RAISERROR(N'Did you mean to run the whole thing?',20,1) WITH LOG;
GO



ALTER DATABASE StackOverflow2010 SET COMPATIBILITY_LEVEL = 160;
GO
ALTER DATABASE StackOverflow2010 SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
GO

USE StackOverflow2010;
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

/*************************************************

*************************************************/


/* Turn on actual plans
Why does this go parallel?
*/
SELECT TOP 1000 Id, Title
FROM Posts
ORDER BY CreationDate DESC;
GO

SELECT * 
from sys.configurations
where name in ('max degree of parallelism', 'cost threshold for parallelism');
GO


CREATE OR ALTER FUNCTION dbo.answerAccepted(@acceptedanswerid INT) 
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	declare @returnval bit=0;
    IF ISNULL(@acceptedanswerid, 0) > 0 
        SET @returnval = 1;
	RETURN  @returnval;
END
GO

/* We can add the column
using PERSISTED writes the results to disk 
This will take ~1:15
*/
ALTER TABLE dbo.Posts
ADD HasAcceptedAnswer AS dbo.answerAccepted(AcceptedAnswerId) PERSISTED;
GO

/****We can create a nonclustered index on it */
CREATE INDEX ix_questionable on dbo.Posts(HasAcceptedAnswer);
GO


/************************************************
Let's rerun this query.
It has nothing to do with the computed column.
Even if it did, the column is persisted to disk and indexed.
*************************************************/
SELECT TOP 1000 Id, Title
FROM Posts
ORDER BY CreationDate DESC;
GO


/****
Yeah, it doesn't matter. 
The table has cooties.
*****/
DROP INDEX IF EXISTS ix_questionable on dbo.Posts;
GO

ALTER TABLE dbo.Posts
DROP COLUMN HasAcceptedAnswer;
GO


/**********************
This function was simple, so we can do this instead
**************************/
ALTER TABLE dbo.Posts
ADD HasAcceptedAnswer AS (CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) PERSISTED;
GO

/* This can be indexed as well, if you like */

/* This doesn't prevent parallelism */
SELECT TOP 1000 Id, Title
FROM Posts
ORDER BY CreationDate DESC;
GO

/************************************************
If the function doesn't work as a simple computed column, consider
other options. Even a trigger is likely preferable long term to a scalar UDF in a computed column.
https://www.brentozar.com/archive/2020/10/using-triggers-to-replace-scalar-udfs-on-computed-columns/
************************************************/



/************************************************
Cleanup
************************************************/


DROP INDEX IF EXISTS ix_questionable on dbo.Posts;
GO

ALTER TABLE dbo.Posts
DROP COLUMN HasAcceptedAnswer;
GO
