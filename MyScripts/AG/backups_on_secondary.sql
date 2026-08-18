/*

Let’s see what kinds of database backups are supported on the secondary replica:

1 Full Backup: We can take COPY-ONLY full database backups from the secondary replica. 
	Sometimes, developers ask database professionals to restore the database copy in the dev & test environments.
	We can use the secondary replica for a copy-only backup. It does not impact the LSN or the differential bitmap


2 Differential backup: You cannot take differential backup on the secondary replica


3 Transaction log backup: The secondary replica supports the regular transaction log backup. 
	The Copy_Only option is unsupported on the secondary replica. 
	SQL Server Always On Availability Group ensures a consistent log chain (log sequence number) 
	whether we take the log backup from the primary or the secondary replica
