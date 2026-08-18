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


/*************************************************
Auto-tuning
This is enabled by default in Azure SQL
*************************************************/
ALTER DATABASE CURRENT SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON ); 
GO

SELECT * 
FROM sys.database_automatic_tuning_options;
GO


exec sp_BlitzIndex @TableName='Posts';
GO
--We have one simple index on posts.
CREATE INDEX ix_Posts_PostTypeId on dbo.Posts (PostTypeId) INCLUDE (Score, Id);
GO


CREATE OR ALTER PROCEDURE dbo.TempTableVsAutoTune
	@PostTypeId int NULL
AS
	SET NOCOUNT ON;

	CREATE TABLE #p (
		[Id] [int] NOT NULL PRIMARY KEY CLUSTERED,
		[PostTypeId] [int] NULL,
		[Score] [int] NULL
	)

	IF @PostTypeId IS NOT NULL
	BEGIN
		INSERT #p (Id, PostTypeId, Score)
		SELECT Id, PostTypeId, Score
		FROM dbo.Posts
		WHERE PostTypeId = @PostTypeId;
	END
	ELSE
	BEGIN
		/* Only one row */
		INSERT #p (Id, PostTypeId, Score)
		SELECT Id, PostTypeId, Score
		FROM dbo.Posts
		WHERE Id =4;
	END

	declare @1 bigint;
	SELECT 
		@1 = COUNT(*),
		@1 = MAX(p.AnswerCount), 
		@1 = MIN(p.Score),
		@1 = MIN(p.ViewCount),
		@1 = MIN(p.FavoriteCount)
	FROM dbo.Posts as p
	JOIN #p on p.Id=#p.Id;
GO

/* Clear query store for the same of demo
Be careful doing this on production databases if you have dependencies on Query Store.*/
ALTER DATABASE CURRENT SET QUERY_STORE CLEAR;
GO

/* Enable actual plans */
EXEC dbo.TempTableVsAutoTune @PostTypeId=null;
GO
EXEC dbo.TempTableVsAutoTune @PostTypeId=3;
GO
/* Why does this one get a different plan? */
EXEC dbo.TempTableVsAutoTune @PostTypeId=1;
GO
/* What plan does this one get? */
EXEC dbo.TempTableVsAutoTune @PostTypeId=2;
GO



/* Run this in another window to get a workload going 
This requires sqlcmd mode to execute
*/
!!ostress.exe -S192.168.4.181,1435 -dStackOverflow2010 -Usa -PPassword23 -q -n1 -r40 -i"C:\Temp\automatic-plan-tuning-vs-temp-tables_WORKLOAD.sql" -T146


/********************************
Look for a tuning recommendation
The number after PR is the query_id in query_store

*******************************/


SELECT * 
from sys.dm_db_tuning_recommendations;
GO

/* Script from
https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-tuning-recommendations-transact-sql?view=sql-server-ver16
*/
WITH cte_db_tuning_recommendations
AS (
    SELECT reason,
        score,
        query_id,
		regressedPlanId,
        recommendedPlanId,
        current_state = JSON_VALUE(STATE, '$.currentValue'),
        current_state_reason = JSON_VALUE(STATE, '$.reason'),
        script = JSON_VALUE(details, '$.implementationDetails.script'),
        estimated_gain = (regressedPlanExecutionCount + recommendedPlanExecutionCount) *
                         (regressedPlanCpuTimeAverage - recommendedPlanCpuTimeAverage) / 1000000,
        error_prone = IIF(regressedPlanErrorCount > recommendedPlanErrorCount, 'YES', 'NO'),
		execute_action_start_time,
		execute_action_duration,
		execute_action_initiated_by,
		revert_action_initiated_time,
		revert_action_initiated_by,
		revert_action_start_time,
		details
    FROM sys.dm_db_tuning_recommendations
    CROSS APPLY OPENJSON(Details, '$.planForceDetails') WITH (
            [query_id] INT '$.queryId',
            regressedPlanId INT '$.regressedPlanId',
            recommendedPlanId INT '$.recommendedPlanId',
            regressedPlanErrorCount INT,
            recommendedPlanErrorCount INT,
            regressedPlanExecutionCount INT,
            regressedPlanCpuTimeAverage FLOAT,
            recommendedPlanExecutionCount INT,
            recommendedPlanCpuTimeAverage FLOAT
            )
    )
SELECT qsq.query_id,
	qsq.query_hash,
	object_name(qsq.object_id) as object_name,
    qsqt.query_sql_text,
    dtr.*,
    CAST(rp.query_plan AS XML) AS RegressedPlan,
    CAST(sp.query_plan AS XML) AS SuggestedPlan
FROM cte_db_tuning_recommendations AS dtr
INNER JOIN sys.query_store_plan AS rp
    ON rp.query_id = dtr.query_id
        AND rp.plan_id = dtr.regressedPlanId
INNER JOIN sys.query_store_plan AS sp
    ON sp.query_id = dtr.query_id
        AND sp.plan_id = dtr.recommendedPlanId
INNER JOIN sys.query_store_query AS qsq
    ON qsq.query_id = rp.query_id
INNER JOIN sys.query_store_query_text AS qsqt
    ON qsqt.query_text_id = qsq.query_text_id;
GO


/**************************************************************
QuickieStore is from Erik Darling Data
https://github.com/erikdarlingdata/DarlingData/tree/main/sp_QuickieStore
**************************************************************/

exec sp_WhoIsActive @get_plans=1;
GO

exec sp_QuickieStore;
GO

/* Which plan is it forcing for each? */
exec sp_QuickieStore @include_query_ids = '6';
GO

/*** Do we really want that? **/

exec sp_WhoIsActive @get_plans=1;
GO

--we can unforce the plans
exec sp_query_store_unforce_plan @query_id= 6, @plan_id = 8;
GO

--It keeps a status that a user invalidated the recommendation
--But these recommendations are not persisted when the database goes offline
--So the auto-tuning cycle will repeat eventually

-- We can add a recompile hint if we don't want the query to be auto-tuned
EXEC sp_query_store_set_hints @query_id=5, @value = N'OPTION(RECOMPILE)';
GO

/* Re-check the recommendation */
SELECT * 
from sys.dm_db_tuning_recommendations;
GO

/*** 
What would happen if we cleared query store and had added the hint this way? 
**/


/*******************************
CLEANUP
*******************************/

/* Stop Ostress.exe*/

ALTER DATABASE CURRENT SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
GO

exec sp_query_store_clear_hints @query_id=6;
GO