CREATE OR ALTER FUNCTION dbo.udfGetSum(@NumA int, @NumB int)
RETURNS int
AS 
BEGIN 
      DECLARE @SumOfNumbers int
      SELECT @SumOfNumbers = @NumA + @NumB
      RETURN @SumOfNumbers
END;
 
-- Check the function
SELECT dbo.udfGetSum(5,4);

----------------------------------------------------

CREATE or ALTER FUNCTION dbo.udfGetEmployees(@CompID int) 
RETURNS TABLE 
AS 
RETURN 
      SELECT *
      FROM dbo.Companies
      WHERE ID = @CompID;
 
-- Check the function
SELECT * FROM dbo.udfGetEmployees(1);