/*Systemvyer
Sammanfattande lista från sysmail_account med info om uppsatta mail-konton
*/

select SERVERPROPERTY('MachineName') AS [HostName], 
SERVERPROPERTY('InstanceName') AS [Instance], name as [Account], email_address, display_name
from msdb.dbo.sysmail_account
 

/*Alla systemvyer relaterade till dbmail

select * from  msdb.dbo.sysmail_account

select * from  msdb.dbo.sysmail_configuration

select * from msdb.dbo.sysmail_log

select * from msdb.dbo.sysmail_mailitems

select * from msdb.dbo.sysmail_profile

select * from msdb.dbo.sysmail_profileaccount

select * from msdb.dbo.sysmail_server

select * from msdb.dbo.sysmail_servertype
*/

--Mailservrar
--Ta reda på vilka mailservrar som är konfigurerade i SQL server
select servertype, servername, port, username
from msdb.dbo.sysmail_server;
 

--Setup
--Dessa är stegen för att sätta upp dbmail

--Create Database mail account
exec msdb.dbo.sysmail_add_account_sp
@account_name = 'DB-mail-scomom_wfs0017a',
@email_address = 'wfs0017a_scomom@seb.se',
@display_name = 'SEB scomom wfs0017a',
@mailserver_name = 'smtp2010.sebank.se';
 

--Create Database mail profile
exec msdb.dbo.sysmail_add_profile_sp
@profile_name = 'LogShippingJob';
 

--Add account to profile
EXEC msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = 'LogShippingJob',
@account_name = 'DB-mail-scomom_wfs0017a',
@sequence_number =1;
 

--Grant access to profile to all users in msdb
EXEC msdb.dbo.sysmail_add_principalprofile_sp
@profile_name = 'LogShippingJob',
@principal_name = 'public',
@is_default =1;
 

--Send mail
--Så här gör man för att testa att skicka mail från Management Studio
EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'Notification',
@recipients = 'h09aliis@gmail.com',
@subject = 'mailtest ',
@body = 'Testar db mail '
 

--Remove
--Delete profile
exec msdb.dbo.sysmail_delete_profile_sp @profile_name = 'LogShippingJob';

--Delete account
exec msdb.dbo.sysmail_delete_account_sp @account_name = 'DB-mail-scomom_wfs0017a';

--Delete maillog
EXEC msdb.dbo.sysmail_delete_log_sp
 

