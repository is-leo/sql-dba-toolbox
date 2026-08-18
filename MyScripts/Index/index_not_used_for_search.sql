--Index som inte använts för sökningar
SELECT  o.name AS object_name, 
		i.name AS index_name, 
		i.type_desc, 
		u.user_seeks, 
		u.user_scans, 
		u.user_lookups, 
		u.user_updates
FROM	sys.indexes i
JOIN	sys.objects o ON  i.object_id = o.object_id
LEFT JOIN  sys.dm_db_index_usage_stats u ON i.object_id = u.object_id
        AND    i.index_id = u.index_id
        AND    u.database_id = DB_ID()
WHERE   o.type <> 'S'    
and		isnull(u.user_updates,0) > 0
and		i.type_desc <> 'HEAP'
and		u.index_id is null or (u.user_updates > 0 and u.user_seeks < 10 and u.user_scans < 10 and u.user_lookups < 10)
ORDER BY  u.user_updates desc


--Samma men med en rolling sum av hur många updates som gjorts 
SELECT  o.name AS object_name, 
		i.name AS index_name, 
		i.type_desc, 
		u.user_seeks, 
		u.user_scans, 
		u.user_lookups, 
		u.user_updates,
		sum(u.user_updates) over (order by o.name, i.name) as 'Sum total'
FROM	sys.indexes i
JOIN	sys.objects o ON  i.object_id = o.object_id
LEFT JOIN  sys.dm_db_index_usage_stats u ON i.object_id = u.object_id
        AND    i.index_id = u.index_id
        AND    u.database_id = DB_ID()
WHERE   o.type <> 'S'    
and		isnull(u.user_updates,0) > 0
and		i.type_desc <> 'HEAP'
and		u.index_id is null or (u.user_updates > 0 and u.user_seeks < 10 and u.user_scans < 10 and u.user_lookups < 10)
order by o.name, i.name


--Samma men med summa per tabell 
SELECT  o.name AS object_name,
		SUM(u.user_updates)
FROM	sys.indexes i
JOIN	sys.objects o ON  i.object_id = o.object_id
LEFT JOIN  sys.dm_db_index_usage_stats u ON i.object_id = u.object_id
        AND    i.index_id = u.index_id
        AND    u.database_id = DB_ID()
WHERE   o.type <> 'S'    
and		isnull(u.user_updates,0) > 0
and		i.type_desc <> 'HEAP'
and		u.index_id is null or (u.user_updates > 0 and u.user_seeks < 10 and u.user_scans < 10 and u.user_lookups < 10)
GROUP BY o.name
ORDER BY SUM(u.user_updates) DESC
