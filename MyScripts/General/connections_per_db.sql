SELECT db_name(dbid) as DatabaseName, count(dbid) as NoOfConnections,
loginame as LoginName
FROM sys.sysprocesses
WHERE dbid > 0
GROUP BY dbid, loginame
ORDER BY db_name(dbid) asc, loginame ASC

select count(loginame)
from sys.sysprocesses
where dbid > 0

