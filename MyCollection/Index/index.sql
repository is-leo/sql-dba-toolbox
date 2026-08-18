-- Declare a variable for database name to improve flexibility
DECLARE @dbName NVARCHAR(128) = N'AdventureWorksLT';

-- Retrieve index fragmentation stats for the specified database along with the index name
SELECT 
    OBJECT_NAME(ips.OBJECT_ID) AS ObjectName,        -- Name of the table or view
    i.name AS IndexName,                            -- Name of the index
    ips.index_id,                                   -- ID of the index
    ips.index_type_desc AS IndexType,               -- Type of index (Clustered, Non-Clustered, etc.)
    ips.index_level AS IndexLevel,                  -- Level of the index (leaf/non-leaf)
    ips.avg_fragmentation_in_percent AS FragmentationPercent, -- Percentage of fragmented pages
    ips.avg_page_space_used_in_percent AS PageSpaceUsedPercent, -- Percentage of page space used
    ips.page_count AS PageCount                     -- Total number of pages in the index
FROM sys.dm_db_index_physical_stats(
    DB_ID(@dbName),     -- Database ID of the selected database
    NULL,               -- Object ID (NULL = all objects)
    NULL,               -- Index ID (NULL = all indexes)
    NULL,               -- Partition number (NULL = all partitions)
    'SAMPLED'           -- Sampled mode for performance reasons (other options: 'DETAILED', 'LIMITED')
) ips
JOIN sys.indexes i
    ON ips.OBJECT_ID = i.OBJECT_ID AND ips.index_id = i.index_id  -- Joining with sys.indexes to get the index name
ORDER BY ips.avg_fragmentation_in_percent DESC;     -- Order by fragmentation percentage (high to low)


/*
If avg_fragmentation_in_percent > 5% and < 30%, then use ALTER INDEX REORGANIZE: 
This statement is replacement for DBCC INDEXDEFRAG to reorder the leaf level pages 
of the index in a logical order. 
As this is an online operation, the index is available while the statement is running.

If avg_fragmentation_in_percent > 30%, then use ALTER INDEX REBUILD: 
This is replacement for DBCC DBREINDEX to rebuild the index online or offline. 
In such case, we can also use the drop and re-create index method.
*/

ALTER INDEX XMLPROPERTY_Person_Demographics ON Person.Person
REBUILD WITH ( SORT_IN_TEMPDB = ON)
