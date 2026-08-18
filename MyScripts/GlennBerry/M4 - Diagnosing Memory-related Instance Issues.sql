-- M5 - Diagnosing Memory-related Instance Issues **************************************************************
-- Glenn Berry


-- Make sure you are using the correct version of these diagnostic queries for your version of SQL Server


-- Check the major product version to see if it is SQL Server 2017 CTP 1 or greater
IF NOT EXISTS (SELECT * WHERE CONVERT(varchar(128), SERVERPROPERTY('ProductVersion')) LIKE '14%')
	BEGIN
		DECLARE @ProductVersion varchar(128) = CONVERT(varchar(128), SERVERPROPERTY('ProductVersion'));
		RAISERROR ('Script does not match the ProductVersion [%s] of this instance. 
		            Many of these queries may not work on this version.' , 18 , 16 , @ProductVersion);
	END
	ELSE
		PRINT N'You have the correct major version of SQL Server for this diagnostic information script';
GO




-- Good basic information about OS memory amounts and state  (Query 1) (System Memory)
SELECT total_physical_memory_kb/1024 AS [Physical Memory (MB)], 
       available_physical_memory_kb/1024 AS [Available Memory (MB)], 
       total_page_file_kb/1024 AS [Total Page File (MB)], 
	   available_page_file_kb/1024 AS [Available Page File (MB)], 
	   system_cache_kb/1024 AS [System Cache (MB)],
       system_memory_state_desc AS [System Memory State]
FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);
------

-- You want to see "Available physical memory is high" for System Memory State
-- This indicates that you are not under external memory pressure

-- Possible System Memory State values:
-- Available physical memory is high
-- Physical memory usage is steady
-- Available physical memory is low
-- Available physical memory is running low
-- Physical memory state is transitioning

-- sys.dm_os_sys_memory (Transact-SQL)
-- https://bit.ly/2pcV0xq


-- SQL Server Process Address space info  (Query 2) (Process Memory)
SELECT physical_memory_in_use_kb/1024 AS [SQL Server Memory Usage (MB)],
	   locked_page_allocations_kb/1024 AS [SQL Server Locked Pages Allocation (MB)],
       large_page_allocations_kb/1024 AS [SQL Server Large Pages Allocation (MB)], 
	   page_fault_count, memory_utilization_percentage, available_commit_limit_kb, 
	   process_physical_memory_low, process_virtual_memory_low
FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);
------

-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low
-- This indicates that you are not under internal memory pressure
-- If locked_page_allocations_kb > 0, then LPIM is enabled

-- How to enable the "locked pages" feature in SQL Server 2012
-- https://bit.ly/2F5UjOA

-- Memory Management Architecture Guide
-- https://bit.ly/2JKkadC 


-- Get total buffer usage by database for current instance  (Query 3) (Total Buffer Usage by Database)
-- This make take some time to run on a busy instance
WITH AggregateBufferPoolUsage
AS
(SELECT DB_NAME(database_id) AS [Database Name],
CAST(COUNT(*) * 8/1024.0 AS DECIMAL (10,2))  AS [CachedSize]
FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
WHERE database_id <> 32767 -- ResourceDB
GROUP BY DB_NAME(database_id))
SELECT ROW_NUMBER() OVER(ORDER BY CachedSize DESC) AS [Buffer Pool Rank], 
       [Database Name], CachedSize AS [Cached Size (MB)],
       CAST(CachedSize / SUM(CachedSize) OVER() * 100.0 AS DECIMAL(5,2)) AS [Buffer Pool Percent]
FROM AggregateBufferPoolUsage
ORDER BY [Buffer Pool Rank] OPTION (RECOMPILE);
------

-- Tells you how much memory (in the buffer pool) 
-- is being used by each database on the instance


-- Page Life Expectancy (PLE) value for each NUMA node in current instance  (Query 4) (PLE by NUMA Node)
SELECT @@SERVERNAME AS [Server Name], RTRIM([object_name]) AS [Object Name], 
instance_name, cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);
------

