/* Queries running in the background */

/* User 1 (joy) - a lot of reads for over 30 minutes */
USE AdventureWorks2019;

SET NOCOUNT ON;

DECLARE @Count int;

WHILE 1=1
	SELECT @Count = COUNT(Title)
	FROM Person.Person
	WHERE Title = 'Mrs';


/* Script used before demo to create schema for temp table */
DECLARE 
 @Create_Destination_Table NVARCHAR(MAX);

EXEC sp_WhoIsActive @help = 1
 @Output_Column_List = '[session_id][login_name][start_time][sql_text]'
 , @Return_Schema = 1
 , @Schema = @Create_Destination_Table OUTPUT;

SELECT @Create_Destination_Table;


/* ***Script used in demo*** */
SET NOCOUNT ON;
 
DECLARE
 @Destination_Table VARCHAR(MAX) = '#WhoIsActive'
 , @Session_ID SMALLINT
 , @Login_Name NVARCHAR(128)
 , @SQL_Text XML
 , @Duration_Minutes INT
 , @Message NVARCHAR(MAX);


/* Create the temporary destination table */ 
DROP TABLE IF EXISTS #WhoIsActive;

CREATE TABLE #WhoIsActive(
 [session_id] smallint NOT NULL
 ,[login_name] nvarchar(128) NOT NULL
 ,[start_time] datetime NOT NULL
 ,[sql_text] xml NULL);
 
/* Collect activity */
EXEC sp_WhoIsActive
 @Output_Column_List = '[session_id][login_name][start_time][sql_text]'
 , @Destination_Table = @Destination_Table;

/* Check for any queries that meet the condition */
WHILE EXISTS (
 SELECT session_id
 FROM #WhoIsActive
 WHERE DATEADD(minute, -30, getdate()) > start_time) BEGIN 
 
  /* Get the session_id for the first query that meets the condition */
  SELECT @Session_ID = MIN(session_id)
  FROM #WhoIsActive
  WHERE DATEADD(minute, -30, getdate()) > start_time; 
 
 /* Get other information for the query */
  SELECT
   @Login_Name = login_name
   , @SQL_Text = sql_text
   , @Duration_Minutes = DATEDIFF(mi, start_time, GETDATE() )
  FROM #WhoIsActive
  WHERE session_id = @Session_ID;

  --SELECT @Login_Name, @SQL_Text, @Duration_Minutes

  /* Create email body message */
  SET @Message =
  'SessionID: ' + CONVERT(VARCHAR(10), @Session_ID)
  + CHAR(10)
  + 'Login Name: ' + @Login_Name 
  + CHAR(10)
  + 'Duration in Minutes: ' + CONVERT(VARCHAR(10), @Duration_Minutes) 
  + CHAR(10)
  + 'SQL Text: ' + CHAR(10)
  + CONVERT(NVARCHAR(MAX), ISNULL(@SQL_Text,'(unknown)'));
 
  /* Send email alert */
  EXECUTE msdb.dbo.sp_send_dbmail
   @profile_name = 'SQLMAIL'
   , @recipients = 'you@youremail.com'
   , @Subject = 'ALERT: Long Running Query'
   , @Body = @Message;

 /* Remove session_id record after sending email */
  DELETE 
  FROM #WhoIsActive
  WHERE session_id = @Session_ID ;

  END;
