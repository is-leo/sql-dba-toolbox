
--EDIT & TEST
--Steps to restore a database from a backup device 
--that was part of an Always On Availability Group, and now needs to be restored 

--Name of Always on Availability Group = MyAG1
--Name of Always On Availability Group db = MyAGDB1
--Note: this is a workflow - and there may be some slight 
--variations depending your Availability Group set up 

--Steps to Restore database 
-- 1. Remove the database from the AG Group from the PRIMARY 
ALTER AVAILABILITY GROUP [MyAG1] REMOVE DATABASE [MyAGDB1];

--2. Restore the database to PRIMARY from the backup device in RECOVERY mode 
--Method will depend you're using RESTORE from disk  or might be using a console 
--for an Enterprise backup system

--3. Restore the same database to SECONDARY in NORECOVERY mode. Some sample Restore statements ,
RESTORE DATABASE MyAGDB1 from disk='\\mynode1\Backups\MyAGDB1.bak' WITH NORECOVERY
RESTORE LOG MyAGDB1 from disk='\\node1\Backups\MyAGBDB1.trn' WITH NORECOVERY

--4. Add the database on PRIMARY back to the Availability Group
ALTER AVAILABILITY GROUP [MyAG1] ADD DATABASE [MyAGDB1];

--5. Join the database on the secondary replica back to the Availability Group
ALTER DATABASE MyAGDB1 SET HADR AVAILABILITY GROUP = MyAG1