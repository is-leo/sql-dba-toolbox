USE MASTER
IF EXISTS
(SELECT * FROM sys.server_principals
 WHERE name = N'BUILTIN\Administrators')
 DROP LOGIN [BUILTIN\Administrators]
 GO