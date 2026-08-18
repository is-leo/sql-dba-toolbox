/*
https://upbase.atlassian.net/wiki/spaces/UP/pages/601293011/Performance+sql+server

The Best SQL Server Performance Monitor Counters to Analyze. According to https://www.brentozar.com/archive/2006/12/dba-101-using-perfmon-for-sql-performance-tuning/


Diagnosing Disk I/O Issues
PerfMon: Physical Disk\Disk sec/Reads and Physical Disk\Disk sec/Writes counters.
•	 Less than 10 ms = good performance
•	 Between 10 ms and 20 ms = slow performance
•	 Between 20 ms and 50 ms = poor performance
•	 Greater than 50 ms = significant performance problem.


SQL Performance troubleshooting – what are the questions?
The first question is identify the task . What task is running?
The second question. How long is the task  taking ?
The third question – How long should the task take?
For example – The task is a SQL Server backup . It’s taking 5 hrs and it normally takes 2 hrs.

I cannot tell you how many times an owner will report an issue with general terms such as “it’s slow”. OK, what is slow? and how are you measuring it’s slow, is it for example a Datawarehouse report  that is taking 30 minutes ? OK, next question , how long does it normally take to complete?

The steps below are a straightforward approach to troubleshooting sub optimal SQL Execution Plans.

Step 1)  Statistics – Is Auto Create and Update Statistics Enabled? If Auto Create statistics is disabled , this may indicate out of date statistics. If Disabled, than proceed to  Update Statistics – use sp_updatestats to update all statistics on the database. Run the query and check if any improvement.

Step 2)  If  Auto Create and Update Statistics is Enabled, Identify the longest running queries or highest impact queries .( If the queries have high CPU usage go to step 6). Long duration and highest IO should be a priority.

Step 3)       Place every query in the SSMS and analyse the execution plan. First – check for tables or index scans.  If large table \ index scans are occurring – progress with Query Analysis.  The Query Analysis should ask questions such as : Are all JOINS valid ? Are the JOINS returning excessive data ? Search argument validity?   Functions in predicate? 
Step 4)       If no table or index scans exist and  the query is complex , for example a large transaction managing a booking process –  check for : excessive joins, temp tables, DDL changes, sub – queries , no set based approach to writing the queries. Review  the query ,  break it down into smaller parts or analyse the JOINS to invoke a new execution plan , ensuring a similar transaction integrity is retained
Step 5)       If the query is simple and no no index \table scans exists and executing in  SSMS responds with acceptable  performance - analyse the Application and how it processes the resultset.   Ask the right question a) are just relevant results returned?  Talk to the application developers.
Step  6)       If the query is no faster in SSMS , more complex query tuning is required,  research other methods or contact a performance tuning expert
Step 7)       If in Step  2 you identified queries  with high CPU usage , analyse in SSMS for Hash Joins, Sorts, Filters.  If any of these exists , progress with Query Analysis.
Step 8)       Repeat until the problem disappears.

From <https://www.sqlserver-dba.com/2012/11/sql-server-how-to-troubleshoot-a-slow-running-query.html> 

*/
--Att lösa parameter sniffing problemet deklarera värdet som variable inne i lokala statement:

CREATE PROCEDURE x (@p1 int)
AS
BEGIN
	DECLARE @local_p1 int
	SET @local_p1 = @p1
	SELECT * FROM tab WHERE id=@local_p1
END


