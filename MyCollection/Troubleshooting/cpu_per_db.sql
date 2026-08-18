--Returns the top databases by CPU usage.
WITH DB_CPU_Stats
AS
(
  SELECT
    DatabaseID,
    DB_Name(DatabaseID) AS [DatabaseName],
    SUM(total_worker_time) AS [CPU_Time_Ms]
  FROM sys.dm_exec_query_stats AS qs
  CROSS APPLY
    (
      SELECT
        CONVERT(int, value) AS [DatabaseID]
      FROM sys.dm_exec_plan_attributes(qs.plan_handle)
      WHERE attribute = N'dbid'
    ) AS F_DB
  GROUP BY DatabaseID
)
SELECT
  ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
    DatabaseName,
    [CPU_Time_Ms],
    CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE (DatabaseID > 4) AND (DatabaseID <> 32767)
ORDER BY row_num


/*
The query performs the following steps:

Defines a Common Table Expression (CTE) called "DB_CPU_Stats". 
The CTE calculates the CPU usage for each database by summing the total worker time 
for all queries executed on the database. The database ID and name are also obtained 
for each database.

Selects rows from the CTE, computing the rank of each database based on its CPU usage, 
along with the database name, total CPU usage in milliseconds, and CPU usage as 
a percentage of the total CPU usage for all databases.

Filters the output to exclude the system databases (with IDs less than or equal to 4) 
and the resource database (with ID 32767).
Orders the output by the calculated row number, so that the top database 
by CPU usage is displayed first.*/ 