--Transaktionsloggen består av sk virtual log files (VLF). Varje gång transaktionslogen utökas skapas ett antal VLF.
--För att ta reda på hur många VLF som en databaslog har kan man köra följande sats. Den visar db och antal VLF samt autogrowth storlek.

Create Table #stage(
  RecoveryUnitID int    -- Denna finns ej i SQL 2008 i DBCC LogInfo
  , FileID int
  , FileSize bigint
  , StartOffset bigint
  , FSeqNo bigint
  , [Status] bigint
  , Parity bigint
  , CreateLSN numeric(38)
  );
 
 Create Table #results(
  Database_Name sysname
  , VLF_count int
  , log_auto_growth_mb int
  );
 
 Exec sp_msforeachdb N'Use [?];
  Insert Into #stage
  Exec sp_executeSQL N''DBCC LogInfo(?)''; 
 
 Insert Into #results
  Select DB_Name(), Count(*), convert(int, max(db.growth / 128))
  From #stage s, sys.database_files db
  where type = 1; 
 
 Truncate Table #stage;'
 
 Select *
  From #results
  --where VLF_count > 400
  Order By VLF_count Desc;
 
 Drop Table #stage;
 Drop Table #results;