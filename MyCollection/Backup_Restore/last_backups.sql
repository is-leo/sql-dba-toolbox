-- Last backup information by database  (Query 8) (Last Backup By Database)
SELECT ISNULL(d.[name], bs.[database_name]) AS [Database], d.recovery_model_desc AS [Recovery Model], 
       d.log_reuse_wait_desc AS [Log Reuse Wait Desc],
    MAX(CASE WHEN [type] = 'D' THEN bs.backup_finish_date ELSE NULL END) AS [Last Full Backup],
	MAX(CASE WHEN [type] = 'D' THEN bmf.physical_device_name ELSE NULL END) AS [Last Full Backup Location],
    MAX(CASE WHEN [type] = 'I' THEN bs.backup_finish_date ELSE NULL END) AS [Last Differential Backup],
	MAX(CASE WHEN [type] = 'I' THEN bmf.physical_device_name ELSE NULL END) AS [Last Differential Backup Location],
    MAX(CASE WHEN [type] = 'L' THEN bs.backup_finish_date ELSE NULL END) AS [Last Log Backup],
	MAX(CASE WHEN [type] = 'L' THEN bmf.physical_device_name ELSE NULL END) AS [Last Log Backup Location]
FROM sys.databases AS d WITH (NOLOCK)
LEFT OUTER JOIN msdb.dbo.backupset AS bs WITH (NOLOCK)
ON bs.[database_name] = d.[name]
LEFT OUTER JOIN msdb.dbo.backupmediafamily AS bmf WITH (NOLOCK)
ON bs.media_set_id = bmf.media_set_id 
AND bs.backup_finish_date > GETDATE()- 30
WHERE d.name <> N'tempdb'
GROUP BY ISNULL(d.[name], bs.[database_name]), d.recovery_model_desc, d.log_reuse_wait_desc, d.[name] 
ORDER BY d.recovery_model_desc, d.[name] OPTION (RECOMPILE);