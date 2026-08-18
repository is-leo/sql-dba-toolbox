-- This script demonstrates a typical conversion deadlock. It also
-- demonstrates how you can use sp_getapplock to get two windows start
-- simultaneousely.

-- We have a table with an id column where we don't use IDENTITY, but roll-
-- our own primary key.
DROP TABLE IF EXISTS RollYourOwn
CREATE TABLE RollYourOwn(id   int          NOT NULL,
                         data nvarchar(50) NOT NULL,
                         CONSTRAINT pk_RollYourOwn PRIMARY KEY(id)
)
go
-- A stored procedure to add data and return the id for the new row.
CREATE OR ALTER PROCEDURE inner_sp @data nvarchar(50),
                                   @id   int OUTPUT AS
   BEGIN TRANSACTION

   -- Get next id and prevent other processes from increasing the max.
   SELECT @id = isnull(MAX(id), 0) + 1 
   FROM   RollYourOwn WITH (SERIALIZABLE)

   WAITFOR DELAY '00:00:00.500' -- To increase the possibility for a deadlock.

   INSERT RollYourOwn(id, data)
      VALUES(@id, @data)

   COMMIT TRANSACTION
go
-- An outer SP. The main purpose of it just to demonstrate the call
-- stack in the deadlock XML.
CREATE OR ALTER PROCEDURE outer_sp @data nvarchar(50) AS
   DECLARE @id int
   EXEC inner_sp @data, @id OUTPUT
   SELECT @id AS TheId
go
-- Add some initial rows.
EXEC outer_sp N'São Paolo'
EXEC outer_sp N'Recife'
go
-- Now grab an exclusive application lock on session level.
EXEC sp_getapplock N'Deadlocktester', 
                   @LockMode = N'Exclusive', @LockOwner = N'Session'
go
-- Run this next batch in a separate window!
/*
-- Get a shared lock on the Deadlocktester. The call will be blocked until
-- the first window releases the lock.
EXEC sp_getapplock N'Deadlocktester', 
                   @LockMode = N'Shared', @LockOwner = N'Session' 
-- Once the lock is released try to insert a row.
EXEC outer_sp N'Belo Horizonte'
go
-- Release lock.
EXEC sp_releaseapplock N'Deadlocktester', @LockOwner = N'Session'
*/
go
-- Release lock and try to insert a row. The two calls will run in parallel
-- and most likely deadlock.
EXEC sp_releaseapplock N'Deadlocktester', @LockOwner = N'Session'
EXEC outer_sp 'Manuas'
go
-- Go for a coffee or similar and come back in a minute or two, so that
-- the deadlock is in system_health.
; WITH CTE AS (
  SELECT CAST(event_data AS xml) AS xml, timestamp_utc
  FROM sys.fn_xe_file_target_read_file(
     N'system_health*.xel', DEFAULT, DEFAULT, DEFAULT)
  WHERE object_name = 'xml_deadlock_report'
)
SELECT xml.query('/event/data[1]/value[1]/deadlock[1]'), timestamp_utc
FROM   CTE
ORDER BY timestamp_utc DESC
go
-- Get the value for sqlhandle, stmtstart and stmtend for the top element 
-- in the <executionStack> tag and paste in below. 
SELECT convert(xml, etqp.query_plan) AS query_plan, qs.*
FROM   sys.dm_exec_query_stats qs
CROSS  APPLY sys.dm_exec_text_query_plan(qs.plan_handle, 
             qs.statement_start_offset, qs.statement_end_offset) AS etqp
WHERE  qs.sql_handle = 0x0300020027b3813aad680d0169b0000001000000000000000000000000000000000000000000000000000000
  AND  qs.statement_start_offset = 884
  AND  qs.statement_end_offset = 990

-- Note there can be more one entry in sys.dm_exec_query_stats for the same
-- sql_handle and stmt_start/end if different SET options are in play.
-- Also, note that for a complex query, the plan may have changed since the
-- deadlock occurred, particularly if it includes temp tables.