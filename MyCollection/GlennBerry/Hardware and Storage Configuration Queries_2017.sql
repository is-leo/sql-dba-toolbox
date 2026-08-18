-- Hardware and Storage Configuration Queries
-- Glenn Berry


-- Make sure you are using the correct version of these diagnostic queries for your version of SQL Server


-- Check the major product version to see if it is SQL Server 2017 CTP 1 or greater
IF NOT EXISTS (SELECT * WHERE CONVERT(varchar(128), SERVERPROPERTY('ProductVersion')) LIKE '14%')
	BEGIN
		DECLARE @ProductVersion varchar(128) = CONVERT(varchar(128), SERVERPROPERTY('ProductVersion'));
		RAISERROR ('Script does not match the ProductVersion [%s] of this instance. Many of these queries may not work on this version.' , 18 , 16 , @ProductVersion);
	END
	ELSE
		PRINT N'You have the correct major version of SQL Server for this diagnostic information script';


-- Hardware information from SQL Server 2017  (Query 1) (Hardware Info)
SELECT cpu_count AS [Logical CPU Count], scheduler_count, 
       (socket_count * cores_per_socket) AS [Physical Core Count], 
       socket_count AS [Socket Count], cores_per_socket, numa_node_count,
       physical_memory_kb/1024 AS [Physical Memory (MB)], 
       max_workers_count AS [Max Workers Count], 
	   affinity_type_desc AS [Affinity Type], 
       sqlserver_start_time AS [SQL Server Start Time], 
	   virtual_machine_type_desc AS [Virtual Machine Type], 
       softnuma_configuration_desc AS [Soft NUMA Configuration], 
	   sql_memory_model_desc, process_physical_affinity -- New in SQL Server 2017
FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);
------

-- Gives you some good basic hardware information about your database server
-- Note: virtual_machine_type_desc of HYPERVISOR does not automatically mean 
--       you are running SQL Server inside of a VM
-- It merely indicates that you have a hypervisor running on your host

-- sys.dm_os_sys_info (Transact-SQL)
-- https://bit.ly/2pczOYs

-- Soft NUMA configuration was a new column for SQL Server 2016
-- OFF = Soft-NUMA feature is OFF
-- ON = SQL Server automatically determines the NUMA node sizes for Soft-NUMA
-- MANUAL = Manually configured soft-NUMA

-- Configure SQL Server to Use Soft-NUMA (SQL Server)
-- https://bit.ly/2HTpKJt

-- sql_memory_model_desc values (Added in SQL Server 2016 SP1)
-- CONVENTIONAL
-- LOCK_PAGES
-- LARGE_PAGES


-- Get System Manufacturer and model number from SQL Server Error log (Query 2) (System Manufacturer)
EXEC sys.xp_readerrorlog 0, 1, N'Manufacturer';
------ 

-- This can help you determine the capabilities and capacities of your database server
-- Can also be used to confirm if you are running in a VM
-- This query might take a few seconds if you have not recycled your error log recently
-- This query will return no results if your error log has been recycled since the instance was started


-- Get BIOS date from Windows Registry (Query 3) (BIOS Date)
EXEC sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\BIOS', N'BiosReleaseDate';
------

-- Helps you understand whether the main system BIOS is up to date, and the possible age of the hardware
-- Not useful for virtualization


-- Get processor description from Windows Registry  (Query 4) (Processor Description)
EXEC sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'HARDWARE\DESCRIPTION\System\CentralProcessor\0', N'ProcessorNameString';
------

-- Gives you the model number and rated clock speed of your processor(s)
-- Your processors may be running at less than the rated clock speed due
-- to the Windows Power Plan or hardware power management

-- You can use CPU-Z to get your actual CPU core speed and a lot of other useful information
-- https://www.cpuid.com/softwares/cpu-z.html

-- You can learn more about processor selection for SQL Server by following this link
-- https://bit.ly/2F3aVlP




-- SQL Server NUMA Node information  (Query 5) (SQL Server NUMA Info)
SELECT node_id, node_state_desc, memory_node_id, processor_group, cpu_count, online_scheduler_count, 
       idle_scheduler_count, active_worker_count, avg_load_balance, resource_monitor_state
