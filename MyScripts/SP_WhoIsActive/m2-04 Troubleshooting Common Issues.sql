/* Queries running in the background */
/* User 1 (mia) - a parallel plan */
USE AdventureWorks2016_EXT;

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

DECLARE @PurchaseOrderNumber NVARCHAR(25);

WHILE 1=1
	SELECT @PurchaseOrderNumber = MIN(soh1.PurchaseOrderNumber)
	FROM Sales.SalesOrderHeaderBulk soh1
	JOIN Sales.SalesOrderHeaderBulk soh2
	 ON soh1.SalesOrderID = soh1.SalesOrderID
	 AND soh1.rowguid = soh2.rowguid
	JOIN Sales.SalesOrderHeaderBulk soh3
	 ON soh2.SalesOrderID = soh3.SalesOrderID
	 AND soh2.rowguid = soh3.rowguid;


/* User 2 (joy) - a lot of reads */
USE AdventureWorks2019;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	SELECT @Count = COUNT(Title)
	FROM Person.Person
	WHERE Title = 'Mrs';


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
	DROP TABLE IF EXISTS #SalesOrderHeader

	SELECT SalesOrderID
	INTO #SalesOrderHeader
	FROM Sales.SalesOrderHeader;
	END

/*
T-SQL used:

sp_WhoIsActive
 @Delta_Interval = 5
 , @Output_Column_List = '[%delta][%]'

sp_WhoIsActive --(execute with no parameters)

sp_WhoIsActive
 @Get_Task_Info = 2

sp_WhoIsActive
 @Get_Plans = 2

*/