EXEC sp_MSforeachdb '
USE ?
SELECT name AS Assembly_Name, permission_set_desc
FROM sys.assemblies
WHERE is_user_defined = 1'