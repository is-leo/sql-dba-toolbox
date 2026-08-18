--to check if extra permissions are granted run
SELECT * FROM master.sys.server_permissions 
WHERE (grantee_principal_id = SUSER_SID(N'public') 
and state_desc LIKE 'GRANT%') AND NOT (state_desc = 'GRANT' and [permission_name] = 'VIEW ANY DATABASE'
and class_desc = 'SERVER') AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' 
and class_desc = 'ENDPOINT' and major_id = 2) AND NOT (state_desc = 'GRANT' 
and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 3) 
AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' 
and major_id = 4) AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT'
and class_desc = 'ENDPOINT' and major_id = 5);