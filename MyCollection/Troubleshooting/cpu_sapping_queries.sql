-- Top 10 CPU-sapping queries for which plans exist in the cache        
SELECT TOP 10
		total_worker_time ,
        execution_count ,
        total_worker_time / execution_count AS [Avg CPU Time] ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText,
		qp.query_plan
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
		cross apply sys.dm_exec_query_plan(deqs.plan_handle) as qp
ORDER BY deqs.total_worker_time DESC ;
