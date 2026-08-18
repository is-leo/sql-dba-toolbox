
/*
By LI:
Namn														Aktuell		Ny tid	    Frekvens	    Kommänter
DBA - DatabaseIntegrityCheck - SYSTEM_DATABASES-Schedule	05:00		19:00		Daily			tar max 10 sekunder
DBA - DatabaseIntegrityCheck - USER_DATABASES-Schedule		02:30		19:05		Daily			anpassa, körs på söndagar just nu, kör dagligen om det går
DBA - IndexOptimize - USER_DATABASES-Schedule				22:00		22:00		Daily			anpassa
DBA - Database_Full_Backup - SYSTEM_DATABASES-Schedule		06:00		23:00		Daily		    öka starttiden m 10 sec på varje instans
DBA - Database_Full_Backup - USER_DATABASES-Schedule		23:00		23:05		Daily			anpassa 
DBA - sp_delete_backuphistory-Schedule						03:52		06:00		Sunday			tar några sekunder
DBA - Output_File_Cleanup-Schedule							04:45		06:05		Sunday			tar några sekunder
DBA - purge_jobhistory-Schedule'							05:15		06:10		Sunday			tar några sekunder
DBA - CommandLog_Cleanup-Schedule'							04:45		06:15		Sunday			tar några sekunder

*/

USE msdb

DECLARE @Full_BackupSystem AS INT = 230345--öka m 5 sekunder
DECLARE @Full_BackupUser  AS INT = 041900 --kolla i tabellen, anpassad
DECLARE @LogBackupStarttime AS INT = 001200 -- öka med 1 minut till 15
DECLARE @IntegrityCheckUser  AS INT = 190500
DECLARE @IndexOptimize AS INT = 221000 -- kolla i tabellen, anpassad



-- Backup Full System Databases Schedule --
DECLARE @DatabaseBackup_SystemFullScheduleID AS int
EXEC sp_add_schedule
	@schedule_name =  N'DBA - Database_Full_Backup - SYSTEM_DATABASES-Schedule'
    , @enabled = 1
    , @freq_type = 4
    , @freq_interval = 1
	, @freq_recurrence_factor = 1
    , @active_start_time = @Full_BackupSystem
	, @schedule_id = @DatabaseBackup_SystemFullScheduleID OUTPUT
EXEC sp_attach_schedule
	@job_name = N'DBA - DatabaseBackup - SYSTEM_DATABASES - FULL'
	, @schedule_id = @DatabaseBackup_SystemFullScheduleID
--


-- Backup Full User Databases Schedule --
DECLARE @DatabaseBackup_UserFullScheduleID AS int
EXEC sp_add_schedule
	@schedule_name =  N'DBA - Database_Full_Backup - USER_DATABASES-Schedule'
    , @enabled = 1
    , @freq_type = 4
    , @freq_interval = 1
	, @freq_recurrence_factor=1
    , @active_start_time = @Full_BackupUser
	, @schedule_id = @DatabaseBackup_UserFullScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - DatabaseBackup - USER_DATABASES - FULL'
	, @schedule_id = @DatabaseBackup_UserFullScheduleID
--

---- Backup Diff User Databases Schedule --
--DECLARE @DatabaseBackup_UserDiffScheduleID AS int
--EXEC sp_add_schedule
--	@schedule_name =  N'DBA - DatabaseBackup-USER_DATABASES-DIFF-Schedule'
--    , @enabled = 1
--    , @freq_type = 8
--    , @freq_interval = 125
--	, @freq_recurrence_factor=1
--    , @active_start_time = 020000
--	, @schedule_id = @DatabaseBackup_UserDiffScheduleID OUTPUT
--EXEC sp_attach_schedule 
--	@job_name = N'DBA - DatabaseBackup - USER_DATABASES - DIFF'
--	, @schedule_id = @DatabaseBackup_UserDiffScheduleID
--
--

---- Backup Diff User Databases Schedule --
--DECLARE @DatabaseBackup_UserDiffScheduleID AS int
--EXEC sp_add_schedule
--	@schedule_name =  N'DBA - DatabaseBackup-USER_DATABASES-DIFF-Schedule'
--    , @enabled = 1
--    , @freq_type = 8
--    , @freq_interval = 125
--	, @freq_recurrence_factor=1
--    , @active_start_time = 020000
--	, @schedule_id = @DatabaseBackup_UserDiffScheduleID OUTPUT
--EXEC sp_attach_schedule 
--	@job_name = N'DBA - DatabaseBackup - USER_DATABASES - DIFF'
--	, @schedule_id = @DatabaseBackup_UserDiffScheduleID
--

-- Backup Log User Databases Schedule --
DECLARE @DatabaseBackup_UserLogScheduleID AS int
EXEC sp_add_schedule
	@schedule_name =  N'DBA - Database_Log_Backup - USER_DATABASES-Schedule'
    , @enabled = 1
    , @freq_type = 4
    , @freq_interval = 1
    , @freq_subday_type = 0x4
    , @freq_subday_interval = 15
    , @active_start_time = @LogBackupStarttime
    , @active_end_time = 235959
	, @schedule_id = @DatabaseBackup_UserLogScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - DatabaseBackup - USER_DATABASES - LOG'
	, @schedule_id = @DatabaseBackup_UserLogScheduleID
