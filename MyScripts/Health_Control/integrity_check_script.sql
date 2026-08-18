IF OBJECT_ID('tempdb..#DBCCInfo', 'U') IS NOT NULL
    DROP TABLE #DBCCInfo;
CREATE TABLE #DBCCInfo (
	DBName VARCHAR(255),
    ParentObject VARCHAR(255),
    [Object] VARCHAR(255),
    Field VARCHAR(255),
    [VALUE] VARCHAR(255));

DECLARE @DBName NVARCHAR(128);

DECLARE db_cursor2 CURSOR FOR
SELECT [name]
FROM sys.databases

OPEN db_cursor2;

FETCH NEXT FROM db_cursor2 INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
DECLARE @SqlStatement NVARCHAR(1000) =  N'USE ' + QUOTENAME(@DBName) + ';
EXEC(''DBCC DBINFO(' + QUOTENAME(@DBName) + ') WITH TABLERESULTS'')'

DECLARE @DBCCInfoTable TABLE (
    ParentObject VARCHAR(255),
    [Object] VARCHAR(255),
    Field VARCHAR(255),
    [VALUE] VARCHAR(255)
);

-- Execute the DBCC DBINFO command and store the results in #DBCCInfo table
INSERT INTO @DBCCInfoTable  
EXEC sp_executesql @SqlStatement;

INSERT INTO #DBCCInfo (DBName, ParentObject, [Object], Field, [VALUE])
SELECT  @DBName, ParentObject, [Object], Field, [VALUE]
FROM @DBCCInfoTable;

    FETCH NEXT FROM db_cursor2 INTO @DBName;
END;

CLOSE db_cursor2;
DEALLOCATE db_cursor2;

DECLARE @DBCCInfo VARCHAR(MAX) = '';
SELECT @DBCCInfo= @DBCCInfo + DBName  + ' - '
+  max([VALUE]) + ' - ' + Field  + ' | '
FROM #DBCCInfo 
WHERE Field = 'dbi_dbccLastKnownGood'
GROUP BY DBName, Field;

IF @DBCCInfo = ''
BEGIN
    SET @DBCCInfo= 'Check if user dbs exist';
END

SELECT @DBCCInfo

