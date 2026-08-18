
--Database Backups for all databases For Previous Week 
--------------------------------------------------------------------------------- 
SELECT 
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
msdb.dbo.backupset.database_name, 
msdb.dbo.backupset.backup_start_date, 
msdb.dbo.backupset.backup_finish_date, 
DATEDIFF(MINUTE,msdb.dbo.backupset.backup_start_date,msdb.dbo.backupset.backup_finish_date) as duration_minutes,
msdb.dbo.backupset.expiration_date, 
CASE msdb..backupset.type 
	WHEN 'D' THEN 'Database' 
	WHEN 'L' THEN 'Log' 
	WHEN 'I' THEN 'Differential Database'
	WHEN 'F' THEN 'File/filegroup'
	WHEN 'G' THEN 'Differential File'
	WHEN 'P' THEN 'Partial'
	WHEN 'Q' THEN 'Differential Partial'
	ELSE msdb..backupset.type 
END AS backup_type, 
CAST(msdb.dbo.backupset.backup_size /1024.0/1024.0 AS INT) as backup_size_MB, 
CAST(msdb.dbo.backupset.compressed_backup_size /1024.0/1024.0 AS INT) as compressed_backup_size_MB , 
CAST((msdb.dbo.backupset.compressed_backup_size /1024.0/1024.0) / NULLIF(DATEDIFF(SECOND,msdb.dbo.backupset.backup_start_date,msdb.dbo.backupset.backup_finish_date),0) AS DECIMAL(18,2))  as MB_per_Second,
msdb.dbo.backupmediafamily.logical_device_name, 
msdb.dbo.backupmediafamily.physical_device_name, 
msdb.dbo.backupset.name AS backupset_name, 
msdb.dbo.backupset.description
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 30) 
AND msdb..backupset.type ='D' -- uncomment if you want only log
--AND msdb..backupset.type <>'L' -- uncomment if you want all but logs
--AND msdb.dbo.backupset.database_name LIKE '%AxDB%'
--AND msdb..backupset.type ='D'
and msdb.dbo.backupset.backup_finish_date > dateadd(day,-7,getdate())
--AND msdb.dbo.backupset.database_name LIKE '%master'
order by msdb.dbo.backupset.database_name, msdb.dbo.backupset.backup_start_date desc