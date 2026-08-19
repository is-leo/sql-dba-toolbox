-- Demo script for SQL Agent Job History demo.

-- This setup script uses the undocumented DBCC WRITEPAGE
-- command to cause corruption and the undocumented DBCC IND
-- command to find pages to corrupt. These commands are explained
-- in detail in Module 3 of the course SQL Server: Advanced
-- Corruption Recovery Techniques.

USE [Company];
GO

CREATE TABLE [RandomData] (
	[c1]  INT IDENTITY,
	[c2]  CHAR (8000) DEFAULT 'a');
GO

INSERT INTO [RandomData] DEFAULT VALUES;
GO 10

-- List the pages in the table
DBCC IND (N'Company', N'RandomData', -1);
GO

-- Pick a page to corrupt
ALTER DATABASE [Company] SET SINGLE_USER;
GO
DBCC WRITEPAGE (N'Company', X, X, 0, 2, 0x0000, 1);
GO
ALTER DATABASE [Company] SET MULTI_USER;
GO