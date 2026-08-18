/* POSION WAITS
1. THREADPOOL means...
We've run out of worker threads, new queries cant start
SQL Server seems frozen, and monitoring tools fail
Windows OS CPU metrics seem totally fine, idle
Connect with the DAC, find the lead blocker

TO FIX: tunde indexes , queries to avoid the blocking
storm & reduce parallelism requirements 

DONT throw CPU or workers threads at it:
it's expensive and ineffective under most circumstances
*/

USE StackOverflow
GO
DROPIndexes
GO

SELECT COUNT(*)
FROM dbo.Users

-- in a new session run
BEGIN TRAN
UPDATE dbo.Users
SET Reputation = 1000000
WHERE Id = 26837

--at this point you wont be able to connect or open new session
--go to file -> new -> Database Engine Query & connect as ADMIN:instancename
--run then sp_BlitzWho to see who is main blocker, in this case update command
--contact the user/app & ask to commit it, killing would cause a rollback which is single-threaded 
--once commite all the piled up queries will progress

--check
sp_BlitzCache @SortOrder = 'memory grant'
sp_BlitzWho

SELECT COUNT(*)
FROM dbo.Users

--improve queries by creating index
CREATE INDEX Age
ON dbo.Users(Age)

--even better to create a columnstore index which is perfect for count, max operations
CREATE NONCLUSTERED COLUMNSTORE
INDEX AgeColumStore ON dbo.Users(Age)
WITH (ONLINE = OFF, MAXDOP = 0)

--------------------------------------------------------------------

/* Next poison wait: RESOURCE_SEMAPHORE */

USE StackOverflow
GO
DropIndexes
GO
SELECT TOP 250 *
	FROM dbo.Users
	ORDER BY Reputation DESC;
GO

--connect with DAC & run to see Memory Grants Pending/Query Problems/RESOURCE_SEMAPHORE
sp_BlitzFirst @ExpertMode = 1

--find out which queries are culprit for RESOURCE_SEMAPHORE
--show me queries that got alot of memory but did not actually use it
sp_BlitzCache @SortOrder = 'unused grant'
--show me queries that got alot of memory but might have used it
sp_BlitzCache @SortOrder = 'memory grant'

--HOW TO FIX: 
--1.create index 
SELECT TOP 250 *
	FROM dbo.Users
	ORDER BY Reputation DESC;
GO

CREATE INDEX Reputation ON dbo.Users(Reputation)
WITH (ONLINE = OFF, MAXDOP = 0)

DROP INDEX Reputation ON dbo.Users

--fix 2
--This query desires 49GB grant
SELECT TOP 250 *
	FROM dbo.Users
	ORDER BY Reputation DESC;
GO
--Selecting less columns will decrease this number
--This query desires 700MB grant
SELECT TOP 250 Id, CreationDate, LastAccessDate
	FROM dbo.Users
	ORDER BY Reputation DESC;
GO
--what if we select less rows, only helps if select is upto 100 rows
--This query desires 8MB grant
SELECT TOP 100 * 
	FROM dbo.Users
	ORDER BY Reputation DESC;
GO

-- one more row query desires 1406MB grant
SELECT TOP 101 * 
	FROM dbo.Users
	ORDER BY Reputation DESC;
GO

--------------------------------------------------------------------

/* Next poison waits: WRITELOG WAIT, HADR_SYNC_COMMIT, ASYNC_METWORK */

SET STATISTICS IO ON
GO
SELECT * FROM dbo.Users

sp_WhoIsActive
GO 20


----------------------- LAB5

sp_BlitzFirst @Seconds = 60, @ExpertMode = 1
/* Before:
Batch req/sec 97.84(goal for 10x: 970)
Wait time ratio: 10.46
Top wait types: 
SOS_SCHEDULER_YIELD (CPU) 3034.7 sec
LCK_M_S  1480.1 sec
PAGEIOLATCH_EX 68 sec
WRITELOG 64 sec

After the Audit clustered index:
Batch req/sec 100 (goal for 10x: 970)
Wait time ratio: 10.17
Top wait types: 
LCK_M_S  2180.9 sec
SOS_SCHEDULER_YIELD (CPU) 1725.7 sec
PAGEIOLATCH_EX 49.2 sec
WRITELOG 27.9 sec

After the snapshot isolation change:
Batch req/sec 78.05 (goal for 10x: 970)
Wait time ratio: 5.54
Top wait types: 
LCK_M_S  is gone
SOS_SCHEDULER_YIELD (CPU) 2500.4 sec
PAGEIOLATCH_EX 22.2 sec
WRITELOG 12.9 sec

DBCC FREEPROCCACHE

After fixing implicit conversion:
Batch req/sec 54.68 (goal for 10x: 970)
Wait time ratio: 5.83
Top wait types: 
LCK_M_S  is gone
SOS_SCHEDULER_YIELD (CPU) 2497.9 sec
PAGEIOLATCH_EX 14.5 sec
WRITELOG 8.7 sec

*/


