/*
För att kolla vilka anslutningar som finns kan man använda denna sats 
som joinar dm_exec_sessions med sysprocesses. Filtrera efter behag. */ 


select CONVERT(VARCHAR(19), GETDATE(),120) as [CheckTime],
DB_NAME(sp.dbid) as [DbName],
es.host_name as [HostName],
ec.client_net_address,
es.[program_name] as program,
es.login_name as [LoginName]
from sys.dm_exec_sessions es
INNER JOIN
sys.sysprocesses sp
ON
es.session_id = sp.spid
INNER JOIN
sys.dm_exec_connections ec
ON 
es.session_id = ec.session_id
where
es.session_id > 50
and
sp.dbid > 4
order by DB_NAME(sp.dbid), es.host_name, es.login_name
go