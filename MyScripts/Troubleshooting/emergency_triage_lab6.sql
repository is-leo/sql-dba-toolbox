sp_BlitzFirst @Seconds = 60, @ExpertMode = 1

--RUN TO SEE BLOCKINGS
sp_WhoIsActive

EXEC sp_WhoIsActive
	@find_block_leaders = 1,
	@sort_order = '[blocked_session_count] desc'

/* Before:
Batch req/sec: 45.76
Wait Time per Core per Sec: 6.98
TOP WAITS:
PAGEIOLATCH_SH
WAIT_ON_SYNC_STATISTICS_REFRESH
ASYNC_NETWORK_IO
PAGELATCH_SH

FINDINGS:
Compilations/Sec High
Number of batch requests during the sample: 2654
Number of compilations during the sample: 8222
For OLTP environments, Microsoft recommends that 90% of batch requests should hit the plan cache, and not be compiled from scratch. We are exceeding that threshold.

High Percentage Of Runnable Queries
High Percentage Of Runnable Queries
High CPU Utilization
Slow Log File Writes
Slow Log File Writes

QUERY THAT IS REPEATEDLY RUNNING:
SELECT *   FROM dbo.Audit   
WHERE (TableName = @TableName OR @TableName IS NULL)     
AND (FieldName = @FieldName OR @FieldName IS NULL)  
AND (UpdateDate >= @StartDate OR @StartDate IS NULL)  
AND (UpdateDate <= @EndDate OR @EndDate IS NULL)   
ORDER BY UpdateDate, FieldName   
OFFSET ((@PageNumber - 1) * @PageSize) ROWS   
FETCH NEXT @PageSize ROWS ONLY

CREATE INDEX:
*/

CREATE CLUSTERED INDEX CL_UpdateDate_FieldName
	ON dbo.Audit(UpdateDate, FieldName)
	WITH (ONLINE = OFF, MAXDOP = 0)

--FIXED IMPLICIT CONVERSION
--TURN ON ALLOW SNAPSHOT ISOLATION
--MODIFY PROC AS:

ALTER   PROC [dbo].[usp_AuditReport] @TableName NVARCHAR(128) = NULL, @FieldName NVARCHAR(128) = NULL, 
	@StartDate DATE, @EndDate DATE, @PageNumber INT = 1, @PageSize INT = 100 AS
BEGIN
SET TRANSACTION ISOLATION LEVEL SNAPSHOT; -- ADD THIS !!!!
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


EXEC sp_WhoIsActive
	@find_block_leaders = 1,
	@sort_order = '[blocked_session_count] desc'

sp_BlitzFirst @Seconds=60, @ExpertMode=1

sp_BlitzCache @SortOrder = 'cpu'

sp_BlitzCache @SortOrder = 'duration'
/*You have 20262 plans in your cache, and 99.00% are duplicates with more than 5 entries, 
meaning similar queries are generating the same plan repeatedly. 
Forced Parameterization may fix the issue. To find troublemakers, use: EXEC sp_BlitzCache @SortOrder = 'query hash'; 

You have 20262 plans in your cache, and 99.00% are single use plans, 
meaning SQL Server thinks it's seeing a lot of "new" queries and creating plans for them. 
Forced Parameterization and/or Optimize For Ad Hoc Workloads may fix the issue.
To find troublemakers, use: EXEC sp_BlitzCache @SortOrder = 'query hash'; 

--after activating AD HOC & Forced Parameterization

You have 34994 total plans in your cache, with 100.00% plans created in the past 24 hours, 
100.00% created in the past 4 hours, and 100.00% created in the past 1 hour. When these percentages are high, 
it may be a sign of memory pressure or plan cache instability.