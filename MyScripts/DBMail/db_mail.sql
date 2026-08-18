
--Source: https://www.youtube.com/watch?v=WjhJJxZeU9w

--check if service broker & db mail extend sp enabled
SELECT is_broker_enabled
FROM sys.databases 
WHERE name = 'msdb'

SELECT * FROM sys.configurations
WHERE name = 'Database Mail XPs'

--enable dm XPs
EXEC sp_configure 'show advanced option', '1'
RECONFIGURE
GO

EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE
GO


--reccomended alerts 

USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'DBAs', @notification_method = 7;
GO
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=60,
@include_event_description_in=1,
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'DBAs', @notification_method = 7;
GO


--to test run
RAISERROR(N'Test alert!',20,1)WITH LOG;

EXEC msdb.dbo.sp_send_dbmail
     @profile_name = 'Notification',
     @recipients = 'leo.ismatov@sqlservice.se',
     @body = 'The database mail configuration was completed successfully.',
     @subject = 'Automated Success Message';
GO


--troubleshoot
SELECT * FROM msdb.dbo.sysmail_event_log;

SELECT [sysmail_server].[account_id],
       [sysmail_account].[name] AS [Account Name],
       [servertype],
       [servername] AS [SMTP Server Address],
       [Port]
FROM [msdb].[dbo].[sysmail_server]
     INNER JOIN [msdb].[dbo].[sysmail_account] 
	 ON [sysmail_server].[account_id] = [sysmail_account].[account_id];




