SELECT * FROM TempDB.sys.sysfiles;

/*The 2 queries below can help. 
The first will take a snapshot of the size of the data 
and log files along with the space used within the files. 
This can be run on a regular basis to track usage over time. 

The second query will return the number of times the log file 
has grown since the last time the instance was restarted.*/

SELECT 
  GETUTCDATE() AS SnapshotDateTime
, groupid --0 = data, 1 = log
, SUM(size/128.) SizeOnDiskInMB
, SUM(FILEPROPERTY(name, 'spaceused')/128.) MBUsedWithinFile 
INTO tempdb_files 
FROM TempDB.sys.sysfiles
GROUP BY groupid;
 
SELECT * 
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Log Growths'
  AND instance_name = 'tempdb';