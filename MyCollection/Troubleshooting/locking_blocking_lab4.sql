
--take long samples of waits:
sp_BlitzFirst @Seconds = 60, @ExpertMode = 1

--stop workload test & take snapshot since startup
sp_BlitzFirst @SinceStartup = 1

--see what queries are causing those waits
sp_BlitzCache @SortOrder = 'reads'

/*

I reviewd SQL2019's performance, and the main bottlenecks are:
1.Lockeing/blocking
2.Storage reads PAGEIOLATCH_SH/Buffer IO
3.SOS_SCHEDULER_YIELD/CPU

Options to reduce blocking are:
a)Tune indexes to reduce unneeded writes & speed up reads
b)Tune queries to reduce blocking, shorten transactions 
c)Impelement optimistic concurrency (RCSI or SI)
To check long runing read queries , blockings:
	sp_BlitzLock
	sp_BlitzCache @SortOrder = 'duration'

d)Change MAXDOP from 1 to 4 so that queries can finish
more quickly, plus change Cost Threshold for Parallelism 
from 5 to 50 so small queries dont go parallel.

-----------------------------------
Wrong troubleshooting steps:
1. sp_Blitz

Before parallelism change:
Batch requests/sec: 0.60
Waite time ratio: 2.23
Top waits: 
LCK% 310 seconds in a 60-second sample
SOS_SCHEDULER_YIELD 84,8 seconds
PAGEIOLATCH_SH 39 seconds
*/

EXEC sys.sp_configure N'cost threshold for parallelism', N'5'
GO
EXEC sys.sp_configure N'max degree of parallelism', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

/*
After parallelism change:
Batch requests/sec: 0.60,  1.29 twice better now
Waite time ratio: 2.23, 7.05 worse
Top waits: 
CX% 1680 seconds in a 60-second sample
SOS_SCHEDULER_YIELD 505 seconds
PAGEIOLATCH_SH 1680 seconds

Correct troubleshooting steps
Based on our timeline, let's start with tuning indexes:
*/

sp_BlitzIndex @GetAllDatabases = 1

--These tables are the ones involved in blocking 
EXEC dbo.sp_BlitzIndex @DatabaseName='StackOverflow', @SchemaName='dbo', @TableName='Users';

/* this table is a heap with no clustered or nonclustered indexes defined 
EQUALITY:  [Id]  {int}, [IsDeleted]  {bit}, [IsPrivate]  {bit} 
EQUALITY:  [Id]  {int} 
EQUALITY:  [IsDeleted]  {bit}, [IsPrivate]  {bit} INCLUDE:  [Id]  {int}, [DisplayName]  {varchar(40)} 
EQUALITY:  [Id]  {int} INEQUALITY:  [LastAccessDate]  {datetime} 
EQUALITY:  [Id]  {int} INCLUDE:  [Reputation]  {int} 

Let's see if Id is unique:
*/
SELECT TOP 100 Id, Count(*) AS recs
FROM dbo.Users
GROUP By Id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;
--no duplicates found

--create index & run in a new session
CREATE UNIQUE CLUSTERED INDEX CL_Id ON dbo.Users(Id)
WITH (ONLINE = OFF, MAXDOP = 0)

--the other table votes
EXEC dbo.sp_BlitzIndex @DatabaseName='StackOverflow', @SchemaName='dbo', @TableName='Votes';
-- This index has no reads but only writes, so dropping it reduces blocking
DROP INDEX [IX_VoteTypeId] ON [StackOverflow].[dbo].[Votes];

--index on vote table
CREATE INDEX VoteTypeId_PostId_UserId_Incl
	ON dbo.Votes(VoteTypeId, PostId, UserdId)
	INCLUDE (IsDeleted, IsPrivate)
	WITH (MAXDOP = 0, ONLINE = OFF)

/*
After parallelism change & with right troubleshooting:
Batch requests/sec: 40 secs
Waite time ratio: 0
Top waits: 
CX% 0 seconds in a 60-second sample
SOS_SCHEDULER_YIELD 0 seconds
PAGEIOLATCH_SH 0 seconds

*/

ALTER     PROC [dbo].[usp_Report2] @LastActivityDate DATETIME, @Tags VARCHAR(150) AS
BEGIN
--As this sp is a read-only and it locks posts table , we can change the isolation level for it 
-- run to allow ALTER DATABASE [StackOverflow] SET ALLOW_SNAPSHOT_ISOLATION ON
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
SELECT TOP 100 u.DisplayName, u.Id AS UserId, u.Location, p.Id AS PostId, p.LastActivityDate, p.Body
  FROM dbo.Posts p
    INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.Tags LIKE '%<sql-server>%'
    AND p.Tags LIKE @Tags
    AND p.LastActivityDate > @LastActivityDate
  ORDER BY u.DisplayName
END
