/******Demo 6: Parameter Sensitive Plan Optimization********/

--ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SENSITIVE_PLAN_OPTIMIZATION = ON 


USE [Adventureworks2022]
GO
IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE type = 'P'
			AND name = 'Salesinformation'
		)
	DROP PROCEDURE dbo.Salesinformation
GO
CREATE PROCEDURE dbo.Salesinformation @productID [int]
AS
BEGIN
	SELECT [SalesOrderID]
		,[ProductID]
		,[OrderQty]
	FROM [Sales].[SalesOrderDetailEnlarged]
	WHERE [ProductID] = @productID
END;


/*PSP optimization enable just by chaning the compat level of the db to 160 */

USE [master]
GO
ALTER DATABASE [Adventureworks2022] SET COMPATIBILITY_LEVEL = 160
GO

/*clear the Query store */
ALTER DATABASE [AdventureWorks2022]
SET QUERY_STORE CLEAR;

/* Clean the procedure cache */
USE [Adventureworks2022]
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE

USE [Adventureworks2022]
GO
SELECT sh.* 
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_histogram(s.object_id, s.stats_id) AS sh
WHERE name = 'IX_SalesOrderDetailEnlarged_ProductID' 
AND s.object_id =OBJECT_ID('Sales.SalesOrderDetailEnlarged')
ORDER BY equal_rows DESC
GO

/* execute the stored procedure using different parameters*/

/*Parameter with many rows */

EXEC dbo.Salesinformation 870


/*Parameter with some rows */

EXEC dbo.Salesinformation 942


EXEC dbo.Salesinformation 898



SELECT *
--usecounts, plan_handle, text 
FROM sys.dm_exec_cached_plans
CROSS APPLY sys.dm_exec_sql_text (plan_handle)
WHERE text LIKE '%SalesOrderDetailEnlarged%'
and objtype = 'Prepared'
GO



