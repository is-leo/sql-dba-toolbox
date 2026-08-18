-- PLE best practice can calculated by 
-- (Max Server Memory/4GB) * 300

--DMV

SELECT * FROM sys.dm_os_performance_counters 
--Real time data. Identical as Performance Monitor but in relational format. Query this twice to determine the true value

SELECT * FROM sys.dm_db_index_physical_stats 
--Information about indexes on a table, fragmentation and average size of records in an index.

SELECT * FROM sys.dm_db_index_usage_stats
--Cumulative index usage data. Join with sys.indexes to get index name.
--The following code return index name, table name and index usage.

USE AdventureWorks2017;
 GO
 SELECT object_name (S.object_id) AS TableName,
 I.name AS IndexName,
 S.user_seeks AS Seeks,
 S.user_scans AS Scans,
 S.user_updates AS Updates,
 S.last_user_seek AS LastSeek,
 S.last_user_Scan AS LastScan
 FROM sys.dm_db_index_usage_stats S
 JOIN sys.indexes I ON S.object_id=I.object_id
 AND S.index_id=I.index_id
 WHERE S.object_id > 100000 --only user owned index data
 ORDER by Seeks, Scans;