

CREATE PROC usp_GetFailedLoginsListFromLastWeek
AS
BEGIN
   SET NOCOUNT ON

   DECLARE @ErrorLogCount INT 
   DECLARE @LastLogDate DATETIME

   DECLARE @ErrorLogInfo TABLE (
       LogDate DATETIME
      ,ProcessInfo NVARCHAR (50)
      ,[Text] NVARCHAR (MAX)
      )
   
   DECLARE @EnumErrorLogs TABLE (
       [Archive#] INT
      ,[Date] DATETIME
      ,LogFileSizeMB INT
      )

   INSERT INTO @EnumErrorLogs
   EXEC sp_enumerrorlogs

   SELECT @ErrorLogCount = MIN([Archive#]), @LastLogDate = MAX([Date])
   FROM @EnumErrorLogs

   WHILE @ErrorLogCount IS NOT NULL
   BEGIN

      INSERT INTO @ErrorLogInfo
      EXEC sp_readerrorlog @ErrorLogCount

      SELECT @ErrorLogCount = MIN([Archive#]), @LastLogDate = MAX([Date])
      FROM @EnumErrorLogs
      WHERE [Archive#] > @ErrorLogCount
      AND @LastLogDate > getdate() - 30
  
   END

   -- List all last week failed logins count of attempts and the Login failure message
   SELECT COUNT (TEXT) AS NumberOfAttempts, TEXT AS Details, 
   MIN(LogDate) as FirstFailure, MAX(LogDate) as LastFailure
   FROM @ErrorLogInfo
   WHERE ProcessInfo = 'Logon'
      AND TEXT LIKE '%fail%'
      AND LogDate > getdate() - 7
   GROUP BY TEXT
   ORDER BY NumberOfAttempts DESC

   SET NOCOUNT OFF
END              



--exec usp_GetFailedLoginsListFromLastWeek

--drop proc usp_GetFailedLoginsListFromLastWeek

  