-- PLE is a good measurement of internal memory pressure
-- Higher PLE is better. Watch the trend over time, not the absolute value
-- This will only return one row for non-NUMA systems

-- Page Life Expectancy isn’t what you think…
-- https://bit.ly/2EgynLa


-- Memory Grants Pending value for current instance  (Query 5) (Memory Grants Pending)
SELECT @@SERVERNAME AS [Server Name], RTRIM([object_name]) AS [Object Name], 
cntr_value AS [Memory Grants Pending]                                                                                                       
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Pending' OPTION (RECOMPILE);
------

-- Run multiple times, and run periodically if you suspect you are under memory pressure
-- Memory Grants Pending above zero for a sustained period is a very strong indicator of internal memory pressure


-- Memory Clerk Usage for instance  (Query 6) (Memory Clerk Usage)
SELECT TOP(10) mc.[type] AS [Memory Clerk Type], 
       CAST((SUM(mc.pages_kb)/1024.0) AS DECIMAL (15,2)) AS [Memory Usage (MB)] 
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
GROUP BY mc.[type]  
ORDER BY SUM(mc.pages_kb) DESC OPTION (RECOMPILE);
------

-- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)

-- MEMORYCLERK_SQLBUFFERPOOL was new for SQL Server 2012. It should be your highest consumer of memory

-- CACHESTORE_SQLCP  SQL Plans         
-- These are cached SQL statements or batches that aren't in stored procedures, functions and triggers
-- Watch out for high values for CACHESTORE_SQLCP
-- Enabling 'optimize for ad hoc workloads' at the instance level can help reduce this
-- Running DBCC FREESYSTEMCACHE ('SQL Plans') periodically may be required to better control this

-- CACHESTORE_OBJCP  Object Plans      
-- These are compiled plans for stored procedures, functions and triggers

-- sys.dm_os_memory_clerks (Transact-SQL)
-- https://bit.ly/2H31xDR


-- Find single-use, ad-hoc and prepared queries that are bloating the plan cache  (Query 7) (Ad hoc Queries)
SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name], t.[text] AS [Query Text], 
cp.objtype AS [Object Type],   
cp.size_in_bytes/1024 AS [Plan Size in KB]
FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype IN (N'Adhoc', N'Prepared') 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC, DB_NAME(t.[dbid]) OPTION (RECOMPILE);
------

-- Gives you the text, type and size of single-use ad-hoc 
-- and prepared queries that waste space in the plan cache
-- Enabling 'optimize for ad hoc workloads' for the instance can help 
-- Running DBCC FREESYSTEMCACHE ('SQL Plans') periodically may be required to better control this
-- Enabling forced parameterization for the database can help, but test first!

-- Plan cache, adhoc workloads and clearing the single-use plan cache bloat
-- https://bit.ly/2EfYOkl


-- Get top total logical reads queries for entire instance (Query 8) (Top Logical Reads Queries)
SELECT TOP(50) DB_NAME(t.[dbid]) AS [Database Name],
qs.total_logical_reads AS [Total Logical Reads],
qs.min_logical_reads AS [Min Logical Reads],
qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],
qs.max_logical_reads AS [Max Logical Reads],   
qs.min_worker_time AS [Min Worker Time],
qs.total_worker_time/qs.execution_count AS [Avg Worker Time], 
qs.max_worker_time AS [Max Worker Time], 
qs.min_elapsed_time AS [Min Elapsed Time], 
qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time], 
qs.max_elapsed_time AS [Max Elapsed Time],
qs.execution_count AS [Execution Count], 
CASE WHEN CONVERT(nvarchar(max), qp.query_plan) LIKE N'%<MissingIndexes>%' 
THEN 1 ELSE 0 END AS [Has Missing Index],
qs.creation_time AS [Creation Time],
t.[text] AS [Complete Query Text], qp.query_plan AS [Query Plan] 
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
ORDER BY qs.total_logical_reads DESC OPTION (RECOMPILE);
------


-- Helps you find the most expensive queries from a memory perspective across the entire instance
-- Can also help track down parameter sniffing issues



