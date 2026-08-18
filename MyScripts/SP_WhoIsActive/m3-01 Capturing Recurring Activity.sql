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
*/

/* Create destination table */


USE AdventureWorks2019;

DECLARE @Create_Destination_Table VARCHAR(MAX);

EXEC sp_WhoIsActive
 @Return_Schema = 1
 , @Schema = @Create_Destination_Table OUTPUT;

SELECT @Create_Destination_Table;


/* Copy output to another tab, change <table_name> in output to dbo.WhoIsActive_Log, and execute */


/* Capture data in destination table */

EXEC sp_WhoIsActive
    @Destination_Table = 'dbo.WhoIsActive_Log';

SELECT *
FROM dbo.WhoIsActive_Log;


/* Add step to purge records over a week old */

DELETE
FROM dbo.WhoIsActive_Log
WHERE collection_time < DATEADD(day, -7, GETDATE());


/* Add index to improve performance of purge */

CREATE INDEX ix_WhoIsActive_Log_collection_time ON dbo.WhoIsActive_Log (collection_time);


