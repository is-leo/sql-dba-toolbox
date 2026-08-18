--generate backup scripts
SELECT 'BACKUP DATABASE ['  + name  + '] TO  DISK = N''F:\backups\'  + name  + '.bak'' 
	WITH NOFORMAT, NOINIT,  NAME = N''' + name  + '-Full Database Backup'', 
	SKIP, 
	NOREWIND, 
	NOUNLOAD, 
	COMPRESSION,  
	STATS = 10' + CHAR(13) 
FROM sys.databases


