SELECT dcs.database_name
	FROM sys.dm_hadr_database_replica_states AS drs
	JOIN sys.availability_replicas AS r ON drs.replica_id = r.replica_id
	JOIN sys.availability_groups AS g ON g.group_id = drs.group_id
	JOIN sys.dm_hadr_database_replica_cluster_states AS dcs ON dcs.group_database_id = drs.group_database_id AND dcs.replica_id = drs.replica_id
	JOIN sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = drs.replica_id
	WHERE drs.database_state_desc = 'ONLINE'
	AND ars.is_local = 1
	AND ars.role_desc = 'PRIMARY'
UNION
SELECT name
	FROM sys.databases d
	LEFT OUTER JOIN sys.database_mirroring dm on dm.database_id = d.database_id
	WHERE state_desc = 'ONLINE'
	AND d.database_id NOT IN(SELECT database_id FROM sys.dm_hadr_database_replica_states)
	AND dm.database_id NOT IN(SELECT database_id FROM sys.database_mirroring WHERE mirroring_role_desc = 'MIRROR')
