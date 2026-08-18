-- Demo script for Running Repair demo

-- Run the Setup-RunningRepair.sql script first

-- Company
DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO

-- Take the database into SINGLE_USER mode
ALTER DATABASE [Company] SET SINGLE_USER;
GO

-- Run repair
DBCC CHECKDB (N'Company', REPAIR_ALLOW_DATA_LOSS)
WITH NO_INFOMSGS;
GO

-- Check all corruptions were fixed
DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO

-- Make the database MULTI_USER again
ALTER DATABASE [Company] SET MULTI_USER;
GO

-- Company2
DBCC CHECKDB (N'Company2') WITH NO_INFOMSGS;
GO

-- Take the database into SINGLE_USER mode
ALTER DATABASE [Company2] SET SINGLE_USER;
GO

-- Run repair
DBCC CHECKDB (N'Company2', REPAIR_ALLOW_DATA_LOSS)
WITH NO_INFOMSGS;
GO

-- Check all corruptions were fixed
DBCC CHECKDB (N'Company2') WITH NO_INFOMSGS;
GO

-- Make the database MULTI_USER again
ALTER DATABASE [Company2] SET MULTI_USER;
GO

-- Company3
DBCC CHECKDB (N'Company3') WITH NO_INFOMSGS;
GO

-- Take the database into SINGLE_USER mode
ALTER DATABASE [Company3] SET SINGLE_USER;
GO

-- Run repair
DBCC CHECKDB (N'Company3', REPAIR_ALLOW_DATA_LOSS)
WITH NO_INFOMSGS;
GO

-- Check all corruptions were fixed
DBCC CHECKDB (N'Company3') WITH NO_INFOMSGS;
GO

-- Did we lose anything?
SELECT COUNT (*) FROM [Company3].[dbo].[RandomData];

-- Make the database MULTI_USER again
ALTER DATABASE [Company3] SET MULTI_USER;
GO