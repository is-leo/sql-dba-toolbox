-- Demo script for Example Output demo.

-- Run the Setup-ExampleOutput.sql script first.

-- Clean database
DBCC CHECKDB (N'Company');
GO

DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO

-- Corrupt database
DBCC CHECKDB (N'Company2') WITH NO_INFOMSGS;
GO

-- Look in the errorlog and the event log too

