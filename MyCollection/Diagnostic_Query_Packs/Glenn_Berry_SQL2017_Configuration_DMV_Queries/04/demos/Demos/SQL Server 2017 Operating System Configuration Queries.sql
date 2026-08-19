-- SQL Server 2017 Operating System Configuration Queries
-- Glenn Berry 


-- Make sure you are using the correct version of these queries for your version of SQL Server


-- Check the major product version to see if it is SQL Server 2017 CTP 1 or greater
IF NOT EXISTS (SELECT * WHERE CONVERT(varchar(128), SERVERPROPERTY('ProductVersion')) LIKE '14%')
	BEGIN
		DECLARE @ProductVersion varchar(128) = CONVERT(varchar(128), SERVERPROPERTY('ProductVersion'));
		RAISERROR ('Script does not match the ProductVersion [%s] of this instance. Many of these queries may not work on this version.' , 18 , 16 , @ProductVersion);
	END
	ELSE
		PRINT N'You have the correct major version of SQL Server for this diagnostic information script';
	

-- SQL and OS Version information for current instance  (Query 1) (Version Info)
SELECT @@VERSION AS [SQL Server and OS Version Info];
------

-- Example output:
-- Microsoft SQL Server 2017 (RTM-CU7) (KB4229789) - 14.0.3026.27 (X64)   
-- May 10 2018 12:38:11   Copyright (C) 2017 Microsoft Corporation  Developer Edition (64-bit) 
-- on Windows 10 Pro for Workstations 10.0 <X64> (Build 17134: ) (Hypervisor) 


-- SQL Server 2017 Builds																		
-- Build			Description			Release Date	URL to KB Article								
-- 14.0.1000.169	RTM					10/2/2017
-- 14.0.3006.16		CU1					10/24/2017		https://support.microsoft.com/en-us/help/4038634
-- 14.0.3008.27		CU2					11/28/2017		https://support.microsoft.com/en-us/help/4052574
-- 14.0.3015.40		CU3					1/4/2018		https://support.microsoft.com/en-us/help/4052987
-- 14.0.3022.28		CU4					2/20/2018		https://support.microsoft.com/en-us/help/4056498
-- 14.0.3023.8		CU5					3/20/2018		https://support.microsoft.com/en-us/help/4092643
-- 14.0.3025.34		CU6					4/17/2018	    https://support.microsoft.com/en-us/help/4101464
-- 14.0.3026.27		CU7					5/23/2018		https://support.microsoft.com/en-us/help/4229789	


-- SQL Server 2017 build versions
-- https://bit.ly/2FLY88I

-- Performance and Stability Fixes in SQL Server 2017 CU Builds
-- https://bit.ly/2GV3CNM

-- @@Version - Transact SQL Configuration Functions
-- https://bit.ly/2FI3zI9


-- Host information (Query 2) (Host Info)
SELECT host_platform, host_distribution, host_release, 
       host_service_pack_level, host_sku, os_language_version 
FROM sys.dm_os_host_info WITH (NOLOCK) OPTION (RECOMPILE); 
------


-- host_release codes (only valid for Windows)
-- 10.0 is Windows 10 or Windows Server 2016 
-- 6.3 is either Windows 8.1 or Windows Server 2012 R2
-- 6.2 is either Windows 8 or Windows Server 2012


-- host_sku codes (only valid for Windows)
-- 4 is Enterprise Edition
-- 7 is Standard Server Edition
-- 8 is Datacenter Server Edition
-- 10 is Enterprise Server Edition
-- 48 is Professional Edition
-- 161 is Pro for Workstations

-- 1033 for os_language_version is US-English

-- sys.dm_os_host_info (Transact-SQL)
-- https://bit.ly/2pcHc5Z



-- Windows information (Query 3) (Windows Info)
SELECT windows_release, windows_service_pack_level, 
       windows_sku, os_language_version
FROM sys.dm_os_windows_info WITH (NOLOCK) OPTION (RECOMPILE);
------

