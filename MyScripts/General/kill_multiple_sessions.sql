-- How to kill multiple sessions
SELECT 'KILL ' + CAST(session_id as varchar(100)) AS Sessions_to_kill
FROM sys.dm_exec_requests where session_id in (55,69,72)
GO


sp_who  @loginame = 'AzureAD\LeoIsmatov'

select * FROM sys.dm_exec_requests

