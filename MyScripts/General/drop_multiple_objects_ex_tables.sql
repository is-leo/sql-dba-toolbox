SELECT NAME + ', ', TYPE
FROM SYS.OBJECTS
WHERE TYPE_DESC != 'SYSTEM_TABLE'
AND TYPE != 'IT'
AND TYPE != 'SQ'

--select user-defined tables  
select name + ', '
from sys.objects
where type = 'U'
AND create_date >= '2022-09-28';
GO

--to perform multiple drop copy result
DROP TABLE
-- copy result here


/*
Object type:

AF = Aggregate function (CLR)
C = CHECK constraint
D = DEFAULT (constraint or stand-alone)
F = FOREIGN KEY constraint
FN = SQL scalar function
FS = Assembly (CLR) scalar-function
FT = Assembly (CLR) table-valued function
IF = SQL inline table-valued function
IT = Internal table
P = SQL Stored Procedure
PC = Assembly (CLR) stored-procedure
PG = Plan guide
PK = PRIMARY KEY constraint
R = Rule (old-style, stand-alone)
RF = Replication-filter-procedure
S = System base table
SN = Synonym
SO = Sequence object
U = Table (user-defined)
V = View

Applies to: SQL Server 2012 (11.x) and later.

SQ = Service queue
TA = Assembly (CLR) DML trigger
TF = SQL table-valued-function
TR = SQL DML trigger
TT = Table type
UQ = UNIQUE constraint
X = Extended stored procedure

Applies to: SQL Server 2014 (12.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).

ST = STATS_TREE

Applies to: SQL Server 2016 (13.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).

ET = External Table

Applies to: SQL Server 2017 (14.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).

EC = Edge constraint*/