--start with CPU issue 
sp_BlitzCache @SortOrder = 'cpu'
--finding duplicate queries
WITH RedundantQueries AS 
        (SELECT TOP 10 query_hash, statement_start_offset, statement_end_offset,
            /* PICK YOUR SORT ORDER HERE BELOW: */

            COUNT(query_hash) AS sort_order,            --queries with the most plans in cache

            /* Your options are:
            COUNT(query_hash) AS sort_order,            --queries with the most plans in cache
            SUM(total_logical_reads) AS sort_order,     --queries reading data
            SUM(total_worker_time) AS sort_order,       --queries burning up CPU
            SUM(total_elapsed_time) AS sort_order,      --queries taking forever to run
            */

            COUNT(query_hash) AS PlansCached,
            COUNT(DISTINCT(query_plan_hash)) AS DistinctPlansCached,
            MIN(creation_time) AS FirstPlanCreationTime,
            MAX(creation_time) AS LastPlanCreationTime,
			MAX(s.last_execution_time) AS LastExecutionTime,
            SUM(total_worker_time) AS Total_CPU_ms,
            SUM(total_elapsed_time) AS Total_Duration_ms,
            SUM(total_logical_reads) AS Total_Reads,
            SUM(total_logical_writes) AS Total_Writes,
			SUM(execution_count) AS Total_Executions,
            --SUM(total_spills) AS Total_Spills,
            N'EXEC sp_BlitzCache @OnlyQueryHashes=''0x' + CONVERT(NVARCHAR(50), query_hash, 2) + '''' AS MoreInfo
            FROM sys.dm_exec_query_stats s
            GROUP BY query_hash, statement_start_offset, statement_end_offset
            ORDER BY 4 DESC)
SELECT r.query_hash, r.PlansCached, r.DistinctPlansCached, q.SampleQueryText, q.SampleQueryPlan,
        r.Total_Executions, r.Total_CPU_ms, r.Total_Duration_ms, r.Total_Reads, r.Total_Writes, --r.Total_Spills,
        r.FirstPlanCreationTime, r.LastPlanCreationTime, r.LastExecutionTime, 
		r.statement_start_offset, r.statement_end_offset, r.sort_order, r.MoreInfo
    FROM RedundantQueries r
    CROSS APPLY (SELECT TOP 10 st.text AS SampleQueryText, qp.query_plan AS SampleQueryPlan, qs.total_elapsed_time
        FROM sys.dm_exec_query_stats qs 
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
        WHERE r.query_hash = qs.query_hash
            AND r.statement_start_offset = qs.statement_start_offset
            AND r.statement_end_offset = qs.statement_end_offset
        ORDER BY qs.total_elapsed_time DESC) q
    ORDER BY r.sort_order DESC, r.query_hash, r.statement_start_offset, r.statement_end_offset, q.total_elapsed_time DESC;


--decide which columns to include in the index
-- Audit db size is 673,504 rows; 70.1MB, index creation should be fast
CREATE CLUSTERED INDEX CL_UpdateDate_FieldName
	ON dbo.Audit(UpdateDate, FieldName)
	WITH (ONLINE = OFF, MAXDOP = 0)

USE StackOverflow
GO
ALTER DATABASE [StackOverflow] SET ALLOW_SNAPSHOT_ISOLATION ON
GO


USE StackOverflow
GO
sp_BlitzIndex @TableName = 'Audit'
-- heap, no clustered index, no identity column
--check the most cpu consuming proc 
ALTER PROC [dbo].[usp_AuditReport] 
	@TableName VARCHAR(128) = NULL, 
	@FieldName VARCHAR(128) = NULL, 
	@StartDate DATE, 
	@EndDate DATE, 
	@PageNumber INT = 1,
	@PageSize INT = 100 AS
BEGIN
--if query is read only
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
SELECT *
  FROM dbo.Audit
  WHERE (TableName = @TableName OR @TableName IS NULL)
    AND (FieldName = @FieldName OR @FieldName IS NULL)
	AND (UpdateDate >= @StartDate OR @StartDate IS NULL)
	AND (UpdateDate <= @EndDate OR @EndDate IS NULL)
  ORDER BY UpdateDate, FieldName
  OFFSET ((@PageNumber - 1) * @PageSize) ROWS
  FETCH NEXT @PageSize ROWS ONLY;
END


--implicit conversion issue was found after, sp_BlitzCache @SortOrder = 'cpu'
--columns @TableName & 	@FieldName are defined as NVARCHAR(128)in the proc
--whereas in the Audit table they are VARCHAR(128)
--also date data types differ (DATE vs DATETIME)
--change to table datatypes in the proc 

/* last cpu mitigation steps:
1. work with queries
2. offload read queries 
