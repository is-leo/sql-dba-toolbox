USE HRDatabase
GO

CREATE OR ALTER PROCEDURE dbo.GetCompanies --CREATE PROCEDURE
	@ID int --input parameter
AS
BEGIN
	SELECT [ID]
            ,[CompanyName]
            ,[CompAddress]
            ,[CompContactNo]
            ,[CreateDate]
      FROM [dbo].[Companies]
	  WHERE ID = @ID
END;

--to execute
EXEC DBO.GetCompanies @ID = 3 -- give an argument for the parameter


--------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.InsCompany
      @CompanyName   varchar(80), -- input parameters
      @CompAddress   varchar(80),
      @CompContactNo varchar(20)
AS
BEGIN
      INSERT INTO [dbo].[Companies]
               ([CompanyName]
               ,[CompAddress]
               ,[CompContactNo]
               ,[CreateDate])
          VALUES
               (@CompanyName
               ,@CompAddress
               ,@CompContactNo
               ,getdate())
END;
 
--To Execute Stored Procedure you would run the following SQL code:
EXEC dbo.InsCompany
      @CompanyName   = 'Zulu-Yankee Company',
      @CompAddress   = '123 Some street, Somewhere Far away, Europe ext 10',
      @CompContactNo= '(999) 852 7401';
 
SELECT * FROM dbo.Companies;