/*This script schedules the following Ola Hallengren maintenance jobs:
	CommandLog Cleanup
	DatabaseBackup - SYSTEM_DATABASES - FULL
	DatabaseBackup - USER_DATABASES - DIFF
	DatabaseBackup - USER_DATABASES - FULL
	DatabaseBackup - USER_DATABASES - LOG
	DatabaseIntegrityCheck - SYSTEM_DATABASES
	DatabaseIntegrityCheck - USER_DATABASES
	IndexOptimize - USER_DATABASES
	Output File Cleanup */

USE msdb ;  
DECLARE
-- Adjust schedule times 
@CommandLog_CleanUp_time int = 190000,
@Database_BackupSYSTEM_DATABASES_time int = 200000,
@Database_BackupUSER_DATABASES_DIFF_time int = 210000,
@DatabaseBackup_USER_DATABASES_FULL_time int = 220000,
@DatabaseBackup_USER_DATABASES_LOG_time int = 230000,
@DatabaseIntegrityCheck_SYSTEM_DATABASES_time int = 000000,
@DatabaseIntegrityCheck_USER_DATABASES_time int = 010000,
@IndexOptimize_USER_DATABASES_time int = 020000,
@Output_File_Cleanup_time int = 030000

-- create CommandLogCleanUp schedule        
EXEC sp_add_schedule  
    @schedule_name = N'CommandLog Cleanup - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @CommandLog_CleanUp_time;  
-- attachs the schedule to the job  
EXEC sp_attach_schedule  
   @job_name = N'CommandLog CleanUp',  
   @schedule_name = N'CommandLog Cleanup - Schedule' ;  


-- create DatabaseBackup - SYSTEM_DATABASES - FULL schedule   
EXEC sp_add_schedule  
    @schedule_name = N'DatabaseBackup - SYSTEM_DATABASES - FULL - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @Database_BackupSYSTEM_DATABASES_time;
-- attach the schedule to the job  
EXEC sp_attach_schedule  
   @job_name = N'DatabaseBackup - SYSTEM_DATABASES - FULL',  
   @schedule_name = N'DatabaseBackup - SYSTEM_DATABASES - FULL - Schedule' ;  
  

-- create DatabaseBackup - USER_DATABASES - DIFF schedule    
EXEC sp_add_schedule  
    @schedule_name = N'DatabaseBackup - USER_DATABASES - DIFF - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @Database_BackupUSER_DATABASES_DIFF_time;  
-- attach the schedule to the job
EXEC sp_attach_schedule  
   @job_name = N'DatabaseBackup - USER_DATABASES - DIFF',  
   @schedule_name = N'DatabaseBackup - USER_DATABASES - DIFF - Schedule' ;  
  

-- create DatabaseBackup - USER_DATABASES - FULL schedule  
EXEC sp_add_schedule  
    @schedule_name = N'DatabaseBackup - USER_DATABASES - FULL - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @DatabaseBackup_USER_DATABASES_FULL_time;  
-- attach the schedule to the job 
EXEC sp_attach_schedule  
   @job_name = N'DatabaseBackup - USER_DATABASES - FULL',  
   @schedule_name = N'DatabaseBackup - USER_DATABASES - FULL - Schedule' ;   


-- create DatabaseBackup - USER_DATABASES - LOG schedule   
EXEC sp_add_schedule  
    @schedule_name = N'DatabaseBackup - USER_DATABASES - LOG - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @DatabaseBackup_USER_DATABASES_LOG_time;  
-- attach the schedule to the job 
EXEC sp_attach_schedule  
   @job_name = N'DatabaseBackup - USER_DATABASES - LOG',  
   @schedule_name = N'DatabaseBackup - USER_DATABASES - LOG - Schedule' ;  
  

-- create DatabaseIntegrityCheck - SYSTEM_DATABASES schedule  
EXEC sp_add_schedule  
    @schedule_name = N'DatabaseIntegrityCheck - SYSTEM_DATABASES - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @DatabaseIntegrityCheck_SYSTEM_DATABASES_time;  
-- attach the schedule to the job
EXEC sp_attach_schedule  
   @job_name = N'DatabaseIntegrityCheck - SYSTEM_DATABASES',  
   @schedule_name = N'DatabaseIntegrityCheck - SYSTEM_DATABASES - Schedule' ;  
 

-- create DatabaseIntegrityCheck - USER_DATABASES schedule 
EXEC sp_add_schedule  
    @schedule_name = N'DatabaseIntegrityCheck - USER_DATABASES - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @DatabaseIntegrityCheck_USER_DATABASES_time;  
-- attach the schedule to the job 
EXEC sp_attach_schedule  
   @job_name = N'DatabaseIntegrityCheck - USER_DATABASES',  
   @schedule_name = N'DatabaseIntegrityCheck - USER_DATABASES - Schedule' ;  
 
 
-- creates IndexOptimize - USER_DATABASES schedule
EXEC sp_add_schedule  
    @schedule_name = N'IndexOptimize - USER_DATABASES - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @IndexOptimize_USER_DATABASES_time;  
-- attach the schedule to the job 
EXEC sp_attach_schedule  
   @job_name = N'IndexOptimize - USER_DATABASES',  
   @schedule_name = N'IndexOptimize - USER_DATABASES - Schedule' ;  
  
-- create Output File Cleanup schedule
EXEC sp_add_schedule  
    @schedule_name = N'Output File Cleanup - Schedule' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = @Output_File_Cleanup_time;  
-- attach the schedule to the job 
EXEC sp_attach_schedule  
   @job_name = N'Output File Cleanup',  
   @schedule_name = N'Output File Cleanup - Schedule' ;  
 