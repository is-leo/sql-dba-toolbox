SELECT [Login] = login_name 
    ,[Last Login Time] = MAX(login_time)
FROM sys.dm_exec_sessions
GROUP BY [login_name];
