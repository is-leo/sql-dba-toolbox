
--This biggest difference is that a CTE can only be used in the current query scope whereas a 
--temporary table or table variable can exist for the entire duration of the session 

--example of cte
WITH cte (BusinessEntityID, FirstName, SureName) AS
(SELECT BusinessEntityID, FirstName, Lastname
 FROM Person.Person
 WHERE EmailPromotion = 2)
SELECT EmailAddress, cte.FirstName, cte.SureName FROM Person.EmailAddress e
INNER JOIN cte ON cte.BusinessEntityID = e.BusinessEntityID


-- Temporary table
CREATE TABLE #temptable (customerid [int] NOT NULL PRIMARY KEY, lastorderdate [datetime] NULL);
INSERT INTO #temptable
SELECT customerid, max(orderdate) as lastorderdate 
FROM sales.SalesOrderHeader
GROUP BY customerid;

SELECT * 
FROM sales.salesorderheader soh
INNER JOIN #temptable t ON soh.customerid=t.customerid AND soh.orderdate=t.lastorderdate

DROP TABLE #temptable
GO


-- Table variable
DECLARE @tablevariable TABLE (customerid [int] NOT NULL PRIMARY KEY, lastorderdate [datetime] NULL);

INSERT INTO @tablevariable
SELECT customerid, max(orderdate) as lastorderdate 
FROM sales.SalesOrderHeader
GROUP BY customerid;

SELECT * 
FROM sales.salesorderheader soh
INNER JOIN @tablevariable t ON soh.customerid=t.customerid AND soh.orderdate=t.lastorderdate
GO