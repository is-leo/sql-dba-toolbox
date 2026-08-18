USE tempdb
go
-- First run only this batch. Then proceeed to 03_deadlockdemo3.sql.
EXEC sp_getapplock N'deadlock_demo', N'Exclusive', 
                   @LockOwner = 'Session'
go
-- Release application lock and run procedure. Be careful to 
-- check output for both windows.
EXEC sp_releaseapplock N'deadlock_demo', @LockOwner = 'Session'

-- Call deadlock_demo with some random data.
DECLARE @data TblType
INSERT @data (data1, data2, data3)
   SELECT TOP (3) sysdatetime(), @@spid, name
   FROM   sys.all_objects
   ORDER  BY newid()
EXEC Deadlock_demo @data
