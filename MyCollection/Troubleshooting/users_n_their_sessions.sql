--  Get SQL users that are connected and how many sessions they have 
SELECT  login_name , s.host_name,
        COUNT(session_id) AS [session_count]
FROM    sys.dm_exec_sessions s
GROUP BY login_name, s.host_name
ORDER BY COUNT(session_id) DESC ;

exec sp_who2