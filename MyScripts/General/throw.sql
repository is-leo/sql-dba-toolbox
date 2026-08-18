THROW 50000, 'Houston, we have a problem.', 1;


BEGIN TRY
    BEGIN TRANSACTION;
    SELECT 1 / 0; -- Do something really cool;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

--errros message ids and definitions
select *  from sys.messages
--where text like '%thread%'

--https://www.mssqltips.com/sqlservertip/7417/sql-server-throw-error-handling/?utm_source=dailynewsletter&utm_medium=email&utm_content=headline&utm_campaign=20221017