--Corrupt a database as test
CREATE DATABASE [50Ways];
GO
ALTER DATABASE [50Ways] SET PAGE_VERIFY CHECKSUM;
GO
ALTER DATABASE [50Ways] SET RECOVERY FULL; 
GO  

USE [50Ways];
GO
CREATE TABLE [dbo].[ToLeaveYourLover]([Way] VARCHAR(50));
GO
INSERT INTO [dbo].[ToLeaveYourLover]([Way])
VALUES ('Slip out the back, Jack'),
('Make a new plan, Stan'),
('Hop on the bus, Gus'),
('Drop off the key, Lee')

GO
SELECT * FROM [50Ways]..[ToLeaveYourLover]; /* Vi har data */
GO
BACKUP DATABASE [50Ways] TO DISK='50Ways_Full_1.bak'; 
GO
BACKUP LOG [50Ways] TO DISK='50Ways_Log_1.bak'; 
GO
USE master;
GO
ALTER DATABASE [50Ways] SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO

--editera datafilen med hexeditor, byt ut t.ex Stan mot Flan, använd XVI32

-- Starta upp databasen igen
USE master;
GO
ALTER DATABASE [50Ways] SET ONLINE;
GO
SELECT * FROM [50Ways]..[ToLeaveYourLover];
GO

DBCC CHECKDB

-- consistency based error 824, 24, 2 när man läser, OUCH!! Men precis som det ska vara.

-- Kan man inserta fler rader?    Fungerar ibland, ibland inte, beroende på hur datasidorna blev skapade
USE [50Ways];
GO
INSERT INTO [dbo].[ToLeaveYourLover]([Way])
VALUES ('She said it grieves me so'),
('To see you in such pain'),
('I wish there was something I could do'),
('To make you smile again')
GO

-- Funkar backup? Jupp! Märkligt nog gör det.
BACKUP DATABASE [50Ways] TO DISK='50Ways_Full_2.bak';
GO
BACKUP LOG [50Ways] TO DISK='50Ways_Log_2.bak';
GO

-- Kan vi laga databasen?
alter database [50Ways] set single_user 
dbcc checkdb('50Ways', repair_allow_data_loss)

--Ahaa, den lagades, vad hände med datat?
SELECT * FROM [50Ways]..[ToLeaveYourLover];
GO

-- Borta! Troligen är hela tabellen nu tom, och det är ju tråkigt. 
-- Men repair allow data loss skämtar inte, den gör just det; allow data loss

