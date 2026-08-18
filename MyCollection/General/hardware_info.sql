-- Hardware information from SQL Server 2017  (Query 17) (Hardware Info)
SELECT cpu_count AS [Logical CPU Count], scheduler_count, 
       (socket_count * cores_per_socket) AS [Physical Core Count], 
       socket_count AS [Socket Count], cores_per_socket, numa_node_count,
       physical_memory_kb/1024 AS [Physical Memory (MB)], 
       max_workers_count AS [Max Workers Count], 
       affinity_type_desc AS [Affinity Type], 
       sqlserver_start_time AS [SQL Server Start Time],
       DATEDIFF(hour, sqlserver_start_time, GETDATE()) AS [SQL Server Up Time (hrs)],
       virtual_machine_type_desc AS [Virtual Machine Type], 
       softnuma_configuration_desc AS [Soft NUMA Configuration], 
       sql_memory_model_desc, process_physical_affinity -- New in SQL Server 2017
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);