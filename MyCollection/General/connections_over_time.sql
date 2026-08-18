/* Om man vill kolla databasanslutningar över tid så kan man 
samla dem i en tabell genom att låta ett jobb köras regelbundet
som kollar anslutningar. */

--Steg1: skapa tabell för att lagra anslutningar
USE [DBA]
GO
CREATE TABLE [dbo].[DbConnections]
(
[CheckTime] [varchar](19) NULL,
[DbName] [nvarchar](128) NULL,
[HostName] [nvarchar](128) NULL,
[Client_IP] [nvarchar](128) NULL,
[Program] [nvarchar](128) NULL,
[LoginName] [nvarchar](128) NULL
) ON [PRIMARY]
GO

-- Steg 2: Schemalägg ett sql jobb med följande 
-- select. Kör det var 5:e eller var 10:e minut.

SET NOCOUNT ON
GO
INSERT INTO DBA.dbo.DbConnections -- se till att namn på db och tabell är rätt
(CheckTime, [DbName], HostName, [Client_IP], Program, LoginName)
select CONVERT(VARCHAR(19), GETDATE(),120) as [CheckTime],
DB_NAME(sp.dbid) as [DbName],
es.host_name as [HostName],
ec.client_net_address,
es.[program_name] as program,
es.login_name as [LoginName]
from sys.dm_exec_sessions es
INNER JOIN
sys.sysprocesses sp
ON
es.session_id = sp.spid
INNER JOIN
sys.dm_exec_connections ec
ON 
es.session_id = ec.session_id
where
es.session_id > 50
and
sp.dbid > 4
order by DB_NAME(sp.dbid), es.host_name, es.login_name
go


