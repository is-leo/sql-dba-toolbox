-- non-problematic & generally expeted wait types

SELECT DISTINCT
 wt.wait_type
FROM sys.dm_os_waiting_tasks AS wt
 JOIN sys.dm_exec_sessions AS s ON wt.session_id = s.session_id
WHERE s.is_user_process = 0