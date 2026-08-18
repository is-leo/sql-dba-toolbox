 /* Before running demo */
CREATE TABLE SomeTable (SomeID int IDENTITY(1,1), SomeValue VARCHAR(20));

/* Queries running in the background */
/* User 1 (leo) - open transaction */
USE AdventureWorks2019;

BEGIN TRAN
       INSERT SomeTable(SomeValue)
       SELECT 'Something Else'


/* Create and rename destination table in one batch */
USE AdventureWorks2019;

DECLARE 
 @Create_Destination_Table NVARCHAR(MAX)
 , @Table_Name VARCHAR(100);

SET @Table_Name = 'dbo.WhoIsActive_TimeoutLog';

EXEC sp_WhoIsActive
 @Output_Column_List = '[collection_time][session_id][login_name][sql_text][blocking%]'
 , @Return_Schema = 1
 , @Schema = @Create_Destination_Table OUTPUT;

SET @Create_Destination_Table = REPLACE(@Create_Destination_Table, '<table_name>', @Table_Name);

EXEC sp_executesql @Create_Destination_Table;
GO


/* Demo of capturing activity in T-SQL */
USE AdventureWorks2019;

DECLARE @SomeID int
 
BEGIN TRY
 SET LOCK_TIMEOUT 1000 /*1000 = 1 second */
 BEGIN TRAN
  SELECT @SomeID = SomeID
  FROM SomeTable
  WHERE SomeValue = 'Something'
 COMMIT
END TRY
BEGIN CATCH
 IF ERROR_NUMBER() IN (
  1204 /* Out of locks */
  , 1205 /* Deadlock victim */
  , 1222 /* Request timeout */
  )
  BEGIN
   EXEC sp_WhoIsActive
    @Output_Column_List = '[collection_time][session_id][login_name][sql_text][blocking%]'
    , @Destination_Table = 'dbo.WhoIsActive_TimeoutLog'
  END
 IF @@TRANCOUNT > 0
  BEGIN
   ROLLBACK
  END
END CATCH
 

/* Review captured activity */
SELECT * 
FROM dbo.WhoIsActive_TimeoutLog
