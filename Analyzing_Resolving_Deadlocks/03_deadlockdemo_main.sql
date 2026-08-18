USE tempdb
go
DROP PROCEDURE IF EXISTS Deadlock_demo
go
DROP TABLE IF EXISTS TestTbl
CREATE TABLE TestTbl (id    int              NOT NULL,
                      guid  uniqueidentifier NOT NULL,
                      data1 datetime2(3)     NOT NULL,
                      data2 int              NOT NULL,
                      data3 sysname          NOT NULL,
                      CONSTRAINT pk_TestTbl PRIMARY KEY (id),
                      CONSTRAINT u_TestTbl UNIQUE (guid)
)

DROP TYPE IF EXISTS TblType
CREATE TYPE TblType AS TABLE (data1 datetime2(3)  NOT NULL,
                              data2 int           NOT NULL,
                              data3 sysname       NOT NULL)
go
-- This is the first version of the procedure which produces a 
-- deadlock with the SERIALIZEBLE hint and avoids it with the UPDLOCK hint.
CREATE OR ALTER PROCEDURE Deadlock_demo @data TblType READONLY AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
   DECLARE @firstid int

   DECLARE @guids TABLE (guid uniqueidentifier NOT NULL UNIQUE)

   BEGIN TRANSACTION

   -- Try procedure without hint as well with the two hints below.
   SELECT @firstid = isnull(MAX(id), 0) + 1
   FROM   TestTbl                 
   -- WITH (SERIALIZABLE)
   -- WITH (UPDLOCK, SERIALIZABLE)

   WAITFOR DELAY '00:00:00.250'    -- To facilitate the demo.

   INSERT TestTbl(id, guid, data1, data2, data3)
      OUTPUT inserted.guid INTO @guids
      SELECT @firstid + row_number() OVER(ORDER BY data3) - 1, 
             newid(), data1, data2, data3
      FROM   @data

   COMMIT TRANSACTION

   -- Return data to client. In a real-world case, this could be a more 
   -- complex, which also could deadlock.
   SELECT T.*
   FROM   TestTbl T
   WHERE  EXISTS (SELECT * FROM @guids g WHERE T.guid = g.guid)
END TRY
BEGIN CATCH
   -- Standard CATCH handler.
   IF @@trancount > 0 ROLLBACK TRANSACTION
   ; THROW
END CATCH
go
-- To test the procedure: Open 03_deadlockdemo2.sql and follow
-- the instructions.

-------------------------------------------------------------------
-- The Deadlock_demo procedure, now with retry logic.
CREATE OR ALTER PROCEDURE Deadlock_demo @data TblType READONLY AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
   DECLARE @firstid int,
           @trancount_save int = @@trancount

   DECLARE @guids TABLE (guid uniqueidentifier NOT NULL UNIQUE)

   DECLARE @trycnt int = 1,
           @done   bit = 0

   WHILE @done = 0
   BEGIN TRY
      SELECT @firstid = NULL
      DELETE @guids

      BEGIN TRANSACTION

      SELECT @firstid = isnull(MAX(id), 0) + 1
      FROM   TestTbl WITH (SERIALIZABLE)

      WAITFOR DELAY '00:00:00.250'   -- To Facilitate demo.

      INSERT TestTbl(id, guid, data1, data2, data3)
         OUTPUT inserted.guid INTO @guids
         SELECT @firstid + row_number() OVER(ORDER BY data1) - 1, 
                newid(), data1, data2, data3
         FROM   @data

      -- Note that the SELECT must be inside the transaction if we want
      -- deadlock retry also for the SELECT.
      SELECT T.*
      FROM   TestTbl T
      WHERE  EXISTS (SELECT * FROM @guids g WHERE T.guid = g.guid)

      COMMIT TRANSACTION

      SELECT @done = 1    -- Exit loop.
   END TRY
   BEGIN CATCH
      IF @@trancount > 0 ROLLBACK TRANSACTION

      -- Do deadlock retry?
      IF @trancount_save = 0 AND error_number() = 1205 
         -- AND @trycnt < 5
      BEGIN
         PRINT concat('Deadlock in attempt ', @trycnt, ', retrying.')
         SELECT @trycnt = @trycnt + 1
      END
      ELSE
      BEGIN
         -- Not deadlock or retry not permissible. Re-raise the error.
         ; THROW
      END
   END CATCH
END TRY
BEGIN CATCH
   IF @@trancount > 0 ROLLBACK TRANSACTION
   ; THROW
END CATCH
go
