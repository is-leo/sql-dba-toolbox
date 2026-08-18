
/*Denna script består av 2 delar: 

 PART 1: Create Alert */
--create sp SQL_ErrorLog_Alert
CREATE PROCEDURE [dbo].[SQL_ErrorLog_Alert]
@Minutes [int] = NULL  
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ERRORMSG varchar(8000)
DECLARE @Mins INT
IF @Minutes IS NULL  -- If the optional parameter is not passed, @Mins value is set to 6
 SET @Mins = 6
ELSE
 SET @Mins = @Minutes

 -- a temporary table to keep data from the error log
 CREATE TABLE #ErrorLogTable 
 (LogDate DATETIME, ProcessInfo VARCHAR(50) ,[Text] VARCHAR(4000))
 INSERT INTO #ErrorLogTable 
 -- a specific error message is searched ans stored in the temp table (ex. all login failures)
 EXEC sp_readerrorlog  0, 1,
'Login failed for user '

--delete information older than @Mins (current date - 6 minutes) from the temp table 
 DELETE FROM #ErrorLogTable 
 WHERE LogDate < CAST(DATEADD(MI,-@Mins,GETDATE()) AS VARCHAR(23))

 --concatenate the rows in the temporary table and store into single variable 
 SELECT  @ERRORMSG = COALESCE(@ERRORMSG + CHAR(13) , '') 
   + CAST(LogDate AS VARCHAR(23)) + '  ' 
   + [Text] FROM #ErrorLogTable

--drop the temp table #ErrorLogTable as the info is now stored in the variable @ERRORMSG
 DROP TABLE #ErrorLogTable
 END

IF @ERRORMSG IS NOT NULL 
  -- There is some data in SQL error log that needs to be stored
  BEGIN
  IF  EXISTS (SELECT * FROM dbo.sysobjects 
    WHERE  id = OBJECT_ID(N'[dbo].[SQL_ErrorLog]') 
    AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
	INSERT INTO [dbo].[SQL_ErrorLog]
	SELECT @ERRORMSG

  ELSE

  BEGIN
  CREATE TABLE [dbo].[SQL_ErrorLog](
   [TEXT] [varchar](8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
   ) ON [PRIMARY]
  INSERT INTO [dbo].[SQL_ErrorLog]
  SELECT @ERRORMSG
 END
END
ELSE  -- No error messages have been in the last @Mins minutes
 Print 'No Error Messages'
 GO
 ---------------------------------------------------------------

/* PART 2: Notify Alert*/
CREATE PROCEDURE [dbo].[SQL_ErrorLog_Alert_Notify]
@LKDSVRNAME VARCHAR(128) = NULL
AS
BEGIN
SET NOCOUNT ON;
DECLARE @SUBJECT  VARCHAR(8000)
DECLARE @MSGBODY  VARCHAR(8000)
 IF @LKDSVRNAME IS NOT NULL  


    /* A linked server name is passed, so alert will be for the linked server.*/
  
 BEGIN
   
  CREATE TABLE #ERRTBL ([TEXT] VARCHAR(8000)) 
  /* Temporary table to poll the linked server 
  and store the error data to be used in the cursor, in the next step */
 
  INSERT INTO #ERRTBL
  EXEC('SELECT [Text] FROM ' + @LKDSVRNAME + '.let_tst.DBO.SQL_ErrorLog')
  
  SET @SUBJECT = @LKDSVRNAME + ' SQL-SERVER ERROR LOG SUMMARY'
  DECLARE CURSOR1 CURSOR
  FOR SELECT [TEXT] FROM #ERRTBL
  
  OPEN CURSOR1
  FETCH NEXT FROM CURSOR1
  INTO @MSGBODY
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SQL ALERTING PROFILE', -- Modify the profile name
    @recipients = 'leo.ismatov@sqlservice.se',-- Modify the email
    @body = @MSGBODY, 
    @subject = @SUBJECT ; 
  FETCH NEXT FROM CURSOR1
  INTO @MSGBODY
  END 
  CLOSE CURSOR1
  DEALLOCATE CURSOR1 
  EXEC ('DELETE FROM ' + @LKDSVRNAME + '.let_tst.DBO.SQL_ErrorLog') 
     
     -- Modify the database name
     
  DROP TABLE #ERRTBL
   
 END
  ELSE  

  /* A linked server name is not passed, 
  so alert will be for the local server. */
   
 BEGIN
    
  SET @SUBJECT = @@SERVERNAME + ' SQL-SERVER ERROR LOG SUMMARY'
  DECLARE CURSOR1 CURSOR
  FOR SELECT [TEXT] FROM let_tst.DBO.SQL_ErrorLog
  OPEN CURSOR1
  FETCH NEXT FROM CURSOR1
  INTO @MSGBODY
  WHILE @@FETCH_STATUS = 0
  BEGIN  
    EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SQL ALERTING PROFILE', -- Modify the profile name
    @recipients = 'leo.ismatov@sqlservice.se',-- Modify the email
    @body = @MSGBODY, 
    @subject = @SUBJECT ; 
 
  FETCH NEXT FROM CURSOR1
  INTO @MSGBODY
  END 
  CLOSE CURSOR1
  DEALLOCATE CURSOR1   
  DELETE FROM let_tst.DBO.SQL_ErrorLog   -- Modify the database name
 END
END

--scripten har ändrats för ett hämta ett spesifikt felmeddelande men flera kan skannas: 
--https://www.mssqltips.com/sqlservertip/2307/automate-monitoring-sql-server-error-logs-with-email-alerts/