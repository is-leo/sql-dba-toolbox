-- Demo script for Backup Checksums demo.

-- Run the Setup-BackupChecksums.sql script

-- Back up both databases
BACKUP DATABASE [Company]
TO DISK = N'C:\Pluralsight\Company.bak'
WITH INIT;
GO

BACKUP DATABASE [Company2]
TO DISK = N'C:\Pluralsight\Company2.bak'
WITH INIT;
GO

-- Now use WITH CHECKSUM
BACKUP DATABASE [Company]
TO DISK = N'C:\Pluralsight\Company_CHECKSUM.bak'
WITH INIT, CHECKSUM;
GO

BACKUP DATABASE [Company2]
TO DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak'
WITH INIT, CHECKSUM;
GO

-- CONTINUE_AFTER_ERROR can be used to force the backup.
BACKUP DATABASE [Company2]
TO DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak'
WITH INIT, CHECKSUM, CONTINUE_AFTER_ERROR;
GO

-- Why not just remove the CHECKSUM?
-- Look in the backup header
RESTORE HEADERONLY
FROM DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak';
GO

-- Look in the error log

-- Testing the backup integrity
RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company.bak';
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company2.bak';
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company_CHECKSUM.bak';
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak';
GO

-- And now with CHECKSUM
 
RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company2.bak'
WITH CHECKSUM;
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company_CHECKSUM.bak'
WITH CHECKSUM;
GO

RESTORE VERIFYONLY
FROM DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak'
WITH CHECKSUM;
GO

-- And restoring
RESTORE DATABASE [Company_Copy]
FROM DISK = N'C:\Pluralsight\Company.bak'
WITH
    MOVE N'Company' TO N'C:\Pluralsight\Company_Copy.mdf',
	MOVE N'Company_log' TO N'C:\Pluralsight\Company_Copy_log.ldf',
	REPLACE;
GO

RESTORE DATABASE [Company2_Copy]
FROM DISK = N'C:\Pluralsight\Company2.bak'
WITH 
    MOVE N'Company2' TO N'C:\Pluralsight\Company2_Copy.mdf',
	MOVE N'Company2_log' TO N'C:\Pluralsight\Company_Copy2_log.ldf',
	REPLACE;
GO

RESTORE DATABASE [Company_Copy]
FROM DISK = N'C:\Pluralsight\Company_CHECKSUM.bak'
WITH
    MOVE N'Company' TO N'C:\Pluralsight\Company_Copy.mdf',
	MOVE N'Company_log' TO N'C:\Pluralsight\Company_Copy_log.ldf',
	REPLACE, CHECKSUM;
GO

RESTORE DATABASE [Company2_Copy]
FROM DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak'
WITH
    MOVE N'Company2' TO N'C:\Pluralsight\Company2_Copy.mdf',
	MOVE N'Company2_log' TO N'C:\Pluralsight\Company2_Copy_log.ldf',
	REPLACE, CHECKSUM;
GO

-- What about removing the CHECKSUM?
RESTORE DATABASE [Company2_Copy]
FROM DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak'
WITH
    MOVE N'Company2' TO N'C:\Pluralsight\Company2_Copy.mdf',
	MOVE N'Company2_log' TO N'C:\Pluralsight\Company2_Copy_log.ldf',
	REPLACE;
GO

-- CONTINUE_AFTER_ERROR can be used to force the restore.
-- Discussed more in Module 5 of SQL Server: Advanced Corruption
-- Recovery Techniques.
RESTORE DATABASE [Company2_Copy]
FROM DISK = N'C:\Pluralsight\Company2_CHECKSUM.bak'
WITH
    MOVE N'Company2' TO N'C:\Pluralsight\Company2_Copy.mdf',
	MOVE N'Company2_log' TO N'C:\Pluralsight\Company2_Copy_log.ldf',
	REPLACE, CONTINUE_AFTER_ERROR;
GO


