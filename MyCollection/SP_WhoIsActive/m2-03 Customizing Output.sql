/* Queries running in the background */
/* User 1 (anna) - a database backup */
USE master;

BACKUP DATABASE AdventureWorks2016_EXT TO DISK = 'NUL' WITH INIT, COPY_ONLY;


/* User 2 (joy) - a lot of reads */
USE AdventureWorks2019;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	SELECT @Count = COUNT(Title)
	FROM Person.Person;


/* User 3 (ken) - a lot of reads from another database */
USE master;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	SELECT @Count = COUNT(*)
	FROM AdventureWorks2019.Sales.SalesOrderDetail;


/* User 4 (leo) - a lot of tempdb */
USE AdventureWorks2019;

SET NOCOUNT ON;

WHILE 1=1 BEGIN
	DROP TABLE IF EXISTS tempdb..#SalesOrderHeader

	SELECT *
	INTO #SalesOrderHeader
	FROM Sales.SalesOrderHeader;
	END


/*
T-SQL used:

sp_WhoIsActive
 @Output_Column_List = '[session_id][login_name][sql_text]'

sp_WhoIsActive
 @Output_Column_List = '[session_id][login_name][sql_text][percent_complete]'

sp_WhoIsActive
 @Output_Column_List = '[session_id][login_name][sql_text][%]'

sp_WhoIsActive
 @Output_Column_List = '[session_id][login_name][sql_text][%]'
 , @Filter_Type = 'login'
 , @Filter = 'leo'

sp_WhoIsActive
  @Output_Column_List = '[session_id][login_name][sql_text][%]'
 , @Filter_Type = 'login'
 , @Filter = 'GlobalInc%''
 , @Not_Filter_Type = 'login'
 , @Not_Filter = '%anna'

sp_WhoIsActive
  @Output_Column_List = '[database_name][session_id][login_name][sql_text][%]'
 , @Filter_Type = 'login'
 , @Filter = 'GlobalInc%''
 , @Not_Filter_Type = 'login'
 , @Not_Filter = '%anna'

sp_WhoIsActive
  @Output_Column_List = '[database_name][session_id][login_name][sql_text][%]'
 , @Filter_Type = 'database'
 , @Filter = 'AdventureWorks2019'
 , @Not_Filter_Type = 'login'
 , @Not_Filter = 'joy'
 , @Sort_Order = '[login_name] DESC'
 , @Get_Plans = 1

sp_WhoIsActive
  @Output_Column_List = '[database_name][session_id][login_name][sql_text][%]'
 , @Show_System_Spids = 1

sp_WhoIsActive
  @Output_Column_List = '[database_name][session_id][login_name][sql_text][%]'
 , @Show_Sleeping_Spids = 2

 */

