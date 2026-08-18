DECLARE @CounterPrefix NVARCHAR(30) 
SET @CounterPrefix = CASE WHEN @@SERVICENAME = 'MSSQLSERVER'
 THEN 'SQLServer:'
 ELSE 'MSSQL$' + @@SERVICENAME + ':'
 END ; 
-- Capture the first counter set
SELECT CAST(1 AS INT) AS collection_instance , 
 [OBJECT_NAME] , 
 counter_name , 
 instance_name , 
 cntr_value , 
 cntr_type , 
 CURRENT_TIMESTAMP AS collection_time
INTO #perf_counters_init
FROM sys.dm_os_performance_counters
WHERE ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
 AND counter_name = 'Full Scans/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
 AND counter_name = 'Index Searches/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
 AND counter_name = 'Lazy Writes/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
 AND counter_name = 'Page life expectancy'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
 AND counter_name = 'Processes Blocked'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
 AND counter_name = 'User Connections'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
 AND counter_name = 'Lock Waits/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
 AND counter_name = 'Lock Wait Time (ms)'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
 AND counter_name = 'SQL Re-Compilations/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Memory Manager'
 AND counter_name = 'Memory Grants Pending'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
 AND counter_name = 'Batch Requests/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
 AND counter_name = 'SQL Compilations/sec'
 ) 
-- Wait on Second between data collection
WAITFOR DELAY '00:00:01'
-- Capture the second counter set
SELECT CAST(2 AS INT) AS collection_instance , 
 OBJECT_NAME , 
 counter_name , 
 instance_name , 
 cntr_value , 
 cntr_type , 
 CURRENT_TIMESTAMP AS collection_time
INTO #perf_counters_second
FROM sys.dm_os_performance_counters
WHERE ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
 AND counter_name = 'Full Scans/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
 AND counter_name = 'Index Searches/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
 AND counter_name = 'Lazy Writes/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
 AND counter_name = 'Page life expectancy'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
 AND counter_name = 'Processes Blocked'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
 AND counter_name = 'User Connections'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
 AND counter_name = 'Lock Waits/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
 AND counter_name = 'Lock Wait Time (ms)'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
 AND counter_name = 'SQL Re-Compilations/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'Memory Manager'
 AND counter_name = 'Memory Grants Pending'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
 AND counter_name = 'Batch Requests/sec'
 ) 
 OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
 AND counter_name = 'SQL Compilations/sec'
 ) 



-- Calculate the cumulative counter values
SELECT i.OBJECT_NAME , 
 i.counter_name , 
 i.instance_name , 
 CASE WHEN i.cntr_type = 272696576
 THEN s.cntr_value - i.cntr_value
 WHEN i.cntr_type = 65792 THEN s.cntr_value
 END AS cntr_value
FROM #perf_counters_init AS i
 JOIN #perf_counters_second AS s
 ON i.collection_instance + 1 = s.collection_instance
 AND i.OBJECT_NAME = s.OBJECT_NAME
 AND i.counter_name = s.counter_name
 AND i.instance_name = s.instance_name
ORDER BY OBJECT_NAME


-- Cleanup tables
--DROP TABLE #perf_counters_init
--DROP TABLE #perf_counters_second 


--Interpret:
/*
Full Scans/sec - indicate missing indexes
Index Searches/sec - shoould be higher than Full Scans/sec                                                                                     
Buffer Manager and Memory Manager counters can be used, as a group, to 
identify if SQL Server is experiencing memory pressure.
The values of the Page Life Expectancy, Free List Stalls/sec, 
and Lazy Writes/sec counters, when corre?lated, will validate or 
disprove the theory that the buffer cache is under memory pressure.
If PLE is under this value (see formula below) then you have memory pressure
"Ex. for a server with 32 GB allocated to the buffer pool, 
the PLE value should be at least (32/4)*300 = 2400"

If the PLE is consistently below this value, and the server is experiencing high Lazy
Writes/sec, which are page flushes from the buffer cache outside of the normal 
CHECK?POINT process, then the server is most likely experiencing data cache memory pressure, 
which will also increase the disk I/O being performed by the SQL Server

General Statistics\Processes Blocked, Locks\Lock Waits/sec, and 
Locks\Lock Wait Time (ms) counters provide information about blocking


The three SQL Statistics counters provide information about how frequently SQL 
Server is compiling or recompiling an execution plan, in relation to the number of 
batches being executed against the server. The higher the number of SQL Compila?tions/sec 
in relation to the Batch Requests/sec, the more likely the SQL Server is 
experiencing an ad hoc workload that is not making optimal using of plan caching. The 
higher the number of SQL Re-Compilations/sec in relation to the Batch Requests/
sec, the more likely it is that there is an inefficiency in the code design that is forcing 
a recompile of the code being executed in the SQL Server. In either case, investigation 
of the Plan Cache, as detailed in the next section, should identify why the server has to 
consistently compile execution plans for the workload.

The Memory Manager\Memory Grants Pending performance counter provides 
information about the number of processes waiting on a workspace memory grant in 
the instance. If this counter has a high value, SQL Server may benefit from additional 
memory, but there may be query inefficiencies in the instance that are causing excessive 
memory grant requirements, for example, large sorts or hashes that can be resolved by 
tuning the indexing or queries being executed.

*/ 


