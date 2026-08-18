
-- IO and latency per file
SELECT  DB_NAME(vfs.database_id) AS database_name ,physical_name AS [Physical Name],
        size_on_disk_bytes / 1024 / 1024. AS [Size of File in MB] ,
        CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [Average Read latency] ,
        CAST(io_stall_write_ms/(1.0 + num_of_writes) AS NUMERIC(10,1)) AS [Average Write latency] ,
        CAST((io_stall_read_ms + io_stall_write_ms)
/(1.0 + num_of_reads + num_of_writes) 
AS NUMERIC(10,1)) AS [Average Total Latency],
        num_of_bytes_read / NULLIF(num_of_reads, 0) AS    [Average Bytes Per Read],
        num_of_bytes_written / NULLIF(num_of_writes, 0) AS   [Average Bytes Per Write]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
  JOIN sys.master_files AS mf 
    ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
ORDER BY [Average Total Latency] DESC

/*
The definition of high IO latency per file in SQL Server is subjective and depends on 
various factors such as the hardware specifications, the workload, and the performance expectations. 
In general, an IO latency of 20 milliseconds (ms) or more per file can be considered high. 
However, this threshold may vary depending on the specific system and workload.

It's important to note that high IO latency can impact the overall performance of the database
and can lead to slow query response times, so it's important to monitor the IO latency
and address any performance issues as soon as they are detected. */ 
