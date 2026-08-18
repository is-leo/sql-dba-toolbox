--Alternative 1
/* This stored procedures helps to find a string value in a table:

This sp takes three parameters:

1 stringToFind - this is the search string you are looking for.
	Ex 'test' or '%test%','%test' , 'test%'.
2 schema name - this is the schema owner of the object
3 table name - sp searches char, nchar, ntext, nvarchar, 
	text and varchar columns in the base table 

*/

USE master
GO

CREATE PROCEDURE dbo.sp_FindStringInTable @stringToFind VARCHAR(max), @schema sysname, @table sysname 
AS

SET NOCOUNT ON

BEGIN TRY
   DECLARE @sqlCommand varchar(max) = 'SELECT * FROM [' + @schema + '].[' + @table + '] WHERE ' 
	   
   SELECT @sqlCommand = @sqlCommand + '[' + COLUMN_NAME + '] LIKE ''' + @stringToFind + ''' OR '
   FROM INFORMATION_SCHEMA.COLUMNS 
   WHERE TABLE_SCHEMA = @schema
   AND TABLE_NAME = @table 
   AND DATA_TYPE IN ('char','nchar','ntext','nvarchar','text','varchar')

   SET @sqlCommand = left(@sqlCommand,len(@sqlCommand)-3)
   EXEC (@sqlCommand)
   PRINT @sqlCommand
END TRY

BEGIN CATCH 
   PRINT 'There was an error. Check to make sure object exists.'
   PRINT error_message()
END CATCH 
GO

--After the stored procedure has been created it needs to be marked
--as a system stored procedure.

USE master
EXEC sys.sp_MS_marksystemobject sp_FindStringInTable
GO

--TEST IT
--EXEC SP_FINDSTRINGINTABLE 'IRV%', 'PERSON', 'ADDRESS' 


--ALTERNATIVE 2
CREATE PROCEDURE dbo.SearchAllDatabases
  @SearchTerm NVARCHAR(255) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  
  IF @SearchTerm IS NULL OR @SearchTerm NOT LIKE N'%[^%^_]%'
  BEGIN
    RAISERROR(N'Please enter a valid search term.', 11, 1);
    RETURN;
  END
 
  CREATE TABLE #results
  (
    [database]   SYSNAME,
    [schema]     SYSNAME,
    [table]      SYSNAME, 
    [column]     SYSNAME,
    ExampleValue NVARCHAR(1000)
  );

  DECLARE
    @DatabaseCommands  NVARCHAR(MAX) = N'', 
    @ColumnCommands    NVARCHAR(MAX) = N'';

  SELECT @DatabaseCommands = @DatabaseCommands + N'
    EXEC ' + QUOTENAME(name) + '.sys.sp_executesql 
        @ColumnCommands, N''@SearchTerm NVARCHAR(MAX)'', @SearchTerm;'
    FROM sys.databases 
    WHERE database_id  > 4  -- non-system databases  
      AND [state]      = 0  -- online 
      AND user_access  = 0; -- multi-user

    SET @ColumnCommands = N'DECLARE @q NCHAR(1),
          @SearchCommands NVARCHAR(MAX);
    
    SELECT @q = NCHAR(39), 
      @SearchCommands = N''DECLARE @VSearchTerm VARCHAR(255) = @SearchTerm;'';
  
    SELECT @SearchCommands = @SearchCommands + CHAR(10) + N''

      SELECT TOP (1)
        [db]     = DB_NAME(),
        [schema] = N'' + @q + s.name + @q + '', 
        [table]  = N'' + @q + t.name + @q + '',
        [column] = N'' + @q + c.name + @q + '',
        ExampleValue = LEFT('' + QUOTENAME(c.name) + '', 1000) 
      FROM '' + QUOTENAME(s.name) + ''.'' + QUOTENAME(t.name) + ''
      WHERE '' + QUOTENAME(c.name) + N'' LIKE @'' + CASE 
        WHEN c.system_type_id IN (35, 167, 175) THEN ''V'' 
        ELSE '''' END + ''SearchTerm;'' 
 
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
    ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
    ON t.[object_id] = c.[object_id]
    WHERE c.system_type_id IN (35, 99, 167, 175, 231, 239)
      AND c.max_length >= LEN(@SearchTerm);

    PRINT @SearchCommands;
    EXEC sys.sp_executesql @SearchCommands, 
      N''@SearchTerm NVARCHAR(255)'', @SearchTerm;';
  
  INSERT #Results
  (
    [database],
    [schema],
    [table],
    [column],
    ExampleValue
  )
  EXEC [master].sys.sp_executesql @DatabaseCommands, 
    N'@ColumnCommands NVARCHAR(MAX), @SearchTerm NVARCHAR(255)', 
    @ColumnCommands, @SearchTerm;

  SELECT [Searched for] = @SearchTerm;
  
  SELECT [database],[schema],[table],[column],ExampleValue 
    FROM #Results 
    ORDER BY [database],[schema],[table],[column];
