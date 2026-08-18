--find files
SELECT d.name DatabaseName, f.name LogicalName,
f.physical_name AS PhysicalName,
f.type_desc TypeofFile
FROM sys.master_files f
INNER JOIN sys.databases d ON d.database_id = f.database_id
GO



--- change db file location 
USE master 
GO  
ALTER DATABASE [db_name] 
MODIFY FILE (name='db_name',filename='E:\Data\db_name.mdf'); -- set new location 
ALTER DATABASE db_name SET OFFLINE WITH ROLLBACK IMMEDIATE; 
--Physically move the mdf file  
ALTER DATABASE db_name SET ONLINE;
