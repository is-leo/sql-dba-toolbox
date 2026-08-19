-- Demo script for Corruption Examples demo

-- Run the Setup-CorruptionExamples.sql script first

DBCC CHECKDB (N'Company') WITH NO_INFOMSGS;
GO

DBCC CHECKDB (N'Company2') WITH NO_INFOMSGS;
GO

DBCC CHECKDB (N'Company3') WITH NO_INFOMSGS;
GO
