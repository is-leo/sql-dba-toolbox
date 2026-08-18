USE [Credit];
go

CREATE INDEX [Test1] ON [dbo].[Member] ([LastName]) 
INCLUDE ([FirstName], [MiddleInitial]); 
go

CREATE INDEX [Test2] ON [dbo].[Member] ([LastName]) 
INCLUDE ([MiddleInitial], [FirstName]); 
go

CREATE INDEX [Test3] ON [dbo].[Member] ([LastName], [member_no]) 
INCLUDE ([MiddleInitial], [FirstName]); 
go

CREATE INDEX [Test4] ON [dbo].[Member] ([LastName]) 
INCLUDE ([MiddleInitial], [FirstName], [member_no]); 
go

EXEC [sp_sqlskills_helpindex] '[dbo].[member]';
go

EXEC sp_sqlskills_helpindex member
go

EXEC [sp_SQLskills_finddupes] '[dbo].[member]';
go