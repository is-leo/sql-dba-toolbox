-- Once you have run the first batch of deadlockdemo2.sql, run
-- this window in its entirety.
USE tempdb
go
-- Get a share application lock, will block until window2 releases
-- the application lock.
EXEC sp_getapplock N'deadlock_demo', N'Shared', 
                   @LockOwner = N'Session'

-- SET DEADLOCK_PRIORITY LOW

-- Call deadlock_demo with some random data.
DECLARE @data TblType
INSERT @data (data1, data2, data3)
   SELECT TOP (4) sysdatetime(), @@spid, name
   FROM   sys.all_columns
   ORDER  BY newid()
EXEC Deadlock_demo @data
go
-- Make sure we release application lock
EXEC sp_releaseapplock N'deadlock_demo', @LockOwner = 'Session'