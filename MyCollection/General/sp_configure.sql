--check current configurations
SELECT name, description, value_in_use, is_advanced  
FROM sys.configurations;   
GO


--value	sql_variant	Configured value for this option.
--minimum	sql_variant	Minimum value for the configuration option.
--maximum	sql_variant	Maximum value for the configuration option.
--value_in_use	sql_variant	Running value currently in effect for this option.
--is_dynamic	bit	1 = The variable that takes effect when the RECONFIGURE statement is executed.
--is_advanced	bit	1 = The variable is displayed only when the show advancedoption is set.


--disable xp_cmdshell, mail procedures unless needed

EXEC sp_configure 'show advanced options',1
GO 
RECONFIGURE
GO
EXEC sp_configure 'Database Mail XPs',1
GO
RECONFIGURE

