--generate create table for sp_whoisactive
declare @table_creation_script varchar(max);
exec sp_whoisactive @Schema = @table_creation_script output, @return_schema=1;
print @table_creation_script;

--generate table alternative 2
declare @table_creation_script varchar(max);
exec sp_whoisactive   @get_outer_command=1
, @output_column_list = 
'[dd%][session_id][sql_command][sql_text][login_name][host_name]
[database_name][wait_info][blocking_session_id][blocked_session_count][percent_complete]
[cpu][used_memory][reads][writes][program_name][collection_time]'
, @find_block_leaders=1
, @Schema = @table_creation_script output,  @return_schema=1;
print @table_creation_script;

--generated table
CREATE TABLE tbl_Whoisactive 
( [dd hh:mm:ss.mss] varchar(8000) NULL,
[session_id] smallint NOT NULL,
[sql_text] xml NULL,
[login_name] nvarchar(128) NOT NULL,
[wait_info] nvarchar(4000) NULL,
[CPU] varchar(30) NULL,
[tempdb_allocations] varchar(30) NULL,
[tempdb_current] varchar(30) NULL,
[blocking_session_id] smallint NULL,
[reads] varchar(30) NULL,
[writes] varchar(30) NULL,
[physical_reads] varchar(30) NULL,
[used_memory] varchar(30) NULL,
[status] varchar(30) NOT NULL,
[open_tran_count] varchar(30) NULL,
[percent_complete] varchar(30) NULL,
[host_name] nvarchar(128) NULL,
[database_name] nvarchar(128) NULL,
[program_name] nvarchar(128) NULL,
[start_time] datetime NOT NULL,
[login_time] datetime NULL,
[request_id] int NULL,
[collection_time] datetime NOT NULL);

--test blocking issue

USE DBA
drop table if exists dbo.t;
 
CREATE TABLE DBO.t (id int  primary key, a varchar(200));
insert into dbo.t (id, a) values (1,'hello'), (2, 'world');
-- start a transaction without committment
begin tran 
update dbo.t set a='hello 2' where id = 1;
-- rollback tran
--comit tran

--run in a new query session
delete from dbo.t

--run in a new query session
select * from dbo.t

--collect metadata to tbl_Whoisactive
exec sp_whoisactive 
@destination_table = 'dbo.tbl_whoisactive';

--query the collected metadata
select *
from dbo.tbl_whoisactive;

--collect metadata to alternative 2
exec sp_whoisactive   @get_outer_command=1
,  @output_column_list = '[dd%][session_id][sql_command][sql_text][login_name][host_name][database_name][wait_info][blocking_session_id][blocked_session_count][percent_complete][cpu][used_memory][reads][writes][program_name][collection_time]'
, @find_block_leaders=1
, @destination_table = 'dbo.tbl_whoisactive';
 
 --query alternative 2
select [dd hh:mm:ss.mss]
, session_id, sql_text
, database_name, wait_info
, blocking_session_id, blocked_session_count 
from dbo.tbl_whoisactive;


--analyze the collected metadata
--1. from the last collection, find sessions running longer than a specificed threshold
declare @duration_thresold varchar(15)='00 00:02:00' --2 min (example only, choose your own value)
select * from dbo.tbl_Whoisactive
where collection_time = (select max(collection_time) from dbo.tbl_Whoisactive)
and [dd hh:mm:ss.mss] > @duration_thresold
 
if (@@rowcount > 0)
exec msdb.dbo.sp_send_dbmail ....  -- please add your own parameters
go
 
--2. from the last collection, find sessions with cpu/reads/writes exceeing defined thresholds
declare @cpu_threshold int = 1000; --define your own
declare @reads_threshold int = 1000, @writes_threshold int = 1000;
select * from dbo.tbl_whoisactive
where collection_time = (select max(collection_time) from dbo.tbl_Whoisactive)
and (   cast(replace(cpu, ',','') as int) > @cpu_threshold
    or cast(replace(reads, ',','') as int) > @reads_threshold
    or cast(replace(writes, ',','') as int) > @writes_threshold
   );
 
if (@@rowcount > 0)
exec msdb.dbo.sp_send_dbmail .... -- please add your own parameters
go
 
--3. from the ast collection, find the total # of blocked sessions
-- if total > @threshold, email alerts
declare @blocked_session_sum int = 5 -- if blocked session is > 5, email alert
 
if (select sum(blocked_session_count)
from dbo.tbl_whoisactive
where collection_time = (select max(collection_time) from dbo.tbl_Whoisactive)
) > @blocked_session_sum
  exec msdb.dbo.sp_send_dbmail @recipients='dba@company.com' -- change to your own email
  , @subject='blocked sessions exceeding threshold' 
  , @body = 'please take a look'
go

sp_whoisactive @get_transaction_info @get_plans
