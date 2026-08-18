-- ================================
-- Create Database Role template
-- ================================
USE 'DBName'
GO

-- Create the database role
CREATE ROLE test_group AUTHORIZATION [dbo]
GO

-- Grant access rights to a specific schema in the database
GRANT 
/*
	ALTER, 
	CONTROL, 
	DELETE, 
	EXECUTE, 
	INSERT, 
	REFERENCES, 
	SELECT, 
	TAKE OWNERSHIP, 
	UPDATE, 
	VIEW DEFINITION 
*/
ON SCHEMA::dbo
	TO test_group
GO

-- Add an existing user to the role
ALTER ROLE test_group ADD MEMBER leo_user
GO


 