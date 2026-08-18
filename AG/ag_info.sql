-- listener, ip, group, db all in one
select SERVERPROPERTY('MachineName') AS [Host Name], SERVERPROPERTY('ServerName') AS [SQL Server Name],
  ag.name [AAG], l.dns_name, l.port, lip.ip_Address, agdb.database_name as [DB]
from [sys].[availability_groups] ag
inner join
[sys].[availability_databases_cluster] agdb
on ag.group_id = agdb.group_id
inner join
[sys].[availability_group_listeners] l
on agdb.group_id = l.group_id
inner join
[sys].[availability_group_listener_ip_addresses] lip
on l.listener_id = lip.listener_id
order by 1, 5

--about endpoints

SELECT * FROM sys.endpoints
SELECT * FROM sys.tcp_endpoints