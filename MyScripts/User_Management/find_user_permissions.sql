--current user
use master 
go
print suser_sname()


-- check assigned permissions
USE [master]
GO
SELECT SUSER_SNAME() as lee, * FROM sys.fn_my_permissions(NULL, NULL);
GO

