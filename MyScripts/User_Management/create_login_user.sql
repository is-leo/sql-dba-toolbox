--list logins
select * from sys.sql_logins

--AD account
CREATE LOGIN user_name_1
FROM WINDOWS WITH DEFAULT_DATABASE= master
GO

--sql login
CREATE LOGIN user_name_2 
WITH PASSWORD = 'acomplexpassword'MUST_CHANGE, CHECK_EXPIRATION=ON, CHECK_POLICY=ON, 
DEFAULT_DATABASE= master
GO

/*check policy & password expiration based on  Windows password policies of the computer */


/*
ALTER SERVER ROLE [sysadmin] 
ADD MEMBER user_namn
GO

ALTER SERVER ROLE [dbcreator] 
ADD MEMBER user_namn
GO

ALTER SERVER ROLE [securityadmin] 
ADD MEMBER user_namn
GO

*/

--azure contained user
USE AdventureWorks2019
GO
CREATE USER ContainedUser WITH PASSWORD = 'ContainedUser'

--For sql server before creating contained user enable following: 
select * from sys.configurations
where name = 'contained database authentication'
GO
sp_configure 'contained database authentication', 1;  
GO  
RECONFIGURE;  
GO
-- on db level change CONTAINMENT to  PARTIAL
-- type in database name in the connection property