-- sys.dm_os_windows_info (Transact-SQL)
-- https://bit.ly/2qJzsZg

-- Gives you major OS version, Service Pack, Edition, and language info for the operating system
-- 10.0 is either Windows 10 or Windows Server 2016
-- 6.3 is either Windows 8.1 or Windows Server 2012 R2 
-- 6.2 is either Windows 8 or Windows Server 2012

-- Windows SKU codes
-- 4 is Enterprise Edition
-- 7 is Standard Server Edition
-- 8 is Datacenter Server Edition
-- 10 is Enterprise Server Edition
-- 48 is Professional Edition
-- 161 is Pro for Workstations


-- Get socket, physical core and logical core count from the SQL Server Error log. (Query 4) (Core Counts)
-- This query might take a few seconds depending on the size of your error log
EXEC sys.xp_readerrorlog 0, 1, N'detected', N'socket';
------

-- This can help you determine the exact core counts used by SQL Server and whether HT is enabled or not
-- It can also help you confirm your SQL Server licensing model
-- Be on the lookout for this message "using 40 logical processors based on SQL Server licensing" 
-- (when you have more than 40 logical cores) which means grandfathered Server/CAL licensing
-- This query will return no results if your error log has been recycled since the instance was last started










-- Returns status of instant file initialization (Query 5) (IFI Status)
EXEC sys.xp_readerrorlog 0, 1, N'Database Instant File Initialization';
------


-- Lets you determine whether Instant File Initialization (IFI) is enabled for the instance
-- This should be enabled in the vast majority of cases
-- SQL Server 2016 and newer lets you enable this during the SQL Server installation process
-- This query will return no results if your error log has been recycled since the instance was last started

-- Database Instant File Initialization
-- https://bit.ly/2nTX74y

-- Misconceptions around instant file initialization
-- https://bit.ly/2oBSKgZ





-- SQL Server Services information (Query 6) (SQL Server Services Info)
SELECT servicename, process_id, startup_type_desc, status_desc, 
last_startup_time, service_account, is_clustered, cluster_nodename, 
instant_file_initialization_enabled -- Added in SQL Server 2016 SP1
FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE);

-- Tells you the account being used for the SQL Server Service and the SQL Agent Service
-- Shows the process_id, when they were last started, and their current status
-- Also shows whether you are running on a failover cluster instance, and what node you are running on
-- Also shows whether IFI is enabled

-- sys.dm_server_services (Transact-SQL)
-- https://bit.ly/2oKa1Un







-- SQL Server Process Address space info  (Query 7) (Process Memory)
-- (shows whether locked pages is enabled, among other things)
SELECT physical_memory_in_use_kb/1024 AS [SQL Server Memory Usage (MB)],
       large_page_allocations_kb, locked_page_allocations_kb, 
	   process_physical_memory_low, process_virtual_memory_low
FROM sys.dm_os_process_memory WITH (NOLOCK) OPTION (RECOMPILE);
------

-- You want to see 0 for process_physical_memory_low
-- You want to see 0 for process_virtual_memory_low
-- This indicates that you are not under internal memory pressure
-- If locked_page_allocations_kb > 0, then LPIM is enabled

-- How to enable the "locked pages" feature in SQL Server 2012
-- https://bit.ly/2F5UjOA

-- sys.dm_os_process_memory (Transact-SQL)
-- https://bit.ly/2pY9TAI



-- Shows each module that is loaded into the SQL Server address space (Query 8) (Loaded Modules)
SELECT [description], [name], company, file_version, 
       product_version, debug, patched, prerelease, patched 
FROM sys.dm_os_loaded_modules WITH (NOLOCK)
ORDER BY [name] OPTION (RECOMPILE);
------

-- sys.dm_os_loaded_modules (Transact-SQL)
-- https://bit.ly/2t3SzzA

-- Performance and consistency issues when certain modules are loaded into SQL Server address space
-- https://bit.ly/2FzJzUG

