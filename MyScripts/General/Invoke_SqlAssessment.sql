/*Build a Solution to Collect Assessment Results
With the flexibility of Invoke-SqlAssesment, we can build an assessment framework
for various SQL Server objects, including instances, databases, or high availability groups.
The following script is to scan a group of SQL Server instances
(via a parameter input) and save the result in a centralized table.
*/

-- we first create a table in a centralized server / database-- I use my local sql instance / database as a central repository-- i.e. [localhost\sql2019].[dbatools]USE [DBAtools]GOdrop table if exists dbo.SQLInstanceAssessment;go-- central repository tableCREATE TABLE [dbo].[SQLInstanceAssessment](   [CheckId] [varchar](60) NULL,   [Severity] [varchar](12) NULL,   [Server] [varchar](60) NULL,   [Message] [varchar](2048) NULL,   [LogDate] [datetime] NULL default getdate(),   [BatchNum] [int] NULL,   [id] [int] IDENTITY(1,1) NOT NULL primary key,)

--After the table is created, we can run the following PowerShell script 
--to get the assessment values into this table.

# doing sql server assessment and save the result to a central repository# min severity is warning (i.e. no info level assessment needed)# I especially filter out check item 'DeprFeaturesInJobs' due to too many items reported backimport-module sqlserver;$svr_list = 'Server01', 'Server02'; # replace it with your own server list$central_svr = '.\sql2019'; # replace it with your own central server$central_db = 'dbatools'; # replace it with your own central db on the central serverget-sqlinstance -ServerInstance $svr_list | Invoke-SqlAssessment -FlattenOutput -MinSeverity warning | where checkid -ne 'DeprFeaturesInJobs' |  select checkid,  severity, @{l='Server'; e={[regex]::match($_.targetpath, "\'(.*)\'").groups[1].value}}, message |Write-SqlTableData -ServerInstance $central_svr -DatabaseName $central_db -SchemaName dbo -TableName SQLInstanceAssessment; $qry = 'update dbo.SQLInstanceAssessment set batchnum = (select max(isnull(batchnum, 0)) +1 from dbo.SQLInstanceAssessment) where batchnum is null';Invoke-Sqlcmd -ServerInstance $central_svr -Database $central_db -Query $qry; 
All assessment results for Server01 and Server02 are stored in a central table, as shown below. You can check multiple SQL Server instances simultaneously if you put all instance names into $svr_list variable.


From <https://www.mssqltips.com/sqlservertip/7435/check-sql-server-best-practice-settings-invoke-sqlassessment/?utm_source=dailynewsletter&utm_medium=email&utm_content=headline&utm_campaign=20221025> 


------------------------------------------

Install-Module -Name SqlServer -RequiredVersion 22.2.0

Get-SqlInstance -ServerInstance DESKTOP-GG4LGNS | Invoke-SqlAssessment

###### What items can be assessed or checked on the instance level:
Get-SqlInstance -ServerInstance DESKTOP-GG4LGNS | Get-SqlAssessmentItem | sort-object -property ID

Get-SqlInstance -ServerInstance DESKTOP-GG4LGNS | Invoke-SqlAssessment -Check WeakPassword ;

###### What items can be assessed or checked on the database level:
Get-sqldatabase -ServerInstance DESKTOP-GG4LGNS | get-sqlassessmentitem | Sort-Object ID

#backup check
Get-sqldatabase -server DESKTOP-GG4LGNS -database AdventureWorks2019 | invoke-sqlassessment -check fullbackup

#Full check:
Get-sqldatabase -server DESKTOP-GG4LGNS -database AdventureWorks2019 | invoke-sqlassessment -flat