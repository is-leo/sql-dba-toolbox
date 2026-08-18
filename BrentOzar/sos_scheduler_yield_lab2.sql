sp_Blitz

sp_BlitzFirst @Seconds = 60, @ExpertMode = 1

/* Before:
Batch req/sec: 1.86
Wait time ration (per core per sec): 2.29 
2nd top wait type: SOS_SCHEDULER_YIELD 188.5

Check FindingsGroup column for Forwarded Fetches/Sec High run then: */
sp_BlitzIndex @GetAllDatabases = 1

-- look for Heaps with Forwarded Fetches StackOverflow 272546948 forwarded fetches...
-- looks like the 'Users' table is the problem child
-- 2 ways to solve: rebuild the table which requries lock or create a clustered index

EXEC dbo.sp_BlitzIndex @DatabaseName='StackOverflow', @SchemaName='dbo', @TableName='Users';

--check for duplicate Ids
SELECT TOP 100 Id, COUNT(*) AS recs
FROM dbo.Users
GROUP BY Id
HAVING COUNT(*) > 1
ORDER BY COUNT (*) DESC;

-- No duplicate Ids, let's fix it:
CREATE UNIQUE CLUSTERED INDEX CL_ID ON dbo.Users(Id)
WITH (ONLINE = OFF, MAXDOP = 0)
GO
CREATE INDEX DisplayName ON dbo.Users(DisplayName)
WITH (ONLINE = OFF, MAXDOP = 0)
GO

/* After fixing the User clustered index:
Batch req/sec: 1.17
Wait time ration (per core per sec): 0.2 
2nd top wait type: SOS_SCHEDULER_YIELD 81.7
*/

--top most resource intensive queries by cpu
sp_BlitzCache @SortOrder = 'cpu'

  CREATE OR ALTER  PROC dbo.usp_GetNewPostsForUser_updated @DisplayName NVARCHAR(40) AS  
  BEGIN  
  /* Get the last date a user logged in */  
  DECLARE @LastLoginDate VARCHAR(50);  
  SELECT @LastLoginDate = LastAccessDate    
  FROM dbo.Users    
  WHERE DisplayName = @DisplayName    
  AND LastAccessDate IS NOT NULL;    
  
  /* Show the first 100 questions entered after they last logged in */  
  SELECT TOP 100 *    
  FROM dbo.Posts p    
  WHERE p.CreationDate > @LastLoginDate    

  /*replace this line
  AND dbo.IsTagBanned(p.Id) = 0 -- scallar function that reads row by row which consumes cpu
  
  with this: */
  AND NOT EXISTS (SELECT 1 FROM dbo.Posts p2 
		INNER JOIN dbo.BannedTags bt ON p2.Tags = bt.Tag WHERE p2.Id = p.Id)

  AND p.PostTypeId = 1  /* Only questions */    
  ORDER BY p.CreationDate;    
  END  

  SET STATISTICS TIME ON;
  EXEC usp_GetNewPostsForUser N'Brent Ozar'
  /* Before:
		Took 19 sec to execute
		CPU time = 4359 ms,  elapsed time = 19239 ms.
  */
 SET STATISTICS TIME ON;
 EXEC usp_GetNewPostsForUser_updated N'Brent Ozar'
 /* After:
        Took 3 sec to execute
		CPU time = 2782 ms,  elapsed time = 3605 ms
	*/
-- Implicit conversion in p2.Tags = bt.Tag, nvarchar vs varchar
-- Upconvert varchar to nvarchar:

ALTER TABLE dbo.BannedTags
	ALTER COLUMN Tag NVARCHAR(150);
GO

--The index 'IX_Tag' is dependent on column 'Tag'.
--ALTER TABLE ALTER COLUMN Tag failed because one or more objects access this column.

DROP INDEX IX_Tag ON dbo.BannedTags

CREATE NONCLUSTERED INDEX [IX_Tag] ON [dbo].[BannedTags]
(
	[Tag] ASC
)WITH (ONLINE = OFF, MAXDOP = 0)
GO

 /* After conversion fix:
 Took 0 sec to execute
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 365 ms.
*/

-- if data type change is not possible use cast inside the procedure
ALTER   PROC [dbo].[usp_GetUsersByDisplayName] @DisplayName sql_variant AS
BEGIN
SELECT *
  FROM dbo.Users
  WHERE DisplayName = CAST(@DisplayName AS NVARCHAR(49)) -- right here
END

SET STATISTICS TIME ON;
EXEC [dbo].[usp_GetUsersByDisplayName] N'Brent Ozar'


-- another procedure 

  CREATE OR ALTER PROC dbo.usp_GetUsersByLocation    
	@Location NVARCHAR(100) = N'%Iceland%' AS  
  BEGIN  
  SELECT *    
	  FROM dbo.Users 
	  WHERE Location LIKE @Location    
	  ORDER BY DisplayName; 
  END  
  GO

  SET STATISTICS TIME, IO ON;
  EXEC dbo.usp_GetUsersByLocation

  sp_BlitzIndex @TableName = 'Users'

  --include 'location' into index 
  CREATE INDEX [DisplayName] ON [StackOverflow].[dbo].[Users] ( [DisplayName] ) 
  INCLUDE (Location)
  WITH (DROP_EXISTING = ON, ONLINE=OFF, MAXDOP =0);
   
   /* After fixing the User clustered index:
Batch req/sec: 13.08
Wait time ration (per core per sec): 2.24 
2nd top wait type: SOS_SCHEDULER_YIELD 151
*/