/*
	How much space is currently used by the buffer pool?
*/
SELECT *
FROM [sys].[dm_os_buffer_descriptors];

/*
	How much space is currently used by the buffer pool,
	per database?
*/
SELECT
	DB_NAME([database_id]) AS [Database], 
    COUNT (*) * 8 AS [SpaceUsed_KB],
    COUNT (*) * 8 / 1024 AS [SpaceUsed_MB]
FROM [sys].[dm_os_buffer_descriptors] WITH (NOLOCK)
WHERE [database_id] > 4 
AND [database_id] <> 32767
GROUP BY DB_NAME([database_id])
ORDER BY [SpaceUsed_MB] DESC OPTION (RECOMPILE);
GO

/*
	To drop clean buffers from the buffer pool, 
	first use CHECKPOINT to force all dirty pages 
	for the current database to be written to disk.
	After you do this, you can issue DBCC DROPCLEANBUFFERS 
	command to remove all clean buffers from the buffer pool.
	Then check buffer use again...
*/
USE [AdventureWorks2014];
GO

DBCC DROPCLEANBUFFERS;
GO

SET STATISTICS IO ON;

SELECT [SalesOrderID], [LineTotal], [UnitPriceDiscount]
FROM [Sales].[SalesOrderDetail]
WHERE [LineTotal] > 10000;
GO
/*

*/

EXEC [sp_SQLskills_SQL2012_helpindex] "Sales.SalesOrderDetail";
GO

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_LineTotal]
	ON [Sales].[SalesOrderDetail] ([LineTotal])
	INCLUDE ([UnitPriceDiscount]);
GO

CHECKPOINT; 
GO
SELECT
	DB_NAME(database_id) AS [Database], 
    COUNT (*) * 8 AS [SpaceUsed_KB],
    COUNT (*) * 8 / 1024 AS [SpaceUsed_MB]
FROM sys.dm_os_buffer_descriptors
WHERE database_id <> 32767
GROUP BY database_id;
GO

DBCC DROPCLEANBUFFERS;
GO

SELECT
	DB_NAME(database_id) AS [Database], 
    COUNT (*) * 8 AS [SpaceUsed_KB],
    COUNT (*) * 8 / 1024 AS [SpaceUsed_MB]
FROM sys.dm_os_buffer_descriptors
WHERE database_id <> 32767
GROUP BY database_id;
GO


/*
	Did the index help?
*/
SELECT [SalesOrderID], [LineTotal], [UnitPriceDiscount]
FROM [Sales].[SalesOrderDetail]
WHERE [LineTotal] > 10000;
GO
/*

*/


/*
	Clean up
*/
DROP INDEX [Sales].[SalesOrderDetail].[IX_SalesOrderDetail_LineTotal];
GO


/*
	What space is being used by the plan cache?
*/
SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO


/*
	Create a SP for testing
*/
IF OBJECT_ID ( 'Sales.usp_GetProductInfo', 'P' ) IS NOT NULL 
    DROP PROCEDURE [Sales].[usp_GetProductInfo];
GO

CREATE PROCEDURE [Sales].[usp_GetProductInfo]
	@ProductID INT
AS	

	SELECT [ProductID], [OrderQty]
	FROM [Sales].[SalesOrderDetail]
	WHERE [ProductID] = @ProductID
	ORDER BY [ProductID];

GO


/*
	Execute the SP
*/
SET STATISTICS IO ON;
EXECUTE [Sales].[usp_GetProductInfo] @ProductID = 900;
GO
EXECUTE [Sales].[usp_GetProductInfo] @ProductID = 870;
GO
SET STATISTICS IO OFF;

/*
	Get the plan for the query from the plan cache
*/
SELECT p.usecounts, s.text, qp.query_plan, p.plan_handle
FROM sys.dm_exec_cached_plans p
CROSS APPLY sys.dm_exec_query_plan (p.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) s
WHERE s.text LIKE '%usp_GetProduct%';


/*
	Clear the entire plan cache :(
	Check the size before and after
*/
SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO

DBCC FREEPROCCACHE;
GO

SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO


/*
	Verify the plan for that SP is no longer in cache
*/
SELECT p.usecounts, s.text, qp.query_plan, p.plan_handle
FROM sys.dm_exec_cached_plans p
CROSS APPLY sys.dm_exec_query_plan (p.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) s
WHERE s.text LIKE '%usp_GetProduct%';
GO


/*
	Selectively remove a plan from cache,
	re-run our SP
*/
EXECUTE [Sales].[usp_GetProductInfo] @ProductID = 900;
GO
EXECUTE [Sales].[usp_GetProductInfo] @ProductID = 870;
GO

/*
	Get the plan handle from cache
*/
SELECT p.usecounts, s.text, qp.query_plan, p.plan_handle
FROM sys.dm_exec_cached_plans p
CROSS APPLY sys.dm_exec_query_plan (p.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) s
WHERE s.text LIKE '%usp_GetProduct%';

/*
	Remove JUST that plan
*/
DBCC FREEPROCCACHE (<crazylongplanhandlethatIneverremember>);
GO

/*
	Confirm it's not in cache
*/	
SELECT p.usecounts, s.text, qp.query_plan, p.plan_handle
FROM sys.dm_exec_cached_plans p
CROSS APPLY sys.dm_exec_query_plan (p.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) s
WHERE s.text LIKE '%usp_GetProduct%';
GO


/*
	Re-check space used by the plan cache, this time
	we'll selectively remove SQL Plans
	http://www.sqlskills.com/blogs/kimberly/plan-cache-and-optimizing-for-adhoc-workloads/
	*query for SQL 2012 and higher
*/
SELECT type, name, sum(pages_kb) [CacheSizeKB]
FROM sys.dm_os_memory_clerks
GROUP BY type, name
ORDER BY type;

SELECT type, name, pages_kb
FROM sys.dm_os_memory_clerks
WHERE name = 'SQL Plans';

SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs],
	AVG(usecounts) AS [Avg Use Count],
    SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes
        ELSE 0
        END) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs – USE Count 1],
    SUM(CASE WHEN usecounts = 1 THEN 1
        ELSE 0
        END) AS [Total Plans – USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO

DBCC FREESYSTEMCACHE('SQL Plans');
GO

SELECT type, name, pages_kb
FROM sys.dm_os_memory_clerks
WHERE name = 'SQL Plans';

SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs],
	AVG(usecounts) AS [Avg Use Count],
    SUM(CAST((CASE WHEN usecounts = 1 THEN size_in_bytes
        ELSE 0
        END) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs – USE Count 1],
    SUM(CASE WHEN usecounts = 1 THEN 1
        ELSE 0
        END) AS [Total Plans – USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO


/*
	Remove plans for distributed queries
*/
DBCC FREESESSIONCACHE;
GO


/*
	Remove plans for a single database
*/
SELECT database_id, name
FROM sys.databases;

SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO

DBCC FLUSHPROCINDB(5);
GO

SELECT objtype AS [CacheType],
    COUNT_BIG(*) AS [Total Plans],
    SUM(CAST(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY objtype;
GO