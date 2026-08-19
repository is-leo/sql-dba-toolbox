USE [AdventureWorks2014];
GO
    

/*
	Create a table
*/
CREATE TABLE [dbo].[MovieInfoHistory] (
	[ID] INT IDENTITY(1,1) PRIMARY KEY, 
	[MovieName] VARCHAR(800), 
	[ReleaseDate] SMALLDATETIME,
	[Rating] VARCHAR(5)
	);


/*
	Add some data
*/
INSERT INTO [dbo].[MovieInfoHistory] ( 
	[MovieName], [ReleaseDate], [Rating]
	)
VALUES
	('Caddyshack', '1980-07-25', 'R'),
	('Bill & Ted''s Excellent Adventure', '1989-02-17 00:00:00', 'PG'),
	('Apollo 13', '1995-05-30 00:00:00', 'PG'),
	('The Hunt for Red October', '1990-03-02 00:00:00', 'PG'),
	('A Few Good Men', '1994-12-11 00:00:00', 'R'),
	('Memento', '2000-10-11', 'R'),
	('Apollo 13', '1995-06-30 00:00:00', 'PG'),
	('The Truman Show', '1998-06-05 00:00:00', 'PG-13'),
	('All The President''s Men', '1976-04-09 00:00:00', 'R'),
	('The Right Stuff', '1983-10-21 00:00:00', 'PG-13');
GO


/*
	Try to add a constraint
*/
ALTER TABLE [dbo].[MovieInfoHistory] 
	ADD CONSTRAINT [CheckReleaseDate] CHECK ([ReleaseDate] < '2000-01-01 00:00:00');
GO


/*
	Try again to add a constraint
*/
ALTER TABLE [dbo].[MovieInfoHistory] WITH NOCHECK 
	ADD CONSTRAINT [CheckReleaseDate] CHECK ([ReleaseDate] < '2000-01-01 00:00:00');
GO


/*
	Add more data
*/
INSERT INTO [dbo].[MovieInfoHistory] ( 
	[MovieName], [ReleaseDate], [Rating]
	)
VALUES
	('The Natural', '1984-05-11 00:00:00', 'PG'),
	('The Hangover', '2009-06-05 00:00:00', 'R'),
	('IronMan', '2008-05-02 00:00:00', 'PG-13'),
	('The Incredibles', '2004-11-05 00:00:00', 'PG');
GO


/*
	Check specific constraint
*/
DBCC CHECKCONSTRAINTS([CheckReleaseDate]);
GO


/*
	Find the bad data
*/
SELECT * 
FROM [dbo].[MovieInfoHistory] 
WHERE [ReleaseDate] = '2000-10-11 00:00:00.000';
GO


/*
	Check constraints again, note the IO
*/
SET STATISTICS IO ON;
GO

DBCC CHECKCONSTRAINTS([CheckReleaseDate]);
GO

DBCC CHECKCONSTRAINTS('dbo.MovieInfoHistory')
GO

DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO


/*
	clean up
*/
DROP TABLE [dbo].[MovieInfoHistory];
GO