--


-- Integrity Check System Databases Schedule --
DECLARE @IntegrityCheck_SystemScheduleID AS int
EXEC sp_add_schedule 
	@schedule_name = N'DBA - DatabaseIntegrityCheck - SYSTEM_DATABASES-Schedule'
	, @enabled = 1
	, @freq_type = 4
	, @freq_interval = 1
	, @active_start_time = 190000
	, @schedule_id = @IntegrityCheck_SystemScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - DatabaseIntegrityCheck - SYSTEM_DATABASES'
	, @schedule_id = @IntegrityCheck_SystemScheduleID
--

-- Integrity Check User Databases Schedule --
DECLARE @IntegrityCheck_UserScheduleID AS int
EXEC sp_add_schedule 
	@schedule_name = N'DBA - DatabaseIntegrityCheck - USER_DATABASES-Schedule'
	, @enabled = 1
	, @freq_type = 4 -- previously 8
	, @freq_interval = 1
	--, @freq_subday_type = 1
	--, @freq_recurrence_factor = 1
	, @active_start_time = @IntegrityCheckUser
	, @schedule_id = @IntegrityCheck_UserScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - DatabaseIntegrityCheck - USER_DATABASES'
	, @schedule_id = @IntegrityCheck_UserScheduleID
--

-- Index Optimize Schedule --
DECLARE @IndexOptimize_ScheduleID AS int
EXEC sp_add_schedule
	@schedule_name =  N'DBA - IndexOptimize - USER_DATABASES-Schedule'
    , @enabled = 1
    , @freq_type = 4
    , @freq_interval = 1
    , @active_start_time = @IndexOptimize
	, @schedule_id = @IndexOptimize_ScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - IndexOptimize - USER_DATABASES'
	, @schedule_id = @IndexOptimize_ScheduleID ;


-- sp_delete_backuphistory --
DECLARE @delete_backuphistory_ScheduleID AS int
EXEC sp_add_schedule
	@schedule_name =  N'DBA - sp_delete_backuphistory-Schedule'
    , @enabled = 1
    , @freq_type = 8
    , @freq_interval = 1
    , @freq_subday_type = 1
	, @freq_recurrence_factor = 1
    , @freq_subday_interval = 0
    , @active_start_time = 060000
    , @active_end_time = 235959
	, @schedule_id = @delete_backuphistory_ScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - sp_delete_backuphistory'
	, @schedule_id = @delete_backuphistory_ScheduleID


-- Output File Cleanup Schedule --
DECLARE @Output_File_Cleanup_ScheduleID AS int
--DECLARE @StartDate INT
--set @StartDate = convert(char(10),dateadd(mm, +1, getdate()),112)
EXEC sp_add_schedule
	@schedule_name =  N'DBA - Output_File_Cleanup-Schedule'
    , @enabled = 1
    , @freq_type = 8
    , @freq_interval = 1
    , @freq_subday_type = 1
	, @freq_recurrence_factor = 1
    , @freq_subday_interval = 0
    , @active_start_time = 060500
    , @active_end_time = 235959
--	, @active_start_date= @StartDate
	, @schedule_id = @Output_File_Cleanup_ScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - Output File Cleanup'
	, @schedule_id = @Output_File_Cleanup_ScheduleID


-- Remove Old Log Files Schedule --
DECLARE @purge_jobhistory_ScheduleID AS int
EXEC sp_add_schedule
	@schedule_name =  N'DBA - purge_jobhistory-Schedule'
    , @enabled = 1
    , @freq_type = 8
    , @freq_interval = 1
    , @freq_subday_type = 1
	, @freq_recurrence_factor = 1
    , @freq_subday_interval = 0
    , @active_start_time = 061000
    , @active_end_time = 235959
	, @schedule_id = @purge_jobhistory_ScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - sp_purge_jobhistory'
	, @schedule_id = @purge_jobhistory_ScheduleID


-- CommandLog Cleanup Schedule --
DECLARE @CommandLog_Cleanup_ScheduleID AS int
--DECLARE @StartDate INT
--set @StartDate = convert(char(10),dateadd(mm, +1, getdate()),112)
EXEC sp_add_schedule
	@schedule_name =  N'DBA - CommandLog_Cleanup-Schedule'
    , @enabled = 1
    , @freq_type = 8
    , @freq_interval = 1
    , @freq_subday_type = 1
	, @freq_recurrence_factor = 1
    , @freq_subday_interval = 0
    , @active_start_time = 061500
    , @active_end_time = 235959
--	, @active_start_date= @StartDate
	, @schedule_id = @CommandLog_Cleanup_ScheduleID OUTPUT
EXEC sp_attach_schedule 
	@job_name = N'DBA - CommandLog Cleanup'
	, @schedule_id = @CommandLog_Cleanup_ScheduleID

