-- TDE. Don’t forget to assign access to private key for SQLserver service account!
USE master
GO
CREATE MASTER KEY ENCRYPTION
BY PASSWORD='T?f91s*EMrLkfv!';
GO

CREATE CERTIFICATE sqlserv1234
FROM FILE ='C:\TDE_files(do_not_delete)\sqlserv1234\sqlserv1234_1.cer'
WITH PRIVATE KEY (FILE ='C:\TDE_files(do_not_delete)\sqlserv1234\sqlserv1234_1.pvk',
DECRYPTION BY PASSWORD = 'JKMkSHk53RPTBANPxHCL')
GO


USE DBA; 
GO
CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 
ENCRYPTION BY SERVER CERTIFICATE sqlserv1234;



-- set it ON
ALTER DATABASE DBA
SET ENCRYPTION ON;
GO


-- check if exist & ON
SELECT DB_NAME(database_ID), * FROM sys.dm_database_encryption_keys