FROM sys.dm_os_nodes WITH (NOLOCK) 
WHERE node_state_desc <> N'ONLINE DAC' OPTION (RECOMPILE);
------

-- Gives you some useful information about the composition and relative load on your NUMA nodes
-- You want to see an equal number of schedulers on each NUMA node
-- Watch out if SQL Server 2017 Standard Edition has been installed 
-- on a physical or virtual machine with more than four sockets or more than 24 physical cores


-- sys.dm_os_nodes (Transact-SQL)
-- https://bit.ly/2pn5Mw8

-- Balancing Your Available SQL Server Core Licenses Evenly Across NUMA Nodes
-- https://bit.ly/2vfC4Rq



-- Get memory-optimized checkpoint mode from SQL Server Error log (Query 6) (Memory-Optimized Checkpoint Mode)
EXEC sys.xp_readerrorlog 0, 1, N'In-Memory OLTP initialized on';
------ 

-- Possible values:
-- In-Memory OLTP initialized on standard machine
-- In-Memory OLTP initialized on highend machine      (Large Checkpoint mode)

-- Checkpoint process for memory-optimized tables in SQL 2016 and implications on the log
-- https://bit.ly/2c8jKj1

-- A "highend machine" must meet all of these criteria:
-- The server has 16 or more logical processors
-- The server has 128GB or greater memory
-- The server is capable of greater than 200MB/sec I/O measured for the IO subsystem of that database

-- FIX: Slow database recovery in SQL Server 2016 due to large log 
--      when you use In-Memory OLTP on a high-end computer
-- https://bit.ly/2FlOEUL

-- In SQL Server 2016 CU1 and later, global TF 9912 must be enabled to get large checkpoint mode



-- Good basic information about OS memory amounts and state  (Query 7) (System Memory)
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





-- See if buffer pool extension (BPE) is enabled (Query 8) (BPE Configuration)
SELECT [path], state_description, current_size_in_kb, 
CAST(current_size_in_kb/1048576.0 AS DECIMAL(10,2)) AS [Size (GB)]
FROM sys.dm_os_buffer_pool_extension_configuration WITH (NOLOCK) OPTION (RECOMPILE);
------

-- BPE is available in both Standard Edition and Enterprise Edition
-- It is a more interesting feature for Standard Edition

-- Buffer Pool Extension to SSDs in SQL Server 2014
-- https://bit.ly/1bm08m8

-- Buffer Pool Extension
-- https://bit.ly/2oBuieO

-- sys.dm_os_buffer_pool_extension_configuration (Transact-SQL)
-- https://bit.ly/2qSF4xr



-- Drive information for all fixed drives visible to the operating system (Query 9) (Fixed Drives)
SELECT fixed_drive_path, drive_type_desc, 
CONVERT(DECIMAL(18,2), free_space_in_bytes/1073741824.0) AS [Available Space (GB)]
FROM sys.dm_os_enumerate_fixed_drives WITH (NOLOCK) OPTION (RECOMPILE);
------

-- This shows all of your fixed drives, not just LUNs with SQL Server database files



-- Volume info for all LUNS that have database files on the current instance (Query 10) (Volume Info)
SELECT DISTINCT vs.volume_mount_point, vs.file_system_type, vs.logical_volume_name, 
CONVERT(DECIMAL(18,2), vs.total_bytes/1073741824.0) AS [Total Size (GB)],
CONVERT(DECIMAL(18,2), vs.available_bytes/1073741824.0) AS [Available Size (GB)],  
CONVERT(DECIMAL(18,2), vs.available_bytes * 1. / vs.total_bytes * 100.) AS [Space Free %],
vs.supports_compression, vs.is_compressed, 
vs.supports_sparse_files, vs.supports_alternate_streams
FROM sys.master_files AS f WITH (NOLOCK)
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs 
ORDER BY vs.volume_mount_point OPTION (RECOMPILE);
------

-- Shows you the total and free space on the LUNs where you have database files
-- Being low on free space can negatively affect performance with some types of storage

-- sys.dm_os_volume_stats (Transact-SQL)
-- https://bit.ly/2oBPNNr




