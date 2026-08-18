/*
IS BEST FOR A QUICK TROUBLESHOTTING! 
CHECKS FOR ACTIVE QUERIES & ANSWERS QUESTIONS LIKE:
Why is my query is slow?
Is my query doing anything?
Is my backup running?
Is there any blockings?

REASONS FOR SLOW QUERIES:
1.Resource limitation
2.DB setting
3.Query inefficiency
4.Blocking

INSTALL IT IN MASTER SO IT CAN BE CALLED FROM ANY DB!!!
*/ 

-- what to do
EXEC sp_WhoIsActive @help = 1

--Get Locks per request . XML format
EXEC sp_WhoIsActive    @get_locks = 1

--Find Blocking leaders
EXEC sp_WhoIsActive  @find_block_leaders = 1, @get_plans = 1

--Get waits of all waits pending on a request
EXEC sp_WhoIsActive     @get_task_info = 2

--Outer ad-hoc query, query plans, full stored procedure or batch
EXEC sp_whoisactive @get_outer_command = 1,@get_plans=1,@get_full_inner_text=1

--filter by preferred output columns
EXEC sp_WhoIsActive
 @output_column_list = '[session_id][login_name][sql_text]'
 , @delta_Interval = 5;


--check what filled up tran log
EXEC sp_WhoIsActive
 @output_column_list = '[dd%][session_id][tran%][login_name][sql_text][%]'
 , @get_transaction_info = 1;


--what is using the most memory
EXEC sp_WhoIsActive
 @output_column_list = '[dd%][session_id][%memory%][login_name][sql_text][%]'
 , @get_memory_info = 1;


--What filled up tempdb
EXEC sp_WhoIsActive
 @output_column_list = '[start_time][session_id][temp%][sql_text][query_plan][wait_info][%]'
 , @get_plans = 1
 , @sort_order = '[tempdb_current] DESC';

--Is there blocking?
EXEC sp_WhoIsActive
 @output_column_list = '[start_time][session_id][block%][login%][locks][sql_text][%]'
 , @find_block_leaders = 1
 , @get_locks = 1
 , @get_additional_info = 1
 , @sort_order = '[blocked_session_count] DESC';