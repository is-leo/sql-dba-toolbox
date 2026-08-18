
sp_BlitzFirst @Seconds = 30, @ExpertMode = 1

/* Before:
PAGEIOLATCH waits: 803.6 seconds in a 60-second sample,
			wait time ratio (per core per sec) 1.2
Batch request/sec: 0.02

 After:
PAGEIOLATCH waits: 8 seconds in a 60-second sample,
			wait time ratio (per core per sec) 0.1
Batch request/sec: 171.80 */

--copy from More Info column & run
EXEC dbo.sp_BlitzIndex @DatabaseName='StackOverflow', @SchemaName='dbo', @TableName='Comments';
EXEC dbo.sp_BlitzIndex @DatabaseName='StackOverflow', @SchemaName='dbo', @TableName='Votes';
EXEC dbo.sp_BlitzIndex @DatabaseName='StackOverflow', @SchemaName='dbo', @TableName='Badges';

sp_BlitzIndex @GetAllDatabases = 1, @Mode = 2 --Inventory of all existing indexes 
sp_BlitzIndex @GetAllDatabases = 1, @Mode = 3 --Inventory of all missing indexes


--skip include columns when creating indexes, includes consume more storage space & takes konger time to create 

 