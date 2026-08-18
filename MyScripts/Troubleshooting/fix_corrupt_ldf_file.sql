/*When you don't have a backup and you cannot attach a db and the error message 
indicates the problem is the transaction log, is because your database wasn't 
cleanly shutdown. Then you need to do the following (SQL Server 2005).
create a database with the same name and file names identical to the one you're
trying to attach 
shutdown the sql server 
swap in the old mdf file 
bring up the server and let the database attempt to be recovered and then go 
into suspect mode */

--run the following commands:put the database into emergency mode
ALTER DATABASE yourDBname SET EMERGENCY;

--Run DB CHECK. You can skip this step if the db is big and want to save time.
DBCC checkdb('yourDBname')

--Set db in single user mode
ALTER DATABASE yourDBname SET SINGLE_USER WITH ROLLBACK IMMEDIATE

--Repair db which will rebuild the log and run full repair
DBCC CheckDB ('yourDBname', REPAIR_ALLOW_DATA_LOSS)

--Set db in multi user mode
ALTER DATABASE yourDBname SET MULTI_USER

--Now you're done and have recovered the corrupt db
