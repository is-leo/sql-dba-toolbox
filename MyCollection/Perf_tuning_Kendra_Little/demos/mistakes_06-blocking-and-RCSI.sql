/* Doorstop */
RAISERROR(N'Did you mean to run the whole thing?',20,1) WITH LOG;
GO



/*****************************************************************************
Demo of timing/behavior changes between Read Committed and Read Committed Snapshot,
with options to get the best of both worlds.
*****************************************************************************/

use master;
GO

IF DB_ID('IsolationLevelsDemo') is not null
BEGIN
	ALTER DATABASE IsolationLevelsDemo SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE IsolationLevelsDemo
END
create database IsolationLevelsDemo
GO

use IsolationLevelsDemo
GO




/****************************************************
Timing differences where Read Committed and RCSI behave differently
One example
****************************************************/

/* Check isolation level, switch back to read committed if necessary */
DBCC USEROPTIONS;
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO

/* Verify current database settings */
SELECT is_read_committed_snapshot_on, snapshot_isolation_state_desc
FROM sys.databases
WHERE name='IsolationLevelsDemo';
GO


USE IsolationLevelsDemo;
GO

DROP TABLE IF EXISTS dbo.SeatAssignments;
GO

CREATE TABLE dbo.SeatAssignments (
    SeatId INT IDENTITY,
    Seat varchar(5) NOT NULL,
    AssignedTo VARCHAR(256) NULL,
    CONSTRAINT pk_SeatAssignments_SeatId PRIMARY KEY CLUSTERED (SeatId)
);
GO

/* Our plane has 100 seats  */
WITH NumberSeries AS (
    SELECT TOP 25 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNumber
    FROM master.dbo.spt_values
)
INSERT INTO dbo.SeatAssignments (Seat)
SELECT 
    CAST(n.RowNumber AS VARCHAR) + s.SeatLetter
FROM 
    NumberSeries n
CROSS APPLY (
    VALUES ('A'), ('B'), ('C'), ('D')
) AS s(SeatLetter);
GO


/* Assign all the seats but one */
UPDATE dbo.SeatAssignments
SET AssignedTo = 
    CASE 
        WHEN Seat = '1A' THEN NULL
        ELSE 'Someone else'
    END;
GO


/* Here's the seats... only one left!*/
SELECT *
FROM dbo.SeatAssignments;
GO


/* The code to assign a seat */
CREATE OR ALTER PROCEDURE dbo.GetMySeat
    @Seat CHAR(2), 
    @Assignee VARCHAR(256)
AS
    BEGIN TRAN

        UPDATE dbo.SeatAssignments
        SET AssignedTo = @Assignee
        WHERE Seat = (
            SELECT Seat
            FROM dbo.SeatAssignments
            WHERE Seat = @Seat
            AND AssignedTo IS NULL
        )

		/* This waitfor is to help reproduce timing issues without
		having a breakpoint or stepping into the proc with a debugger */
		
        WAITFOR DELAY '00:00:05'

    COMMIT
GO



/* Here's how our app works under read committed. */
/* In this session, I start to reserve my seat. FIRST CLASS! YESSSSSS! */
exec dbo.GetMySeat @Seat='1A', @Assignee='Kendar';
GO
        


/* Run this in session B (uncommented) */
/*
USE IsolationLevelsDemo;
GO
exec dbo.GetMySeat @Seat='1A', @Assignee='Nanners';
GO
*/

/* After they both complete */

SELECT *
FROM dbo.SeatAssignments;
GO




/* Enable RCSI, and run through the sequence again... 
Note: to enable/disable RCSI, you must be the only active transaction in the database.
WITH ROLLBACK IMMEDIATE will attempt to kill anyone else doing things in the DB.
*/
ALTER DATABASE IsolationLevelsDemo SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE
GO





/***************************************************
Why this only happens sometimes
****************************************************/

/* Compare these estimated execution plans.
This timing issue happens with the first, more complex query, but not the second simpler one.
What are the plan differences?
*/

declare @Assign varchar(256) = 'Freyja', @Seat varchar(5)='1A'

UPDATE dbo.SeatAssignments
SET AssignedTo = @Assign
WHERE Seat = (
    SELECT Seat
    FROM dbo.SeatAssignments
    WHERE Seat = @Seat
    AND AssignedTo IS NULL
)


UPDATE dbo.SeatAssignments
SET AssignedTo = @Assign
WHERE Seat =  @Seat
AND AssignedTo IS NULL;
GO






/****************************************************
Avoiding the race condition under RCSI
****************************************************/

/* We can use a hint to get the old locking style back under RCSI, if that's what we want */
CREATE OR ALTER PROCEDURE dbo.GetMySeat
    @Seat CHAR(2), 
    @Assignee VARCHAR(256)
AS
    BEGIN TRAN

        UPDATE dbo.SeatAssignments
        SET AssignedTo = @Assignee
        WHERE Seat = (
            SELECT Seat
            FROM dbo.SeatAssignments WITH (READCOMMITTEDLOCK)
            WHERE Seat = @Seat
            AND AssignedTo IS NULL
        )

        WAITFOR DELAY '00:00:05'

    COMMIT
GO

/* Reset the table and run through the sequence again */



/* We can use snapshot isolation for the update.
We need to have logic to handle update conflicts, however. 
(Update conflicts are a FEATURE!)
*/
ALTER DATABASE IsolationLevelsDemo SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

CREATE OR ALTER PROCEDURE dbo.GetMySeat
    @Seat CHAR(2), 
    @Assignee VARCHAR(256)
AS
    SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
    BEGIN TRAN

        UPDATE dbo.SeatAssignments
        SET AssignedTo = @Assignee
        WHERE Seat = (
            SELECT Seat
            FROM dbo.SeatAssignments
            WHERE Seat = @Seat
            AND AssignedTo IS NULL
        )

        WAITFOR DELAY '00:00:10'

    COMMIT
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

GO


/* Reset the table and run through the sequence again */




/* Disable RCSI... */
ALTER DATABASE IsolationLevelsDemo SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE
GO