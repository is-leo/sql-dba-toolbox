--Find Blocking leaders
EXEC sp_WhoIsActive      @find_block_leaders = 1

--Returns the same data as in comment header
EXEC sp_WhoIsActive    @help = 1

--Outer ad-hoc query, query plans, full stored procedure or batch
EXEC sp_whoisactive @get_outer_command = 1,@get_plans=1,@get_full_inner_text=1

--Get Locks per request . XML format
EXEC sp_WhoIsActive    @get_locks = 1

--Get waits of all waits pending on a request
EXEC sp_WhoIsActive     @get_task_info = 2

--download http://whoisactive.com/