-- Quick look at Hard Ware and load

WITH SQLProcessCPU
AS(
   SELECT TOP(30) SQLProcessUtilization AS 'CPU_Usage', ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS 'row_number'
   FROM ( 
         SELECT 
           record.value('(./Record/@id)[1]', 'int') AS record_id,
           record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle],
           record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [SQLProcessUtilization], 
           [timestamp] 
         FROM ( 
              SELECT [timestamp], CONVERT(xml, record) AS [record] 
              FROM sys.dm_os_ring_buffers 
              WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
              AND record LIKE '%<SystemHealth>%'
              ) AS x 
        ) AS y
) 
SELECT 
   SERVERPROPERTY('SERVERNAME') AS 'Instance',
   (SELECT value_in_use FROM sys.configurations WHERE name like '%max server memory%') AS 'Max Server Memory',
   (SELECT physical_memory_in_use_kb/1024 FROM sys.dm_os_process_memory) AS 'SQL Server Memory Usage (MB)',
   (SELECT cpu_count FROM sys.dm_os_sys_info) AS 'Logical CPU Count',
   (SELECT hyperthread_ratio FROM sys.dm_os_sys_info) AS 'Hyperthread Ratio',
   (SELECT cpu_count / hyperthread_ratio FROM sys.dm_os_sys_info) AS 'Physical CPU Count',
   (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) AS 'SQL Instance Start Time',
   (SELECT total_physical_memory_kb/1024 FROM sys.dm_os_sys_memory) AS 'Physical Memory (MB)',
   (SELECT available_physical_memory_kb/1024 FROM sys.dm_os_sys_memory) AS 'Available Memory (MB)',
   (SELECT system_memory_state_desc FROM sys.dm_os_sys_memory) AS 'System Memory State',
   (SELECT [cntr_value] FROM sys.dm_os_performance_counters WHERE [object_name] LIKE '%Manager%' AND [counter_name] = 'Page life expectancy') AS 'Page Life Expectancy',
   (SELECT AVG(CPU_Usage) FROM SQLProcessCPU WHERE row_number BETWEEN 1 AND 30) AS 'SQLProcessUtilization30',
   (SELECT AVG(CPU_Usage) FROM SQLProcessCPU WHERE row_number BETWEEN 1 AND 15) AS 'SQLProcessUtilization15',
   (SELECT AVG(CPU_Usage) FROM SQLProcessCPU WHERE row_number BETWEEN 1 AND 10) AS 'SQLProcessUtilization10',
   (SELECT AVG(CPU_Usage) FROM SQLProcessCPU WHERE row_number BETWEEN 1 AND 5)  AS 'SQLProcessUtilization5',
   GETDATE() AS 'Data Sample Timestamp'
