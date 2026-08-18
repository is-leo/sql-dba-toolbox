-- File names and paths for all user and system databases on instance  (Query 24) (Database Filenames and Paths)
SELECT DB_NAME([database_id]) AS [Database Name], 
       [file_id], [name], physical_name, [type_desc], state_desc,
	   is_percent_growth, growth, 
	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 
       CONVERT(bigint, size/128.0) AS [Total Size in MB], max_size
FROM sys.master_files WITH (NOLOCK)
ORDER BY DB_NAME([database_id]), [file_id] OPTION (RECOMPILE);


/*

Things to look at:

Are data files and log files on different drives?
Is everything on the C: drive?
Is tempdb on dedicated drives?
Is there only one tempdb data file?
Are all of the tempdb data files the same size?
Are there multiple data files for user databases?
Is percent growth enabled for any files (which is bad)? */ 