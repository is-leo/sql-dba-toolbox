/* Doorstop */
RAISERROR(N'Did you mean to run the whole thing?',20,1) WITH LOG;
GO


/*************************************************
WAIT STATS
*************************************************/

/* 
My preferred wait stats script

https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/blob/dev/sp_BlitzFirst.sql
*/


exec sp_BlitzFirst @SinceStartup=1, @ExpertMode=1;
GO

/*
Run in another window --  Enable SQLCMD mode for the session in SSMS (Query menu) 
-r is set to 10 here so it will run for longer
-n is set to 2 here so it will leave more cpu room
*/
!!ostress.exe -S192.168.4.181,1435 -dStackOverflow2010 -Usa -PPassword23 -q -n4 -r10 -i"C:\Temp\mistakes_02-workload.sql" -T146


/* Sample wait stats 
while the workload is running */

exec sp_BlitzFirst @Seconds=20, @ExpertMode=1;
GO


exec sp_BlitzWho @ExpertMode=1, @GetLiveQueryPlan=1;
GO


exec sp_BlitzQueryStore @DatabaseName='StackOverflow2010';
GO