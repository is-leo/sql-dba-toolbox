/* Queries running in the background */
/* User 1 (mia) - a lot of reads */
USE AdventureWorks2019;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	SELECT @Count = COUNT(Title)
	FROM Person.Person
	WHERE Title = 'Mrs.';


/* User 2 (joy) - a lot of updates */
USE AdventureWorks2019;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	UPDATE Person.Person
	SET Title = Title
	WHERE Title = 'Ms.';


/* User 3 (ken) - a lot of reads from another database */
USE master;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	SELECT @Count = COUNT(Title)
	FROM AdventureWorks2019.Person.Person
	WHERE Title = 'Mr.';


/* User 4 (leo) - open transaction */
USE AdventureWorks2019;

SET NOCOUNT ON;

BEGIN TRANSACTION

	UPDATE Person.Person
	SET Title = Title
	WHERE Title = 'Sr.';

--COMMIT

/*
T-SQL used:

sp_WhoIsActive
 @Get_Avg_Time = 1

sp_WhoIsActive
 @Output_Column_List = '[session_id][block%][login%][%]'

--this shows which is the lead blocker
sp_WhoIsActive
 @Output_Column_List = '[session_id][block%][login%][%]'
 , @Find_Block_Leaders = 1
 , @Sort_Order = '[blocked_session_count] DESC'

 --this shows all the locks taken by the transaction (look for x [exclusive] locks )
sp_WhoIsActive
 @Output_Column_List = '[session_id][block%][login%][locks][%]'
 , @Find_Block_Leaders = 1
 , @Sort_Order = '[blocked_session_count] DESC'
 , @Get_Locks = 1

 --gives info about isolation level, some are prone to blockings
sp_WhoIsActive
 @Output_Column_List = '[session_id][block%][login%][additional%][%]'
 , @Find_Block_Leaders = 1
 , @Sort_Order = '[blocked_session_count] DESC'
 , @Get_Additional_Info = 1

*/