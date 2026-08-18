/*
Log shipping involves copying a database backup and subsequent transaction log backups
from the primary (source) server and restoring the database and transaction log backups
on one or more secondary (Stand By / Destination) servers. The Target Database is 
in a standby or no-recovery mode on the secondary server(s) which allows subsequent
transaction logs to be backed up on the primary and shipped (or copied) to the secondary
servers and then applied (restored) there.

Requirements:
1. DB must be in full or bulk recovery mode
2. A shared folder for t-log backup files
3. Agent service must be configured properly
4. Use the same SQL versions on both ends
*/

-- Follow the wizard in the db properties

-- check recovery mode
SELECT name, recovery_model_desc FROM sys.databases WHERE name = 'AdventureWorks2019'

--Basic info
--För att se hur log shipping sköter sig
--Run on Primary
SELECT SERVERPROPERTY('ServerName') AS [SQL Server Name], 
  p.primary_database, ps.secondary_server, ps.secondary_database, p.backup_directory
FROM msdb.dbo.log_shipping_primary_databases p
inner join
msdb.dbo.log_shipping_primary_secondaries ps
on p.primary_id = ps.primary_id;

--Last backup
--Run on Primary
SELECT primary_server, primary_database
,last_backup_file, last_backup_date
FROM msdb.dbo.log_shipping_monitor_primary;


--Om det av någon anledning inte skulle gå att få fram info med ovanstående skript kan man köra detta.
exec sp_help_log_shipping_primary_database
@database = 'mindatabas'


--Last copied and restored
--Run on Secondary
SELECT secondary_server, secondary_database, primary_server, primary_database,
last_copied_file, last_copied_date,
last_restored_file, last_restored_date
FROM msdb.dbo.log_shipping_monitor_secondary;
--Om det av någon anledning inte skulle gå att få fram info med ovanstående skript kan man köra detta.
exec sp_help_log_shipping_secondary_database
@secondary_database = 'mindatabas'

--Restore history
--Restore history dbs
--Detta visar aktuell restorehistorik för databaserna.
--Run on Secondary

select * from msdb.dbo.restorehistory
where destination_database_name='mindatabas'

--Restore history log shipping dbs
--Detta kommando ger restorehistorik för logshippingdatabasen.
-- Run on Secondary
SELECT 
[database_name]
,[log_time]
,[log_time_utc]
,[message]
FROM [msdb].[dbo].[log_shipping_monitor_history_detail]
where database_name ='mindatabas'
order by log_time_utc desc

--Ta bort log shipping - MANUELLT
--Om man inte vill följa guiden grafiskt och eta bort log shipping så kan man göra det med följande steg.

--På primära servern körs följande för att ta bort info om sekundära servern från primära servern.
EXEC master.dbo.sp_delete_log_shipping_primary_secondary
@primary_database = N'AdventureWorks'
,@secondary_server = N'LogShippingServer'
,@secondary_database = N'LogShipAdventureWorks'
GO

--På sekundära servern körs följande för att ta bort den sekundära databasen från log shipping.
sp_delete_log_shipping_secondary_database N'LogShipAdventureWorks'

--På primära servern körs följande för att ta bort info om log shipping konfiguration från primära servern.
--Detta tar också bort backupjobben för logshipping.
sp_delete_log_shipping_primary_database N'AdventureWorks'






