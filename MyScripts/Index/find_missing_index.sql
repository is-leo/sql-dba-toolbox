;with cte
AS
(
SELECT CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage], 
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
COUNT(1) OVER(PARTITION BY mid.[statement]) AS missing_indexes_4_table,
COUNT(1) OVER(PARTITION BY mid.[statement],equality_columns) AS similar_missing_indexes_4_table,
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
)
SELECT Total_advantage = SUM(index_advantage) OVER(PARTITION BY [Database.Schema.Table],equality_columns), * FROM cte
ORDER BY Total_advantage desc,index_advantage DESC OPTION (RECOMPILE);



;with cte
AS
(
SELECT CONVERT(decimal(18,2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) AS [index_advantage], 
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
COUNT(1) OVER(PARTITION BY mid.[statement]) AS missing_indexes_4_table,
COUNT(1) OVER(PARTITION BY mid.[statement],equality_columns) AS similar_missing_indexes_4_table,
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
)
SELECT Total_advantage = SUM(index_advantage) OVER(PARTITION BY [Database.Schema.Table],equality_columns), *
, 'CREATE NONCLUSTERED INDEX IX_XYZ ON ' + cte.[Database.Schema.Table] + ' (' + ISNULL(equality_columns,'') + ',' + ISNULL(inequality_columns,'') + ') INCLUDE (' + included_columns + ') WITH (ONLINE=ON, DATA-COMPRESSION=PAGE)'
 FROM cte
ORDER BY Total_advantage desc,index_advantage DESC OPTION (RECOMPILE);