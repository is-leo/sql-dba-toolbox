EXEC dbo.sp_BlitzIndex @GetAllDatabases = 1

--gives a prioritized list of health problems
EXEC sp_Blitz @CheckServerInfo = 1

EXEC dbo.sp_BlitzIndex
    @DatabaseName = N'Raindance_P_Utdata',
    @Mode = 0; --Lighter detail


EXEC dbo.sp_BlitzIndex
    @DatabaseName = N'Raindance_P_Utdata',
    @Mode = 4; --Heavier detail


--So what I usually do is:
-- Get rid of totally unused indexes
-- Come back and see what duplicate indexes are left
-- Merge those together
-- Come back and see what borderline duplicate indexes are left
-- Merge those together
-- Come back and see if there are any indexes with a really bad write to read ratio
-- Decide which of those are safe to drop

EXEC sp_BlitzFirst @SinceStartup = 1, @OutputType = 'Top10'
	
EXEC Sp_BlitzIndex @GetAllDatabases = 1 --look for high-value missing indexes
	
EXEC Sp_BlitzCache @SortOrder = 'reads'
	
EXEC Sp_BlitzCache @SortOrder = 'cpu'

EXEC sp_BlitzCache @SortOrder = 'memory grant'
	
--Make sure CTFP & MAXDOP are adequatelly set

-- <https://erikdarling.com/sql-server-community-tools-how-i-use-sp_blitzindex/> 



    /*Find top 10 sorted by memory*/
EXEC dbo.sp_QuickieStore
    @database_name = 'Raindance_P_Utdata',
    @sort_order = 'cpu',
    @top = 10;   
    
EXEC dbo.sp_HumanEventsBlockViewer
    @session_name = N'blocked_process_report';
    
    --@help = 1
    EXEC dbo.sp_QuickieStore
    @database_name = 'Raindance_P_Utdata',
    @troubleshoot_performance = 1;

--the contents of the system_health extended event session
--sp_HealthParser @help = 1



