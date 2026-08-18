/*
A database snapshot in SQL Server works by creating a point-in-time, 
read-only copy of a database. However, it doesn't duplicate the entire database. 
Instead, it uses a technique called copy-on-write:

Initial Snapshot: When the snapshot is created, no data is copied immediately. 
The snapshot references the original database's data pages.

Copy-on-Write Mechanism: As changes are made to the original database, the original,
unchanged data pages (before modification) are copied to the snapshot. 
This ensures the snapshot reflects the state of the database when the snapshot was taken.

Read-Only: The snapshot remains static and read-only, 
allowing users to query the data as it existed at the snapshot's creation time.

The snapshot continues to grow as more changes occur in the original database, 
only storing pre-modified pages. This makes snapshots space-efficient compared 
to full database copies.
*/

CREATE DATABASE DBA_snapshot -- snapshot db name
ON(NAME = DBA /*logical file name of source db*/, 
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\DBA_snapshot.mdf')
AS SNAPSHOT OF DBA --source db