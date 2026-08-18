--DATEADD(<Unit of time>, <Units>, <Input Date>)
DECLARE @Date as varchar(15) = '9/1/2011'
PRINT @Date;

-- Syntax to add 5 days to September 1, 2011 (input date) the function would be
SELECT DATEADD(DAY, 5, @Date)

-- Syntax to subtract 5 months from September 1, 2011 (input date) the function would be
SELECT DATEADD(MONTH, -5, @Date)


--DATEDIFF

DECLARE @StartTime DATETIME = '2011-09-23 15:00:00'
       ,@EndTime   DATETIME = '2011-09-23 17:54:02'
       
SELECT CONVERT(VARCHAR(8), DATEADD(SECOND, DATEDIFF(SECOND,@StartTime, @EndTime),0), 108) as ElapsedTime
-- the output would be 02:54:02
-- 108 represetns dateformat HH:MM: SS