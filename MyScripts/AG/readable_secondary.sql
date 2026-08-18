/*
To connect with the secondary database for read-only
connections, specify the argument ApplicationIntent=ReadOnly
in the additional connection parameters. 
If you do not specify the ReadOnly argument in 
the connection string, you cannot use the secondary
database for data read.
*/

--read intent only
USE [master]
GO
ALTER AVAILABILITY GROUP [AG-MyNewDB-Demo]
MODIFY REPLICA ON N'SQLNODE1\INST1' 
WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = READ_ONLY))
GO

USE [master]
GO
ALTER AVAILABILITY GROUP [AG-MyNewDB-Demo]
MODIFY REPLICA ON N'SQLNODE2\INST1' 
WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = READ_ONLY))
GO

--read only
USE [master]
GO
ALTER AVAILABILITY GROUP [AG-MyNewDB-Demo]
MODIFY REPLICA ON N'SQLNODE1\INST1' 
WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO

USE [master]
GO
ALTER AVAILABILITY GROUP [AG-MyNewDB-Demo]
MODIFY REPLICA ON N'SQLNODE2\INST1' 
WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL))
GO

