/*
	SHOW_STATISTICS does not provide statistics for spatial indexes
	The stats blob is in the system table sys.sysobjvalues
*/
USE [AdventureWorks2014];
GO


/*
	Note that IX_SalesOrderDetail_ProductID is on one column, ProductID
*/
sp_helpindex 'Sales.SalesOrderDetail';
GO


/*
	Kimberly's version
*/
sp_SQLskills_SQL2012_helpindex 'Sales.SalesOrderDetail';
GO

DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail',IX_SalesOrderDetail_ProductID);
GO

DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail',IX_SalesOrderDetail_ProductID) WITH STAT_HEADER;
GO

DBCC SHOW_STATISTICS ('Sales.SalesOrderDetail',IX_SalesOrderDetail_ProductID) WITH DENSITY_VECTOR;
GO

DBCC SHOW_STATISTICS ("Sales.SalesOrderDetail",IX_SalesOrderDetail_ProductID) WITH HISTOGRAM;
GO


/*
	Optional for SQL 2008R2 SP2+, and SQL 2012 SP1+
	(get object_id and index_id)
*/
USE [AdventureWorks2014];
GO

SELECT [sch].[name] + '.' + [so].[name], [so].[object_id], [ss].[name], [ss].[stats_id]
FROM [sys].[stats] [ss]
JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
JOIN [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
WHERE [so].[name] =  N'SalesOrderDetail';


/*
	View stat header info easily with new DMF
*/
SELECT *
FROM [sys].[dm_db_stats_properties](1154103152,3);


/*
	Now bring it all together...
*/
SELECT
	[sch].[name] + '.' + [so].[name] "Table",
	[ss].[name] AS "Statistic",
	CASE
		WHEN [ss].[auto_created] = 0 AND [ss].[user_created] = 0 THEN 'Index Statistic'
		WHEN [ss].[auto_created] = 0 AND [ss].[user_created] = 1 THEN 'User Created'
		WHEN [ss].[auto_created] = 1 AND [ss].[user_created] = 0 THEN 'Auto Created'
		WHEN [ss].[auto_created] = 1 AND [ss].[user_created] = 1 THEN 'Not Possible?'
	END "Statistic Type",
	STUFF(( SELECT  ', ' + [c].[name]
                FROM    [sys].[stats_columns] [sc]
                        JOIN [sys].[columns] [c] ON [c].[column_id] = [sc].[column_id]
                                                    AND [c].[object_id] = [sc].[OBJECT_ID]
                WHERE   [sc].[object_id] = [ss].[object_id]
                        AND [sc].[stats_id] = [ss].[stats_id]
                ORDER BY [sc].[stats_column_id]
              FOR
                XML PATH('')
              ), 1, 2, '') AS [ColumnsInStatistic] ,
	CASE
		WHEN [ss].[has_filter] = 1 THEN 'Filtered Index'
		WHEN [ss].[has_filter] = 0 THEN 'No Filter'
	END "Filtered?",
	CASE
		WHEN [ss].[filter_definition] IS NULL THEN ''
		WHEN [ss].[filter_definition] IS NOT NULL THEN [ss].[filter_definition]
	END "Filter Definition",
	[sp].[last_updated] "Stats Last Updated",
	[sp].[rows] "Rows",
	[sp].[rows_sampled] "Rows Sampled",
	[sp].[unfiltered_rows] "Unfiltered Rows",
	[sp].[modification_counter] "Row Modifications",
	[sp].[steps] "Histogram Steps"
FROM [sys].[stats] [ss]
JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
JOIN [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id], [ss].[stats_id]) sp
WHERE [so].[type] = 'U'
ORDER BY [sp].[last_updated] DESC;