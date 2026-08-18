sp_srvrolepermission @srvrolename = 'securityadmin';


--Denna select listar alla logins som finns i en instans
SELECT SERVERPROPERTY('MachineName') AS [Host Name], 
SERVERPROPERTY('ServerName') AS [SQL Server Name],
name as [Login], type_desc as [TYPE], create_date as [Date created], 
default_database_name AS [Default DB]
FROM sys.server_principals
where type in ('S', 'U', 'G')
and name not like 'NT%' and name not like '%SQLServer2005%'
and is_disabled = 0
ORDER by name
GO

--För att ta reda på vilka rättigheter en viss användare eller roll har i en databas kör man följande kommando
use AdventureWorks2017;
GO
exec sp_helprotect @username='alex'

--Denna select listar de logins som har någon serverroll
SELECT SERVERPROPERTY('MachineName') AS [Host Name], 
SERVERPROPERTY('ServerName') AS [SQL Server Name],
name, loginname, sysadmin, securityadmin, serveradmin, 
setupadmin, processadmin, diskadmin, dbcreator, bulkadmin
FROM syslogins
WHERE
(sysadmin <> 0
OR securityadmin <> 0
OR serveradmin <> 0
OR setupadmin <> 0
OR processadmin <> 0
OR diskadmin <> 0
OR dbcreator <> 0
OR bulkadmin <> 0)
and name not like 'NT%' and name not like '%SQLServer2005%';


-- För att få fram alla rättigheter en viss roll tex "public" har i en databas, kan man köra följande fråga
USE AdventureWorks2017 -- Specify database name
GO

SELECT p.[state_desc] AS [PermissionType]
,p.[permission_name] AS [PermissionName]
,USER_NAME(p.[grantee_principal_id]) AS [DatabaseRole]
,CASE p.[class]
WHEN 0
THEN 'Database::' + DB_NAME()
WHEN 1
THEN OBJECT_NAME(major_id)
WHEN 3
THEN 'Schema::' + SCHEMA_NAME(p.[major_id])
END AS [ObjectName]
FROM [sys].[database_permissions] p
WHERE p.[class] IN (0, 1, 3)
AND p.[minor_id] = 0
AND USER_NAME(p.[grantee_principal_id]) = 'Public'

--Om man vill se vilka rättigheter en viss användare har i en databas kör man följande:
use AdventureWorks2017 --- Change db name
go
EXECUTE AS user = 'alex';
SELECT * FROM fn_my_permissions(NULL, 'DATABASE')
ORDER BY subentity_name, permission_name ;
REVERT;
GO

--Vill man bara se sina egna rättigheter kör man
use AdventureWorks2017 --- Change db name
go
SELECT * FROM fn_my_permissions(NULL, 'DATABASE')
ORDER BY subentity_name, permission_name ;
GO

--Om man vill kolla vilka användare som en viss domängrupp eller windowsgrupp har så kör man följande:
exec master..xp_logininfo 'domain\group' ,members

/*CMD*/
--Om inte ovantående funkar i sql kan man köra i cmd detta:
net group <domängrupp> /DOMAIN

--Om man vi ta reda på egenskaper på en domänanvädare kan man köra detta i kommandoprompten:
net user <användarnamn> /DOMAIN


--Denna kod skapar en Server Audit.
--Den filtrerar bort alla händelser som görs med de angivna login-namnen.
USE [master]
GO
CREATE SERVER AUDIT SPECIFICATION [AuditPrivUsers_spec]
FOR SERVER AUDIT [AuditPrivUsers]
ADD (AUDIT_CHANGE_GROUP)
ADD (DATABASE_CHANGE_GROUP),  -- captures ALTER/DROP/CREATE database
ADD (DATABASE_OBJECT_CHANGE_GROUP),  -- captures CREATE/DROP schema
ADD (SCHEMA_OBJECT_CHANGE_GROUP)   -- captures CREATE/ALTER/DROP table
GO

--Och sedan för att aktivera den
USE [master]
GO
ALTER SERVER AUDIT SPECIFICATION [AuditPrivUsers_spec]
WITH ( STATE = ON);

--Denna kod sätter upp en Database Audit Specification.
--Den fångar INSERT/UPDATE/DELETE för rollen “dbo” (som sysadmins är i databasen) samd rollen “db_owner”
USE [db-name]
GO
CREATE DATABASE AUDIT SPECIFICATION [AuditPrivUsersDB_spec]
FOR SERVER AUDIT [AuditPrivUsers]  -- change name according to the actual Server Audit Name
-- Capture sysadmins --
ADD (DELETE ON DATABASE::[db-name] BY [dbo]),
ADD (INSERT ON DATABASE::[db-name] BY [dbo]),
ADD (UPDATE ON DATABASE::[db-name] BY [dbo]),
-- Capture dbowners
ADD (DELETE ON DATABASE::[db-name] BY [db_owner]),
ADD (INSERT ON DATABASE::[db-name] BY [db_owner]),
ADD (UPDATE ON DATABASE::[db-name] BY [db_owner])
GO