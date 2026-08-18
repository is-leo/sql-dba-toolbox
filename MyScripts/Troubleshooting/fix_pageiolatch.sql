
SET STATISTICS IO ON
--DBCC DROPCLEANBUFFERS -- clears up the cache 
--DropIndexes @TableName = 'Comments'

SELECT *
FROM stackoverflow.dbo.comments
WHERE UserId = 26837

--Run this in a new query session
sp_BlitzFirst @ExpertMode = 1,
@Seconds = 30


SELECT 2772305 * 8.0 / 1024 / 1024
--pages * 8k pages / 1024 kb in mb / 1024 mb in gb

/* Fix PAGEIOLATCH waits:

1.Tune indexes 
	  sp_BlitzIndex @GetAllDatabases = 1
	  Focus on high value missing indexes. Index tuning requires some memory
	  so if memory is low try to add some at least temporrily for tuning purpose.

	  CREATE INDEX UserId ON dbo.Comments(UserId)
	  WITH (MAXDOP = 0, ONLINE = OFF);

2.Tune query
	  sp_BlitzCache @SortOrder = 'reads'
	  Tune queries to do less logical reads

	  --can we go on by only selecting top 100, 200 or 300
	  SELECT Top 100 * FROM stackoverflow.dbo.comments
	  WHERE UserId = 26837

3.Add memory
	  relatively cheap to add then before.
	  if you are not allowed to query indexes & queries, take the size of
	  your biggest db size & multiple by 2 & you get the memory size you need
	  ex. db size 100 gb * 2 = 200 GB is the max memory

4.Tune storage
	  companies reluctant to spend money on storage



	  
