-- index fragmentation
SELECT *
FROM sys.dm_db_index_physical_stats (NULL, NULL, NULL, NULL, NULL)
ORDER BY avg_fragmentation_in_percent DESC;

--index usage 
SELECT o.name Object_Name,
       SCHEMA_NAME(o.schema_id) Schema_name,
       i.name Index_name,
       i.Type_Desc,
       s.user_seeks,
       s.user_scans,
       s.user_lookups,
       s.user_updates 
 FROM sys.objects AS o
     JOIN sys.indexes AS i
 ON o.object_id = i.object_id
     JOIN
  sys.dm_db_index_usage_stats AS s   
 ON i.object_id = s.object_id  
  AND i.index_id = s.index_id
 WHERE  o.type = 'u'
 -- Clustered and Non-Clustered indexes
  AND i.type IN (1, 2);


--fragmentation per db
SELECT db_NAME(indexstats.database_id) as [database],
 dbschemas.[name] as 'Schema', 
 dbtables.[name] as 'Table', 
 dbindexes.[name] as 'Index',
 indexstats.alloc_unit_type_desc,
 indexstats.avg_fragmentation_in_percent,
 indexstats.page_count
 FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
 INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
 INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
 INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
 AND indexstats.index_id = dbindexes.index_id
 WHERE indexstats.database_id = DB_ID()
 ORDER BY indexstats.avg_fragmentation_in_percent desc

 -- fragmentation per db (pages more than 2500)
 SELECT DB_NAME(ps.database_id) AS [Database Name], SCHEMA_NAME(o.[schema_id]) AS [Schema Name],
 OBJECT_NAME(ps.OBJECT_ID) AS [Object Name], 
 i.name AS [Index Name], ps.index_id, ps.index_type_desc, ps.avg_fragmentation_in_percent, 
 ps.fragment_count, ps.page_count, i.fill_factor, i.has_filter, i.filter_definition, i.allow_page_locks
 FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL , N'LIMITED') AS ps
 INNER JOIN sys.indexes AS i WITH (NOLOCK)
 ON ps.[object_id] = i.[object_id] 
 AND ps.index_id = i.index_id
 INNER JOIN sys.objects AS o WITH (NOLOCK)
 ON i.[object_id] = o.[object_id]
 WHERE ps.database_id = DB_ID()
 AND ps.page_count > 2500
 ORDER BY ps.avg_fragmentation_in_percent DESC OPTION (RECOMPILE);