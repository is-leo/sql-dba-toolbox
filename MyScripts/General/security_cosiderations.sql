/* Secutiy Considertions 

1. Change widely-known default TCP/IP ports (e.x. 1433) to a custom one

2. Disable and rename sa account (ensure another account has sys.admin rights)

3. Disable auto close & shrink

4. Revoke connect from guest

5. Remove Orhpaned users or alternatively map

6. Review all users and ensure they don't have excessive permissions except admins


7. Local Windows groups should not be used as logins for SQL Server instances. 
		Rationale: Allowing local Windows groups as SQL Logins provides a loophole whereby anyone with OS
		level administrator rights (and no SQL Server rights) could add users to the local Windows groups 
		and thereby give themselves or others access to the SQL Server instance

--to audit
USE [master] 
GO 
SELECT pr.[name] AS LocalGroupName, pe.[permission_name], pe.[state_desc] 
FROM sys.server_principals pr JOIN sys.server_permissions pe ON pr.[principal_id] = pe.[grantee_principal_id]
WHERE pr.[type_desc] = 'WINDOWS_GROUP' AND pr.[name] like CAST(SERVERPROPERTY('MachineName') AS nvarchar) + '%';

8. Ensure that only default permissions are granted to role 'public'

--to check if extra permissions are granted run
SELECT * FROM master.sys.server_permissions 
WHERE (grantee_principal_id = SUSER_SID(N'public') 
and state_desc LIKE 'GRANT%') 
AND NOT (state_desc = 'GRANT' and [permission_name] = 'VIEW ANY DATABASE'and class_desc = 'SERVER')
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 2)
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 3)
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 4) 
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 5);

9. Ensure the public role in the msdb database is not granted access to SQL Agent proxies 
USE [msdb] 
GO 
SELECT sp.name AS proxyname FROM dbo.sysproxylogin spl 
JOIN sys.database_principals dp ON dp.sid = spl.sid 
JOIN sysproxies sp ON sp.proxy_id = spl.proxy_id WHERE principal_id = USER_ID('public');

10. Increase maximum number of error log files to 12. 

11.	Setting CLR Assembly Permission Sets to SAFE_ACCESS will prevent assemblies 
from accessing external system resources such as files, the network, environment variables,
or the registry. Assemblies with EXTERNAL_ACCESS or UNSAFE permission sets can be used to access
sensitive areas of the operating system, steal and/or transmit data and alter the state and
other protection measures of the underlying Windows Operating System. Assemblies which 
are Microsoft-created (is_user_defined = 0) are excluded from this check as they 
are required for overall system functionality.

Execute the following SQL statement:
SELECT name, permission_set_desc FROM sys.assemblies WHERE is_user_defined = 1;

All the returned assemblies should show SAFE_ACCESS in the permission_set_desc column. 
Remediation: ALTER ASSEMBLY WITH PERMISSION_SET = SAFE