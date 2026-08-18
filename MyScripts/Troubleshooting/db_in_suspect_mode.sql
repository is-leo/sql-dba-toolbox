/*När en databas hamnar i "suspect mode" så kan det bero på diskkrasch eller korrupt data. 
Man kan inte göra restore för databasen är inte tillgänglig. */

--Av samma anledning kan man heller inte göra en DBCC CHECKDB enligt nedan för att få fram orsaken.

DBCC CHECKDB ('<dbnamn>') WITH NO_INFOMSGS, ALL_ERRORMSGS;
 

--Då gör man på följande sätt i Management Studio Query window:
--Återställ status för db.

EXEC sp_resetstatus '<dbnamn>';
 

--Sätt db i emergency-läge
ALTER DATABASE <dbnamn> SET EMERGENCY;
 

--Kör en ny check på db
DBCC checkdb('<dbnamn>');
 

--Sätt db i single-user mode och rulla tillbaka transaktioner.
ALTER DATABASE <dbnamn> SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 

--Reparera db och tillåt att förlora data
DBCC CheckDB ('<dbnamn>', REPAIR_ALLOW_DATA_LOSS);
 

--Ställ tillbaka db till fleranvändarläge
ALTER DATABASE <dbnamn> SET MULTI_USER;
 
/*
Nu är databasen fixad. 
Men för att inte riskera att databasen har kvar någon korrupt del bör man återställa senaste backupen.*/