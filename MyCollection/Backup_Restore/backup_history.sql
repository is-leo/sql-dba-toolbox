
-- Get Backup History for required database
SELECT TOP 100
s.database_name,
m.physical_device_name,
CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize,
CAST(DATEDIFF(second, s.backup_start_date,
s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
s.backup_start_date,
CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
CASE s.[type] WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END AS BackupType,
s.server_name,
s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
--WHERE s.database_name = DB_NAME() -- Remove this line for all the database
ORDER BY backup_start_date DESC, backup_finish_date
GO


--Alternative 2
SELECT
CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
msdb.dbo.backupset.database_name,
msdb.dbo.backupset.backup_start_date,
msdb.dbo.backupset.backup_finish_date,
--DATEDIFF(SECOND, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date) AS Duration,
msdb.dbo.backupset.expiration_date,
CASE msdb..backupset.type
WHEN 'D' THEN 'Database'
WHEN 'L' THEN 'Log'
WHEN 'I' THEN 'Differential'
END AS backup_type,
msdb.dbo.backupset.backup_size,
msdb.dbo.backupmediafamily.logical_device_name,
msdb.dbo.backupmediafamily.physical_device_name,
msdb.dbo.backupset.name AS backupset_name,
msdb.dbo.backupset.description
FROM msdb.dbo.backupmediafamily
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7)
ORDER BY
msdb.dbo.backupset.database_name,
msdb.dbo.backupset.backup_finish_date

--Alternative 3
select b.database_name, mf.physical_device_name, b.backup_finish_date, b.type, b.description
FROM msdb.dbo.backupset b
join msdb.dbo.backupmediafamily mf
on b.media_set_id = mf.media_set_id
-- where b.database_name ='dbname'     -- här anges databasnamnet
where backup_finish_date > GETDATE ()-2   -- skippa denna rad ifall du vill ha all historik.
order by b.database_name, b.backup_finish_date desc