--ENABLE DAC--

SELECT * FROM sys.configurations
WHERE name =  'remote admin connections'

--this sets the value
EXEC sp_configure 'remote admin connections', 1
GO

--this make it take effect
RECONFIGURE
GO

--To connect with DAC click on New Query or Database Engine Query and put 'ADMIN:' before the server name!