END
GO

--search across all string columns, across all tables, across all databases
--Tips comes from  https://www.mssqltips.com/sqlservertip/4039/search-all-string-columns-in-all-sql-server-databases/ 

--Syntax
EXEC dbo.SearchAllDatabases @SearchTerm = N'%<string-to-find>%';


--Sample Calls to Find Text
--generate an error because this is not a sensible search:
EXEC dbo.SearchAllDatabases @SearchTerm = N'%';
GO

--search for columns containing "http://"
EXEC dbo.SearchAllDatabases @SearchTerm = N'%http://%';

--search for columns containing "%" or "":
EXEC dbo.SearchAllDatabases @SearchTerm = N'%[%]%';
EXEC dbo.SearchAllDatabases @SearchTerm = N'%[]%';

--search for columns containing "update" followed by "dbo.":
EXEC dbo.SearchAllDatabases @SearchTerm = N'%update%dbo.%';

--search for columns containing "update":
EXEC dbo.SearchAllDatabases @SearchTerm = N'%update%';



--Alternative 3

--https://hanssens.com/code/search-entire-sql-server-database-and-all-tables-for-a-specified-string/

--Simply create it in the database and use it like so:

exec SearchAllTables 'gummy bears';

--This executes a case insensitive search on all tables in the relevant database, and neatly spits out the fields where the string occurs in.
--Here is the stored procedure

CREATE PROC SearchAllTables ( @SearchStr nvarchar(100) ) AS BEGIN

-- Copyright © 2002 Narayana Vyas Kondreddi. All rights reserved.
-- Purpose: To search all columns of all tables for a given search string
-- Written by: Narayana Vyas Kondreddi
-- Site: http://vyaskn.tripod.com + http://stackoverflow.com/questions/436351/how-do-i-find-a-value-anywhere-in-a-sql-server-database
-- Tested on: SQL Server 7.0 and SQL Server 2000
-- Date modified: 28th July 2002 22:50 GMT

DECLARE @Results TABLE(ColumnName nvarchar(370), ColumnValue nvarchar(3630))

SET NOCOUNT ON

DECLARE @TableName nvarchar(256), @ColumnName nvarchar(128), @SearchStr2 nvarchar(110)
SET  @TableName = ''
SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')

WHILE @TableName IS NOT NULL
BEGIN
    SET @ColumnName = ''
    SET @TableName = 
    (
        SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
        FROM    INFORMATION_SCHEMA.TABLES
        WHERE       TABLE_TYPE = 'BASE TABLE'
            AND QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
            AND OBJECTPROPERTY(
                    OBJECT_ID(
                        QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                         ), 'IsMSShipped'
                           ) = 0
    )

    WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
    BEGIN
        SET @ColumnName =
        (
            SELECT MIN(QUOTENAME(COLUMN_NAME))
            FROM    INFORMATION_SCHEMA.COLUMNS
            WHERE       TABLE_SCHEMA    = PARSENAME(@TableName, 2)
                AND TABLE_NAME  = PARSENAME(@TableName, 1)
                AND DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar')
                AND QUOTENAME(COLUMN_NAME) > @ColumnName
        )

        IF @ColumnName IS NOT NULL
        BEGIN
            INSERT INTO @Results
            EXEC
            (
                'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) 
                FROM ' + @TableName + ' (NOLOCK) ' +
                ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
            )
        END
    END 
END

SELECT ColumnName, ColumnValue FROM @Results
END