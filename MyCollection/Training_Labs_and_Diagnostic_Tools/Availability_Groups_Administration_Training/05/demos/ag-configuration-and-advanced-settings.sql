
/* 
settings used in demos while configuring AbacosAG

https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-availability-group-transact-sql?view=sql-server-2017
*/


-- synchronous commit and auto failover on the HA pair
USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT) -- ASYNCHRONOUS_COMMIT
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (FAILOVER_MODE = AUTOMATIC) -- MANUAL
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosB' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT) -- ASYNCHRONOUS_COMMIT
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosB' WITH (FAILOVER_MODE = AUTOMATIC) -- MANUAL
GO

--asynchronous commit and manual failover on the DR replica
USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosC' WITH (FAILOVER_MODE = MANUAL) -- AUTOMATIC
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosC' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT) -- SYNCHRONOUS_COMMIT
GO


USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows] SET(
DB_FAILOVER = ON -- OFF -- controls 'enhanced database health detection'
);
GO
ALTER AVAILABILITY GROUP [AGWindows] SET(
DTC_SUPPORT = NONE -- PER_DB -- controls cross database transaction support
);
GO
ALTER AVAILABILITY GROUP [AGWindows] SET(
REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0
   -- 0 = default
   -- 1 = data protection (HA only if 2+ synch secondaries)
   -- 2 = data protection (HA only if 3+ synch secondaries)
   -- linux setting configured by external cluster
);
GO

ALTER AVAILABILITY GROUP [AGWindows] SET(
	FAILURE_CONDITION_LEVEL = 3  -- 1,2,3,4,5
	-- 1=service offline, 
	-- 2=unable to connect to cluster + timeout expired
	-- 3=critical errors (default)
	-- 4=moderate errors
	-- 5=any qualifying condition
);
GO

ALTER AVAILABILITY GROUP [AGWindows] SET(
	HEALTH_CHECK_TIMEOUT = 30000 -- milliseconds
    -- together with above is "Flexible Failover Policy"
);
GO


-- set up read only secondary replicas
USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)) -- READ_ONLY, NO
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)) -- READ_ONLY, NO
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL)) -- READ_ONLY, NO
GO

-- set up read routing urls and lists

USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL = N'TCP://abacosa.abacos.com:1433'))
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'AbacosB',N'AbacosC')))
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosB' WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL = N'TCP://abacosb.abacos.com:1433'))
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosB' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'AbacosA',N'AbacosC')))
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosC' WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL = N'TCP://abacosc.abacos.com:1433'))
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosC' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'AbacosB',N'AbacosA')))
GO

-- configure backup preferences

USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosA' WITH (BACKUP_PRIORITY = 50)
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosB' WITH (BACKUP_PRIORITY = 50)
GO

ALTER AVAILABILITY GROUP [AGWindows]
MODIFY REPLICA ON N'AbacosC' WITH (BACKUP_PRIORITY = 0)
GO

ALTER AVAILABILITY GROUP [AGWindows] 
	SET(AUTOMATED_BACKUP_PREFERENCE = SECONDARY);  -- PRIMARY, SECONDARY_ONLY, NONE 
GO

-- add a listener

USE [master]
GO
ALTER AVAILABILITY GROUP [AGWindows]
ADD LISTENER N'AbacosAG' (
WITH IP
((N'10.0.128.200', N'255.255.240.0'),
(N'10.0.32.200', N'255.255.224.0')
)
, PORT=1433);
GO