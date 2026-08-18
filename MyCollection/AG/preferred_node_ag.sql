 -- ALTERNATIVE 1
-- CAN BE EXUCTED IN A JOB OR AT STARTUP

--This SP failovers an AG to its preferred node
CREATE PROCEDURE dbo.PreferredNodeforAG
AS
BEGIN

 

--Delay the Execution to allow the SQL Server and AG to fully recover after a reboot
WAITFOR DELAY '00:05:00';

 

-- Check if the preferred node is online and the AG is healthy
IF EXISTS (
SELECT ag.name AS [AG Name], ar.replica_server_name, ar.availability_mode_desc, adc.[database_name], 
       drs.is_local, drs.is_primary_replica, drs.synchronization_state_desc, drs.is_commit_participant, 
       drs.synchronization_health_desc, drs.database_state_desc 
FROM sys.dm_hadr_database_replica_states AS drs WITH (NOLOCK)
INNER JOIN sys.availability_databases_cluster AS adc WITH (NOLOCK)
ON drs.group_id = adc.group_id 
AND drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag WITH (NOLOCK)
ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar WITH (NOLOCK)
ON drs.group_id = ar.group_id 
AND drs.replica_id = ar.replica_id
WHERE ar.replica_server_name = 'SQLNODE2' -- Select preferred node for the AG
AND drs.is_local = 1 -- Verifies that SQLNODE2 is the local node
AND ar.availability_mode_desc = 'SYNCHRONOUS_COMMIT' -- The primary replica waits to commit a given transaction until the secondary replica has written the transaction to disk.
AND drs.is_primary_replica = 0 -- Verifies that SQLNODE2 is not the primary node for AG2
AND drs.synchronization_state_desc = 'SYNCHRONIZED' -- Verifies that data is in sync
AND drs.synchronization_health_desc = 'HEALTHY' -- Status for synchronization
AND drs.database_state_desc = 'ONLINE' -- Verifies that AG dbs are online
AND ag.name = 'AG2' -- Select an AG that you want SQLNODE2 to be primary of
--ORDER BY ag.name, ar.replica_server_name, adc.[database_name] OPTION (RECOMPILE)
)

 

--FAILOVER if the above SELECT statement exists
BEGIN
    ALTER AVAILABILITY GROUP [AG2] FAILOVER;
END
    ELSE
BEGIN
    PRINT 'Please check whether SQLNODE2 is available and healthy, or if it has already become the primary.';
END

 

END;
GO

 -- ALTERNATIVE 2

/*
--executes the SP each time SQL Server restarted
sp_procoption 'dbo.PreferredNodeforAG', 'startup', 'OFF';
GO

--Check if SP has run or not

SELECT o.name, 
       ps.last_execution_time, *
FROM   sys.dm_exec_procedure_stats ps 
INNER JOIN 
sys.objects o 
ON ps.object_id = o.object_id 


select * from  sys.procedures
where name = 'PreferredNodeforAG'
*/


 -- ALTERNATIVE 3

/*
This stored procedure (SP) failovers the Availability Group (AG) to its preferred node (f.ex. AG1 to SQLNODE1 ). 
When executed, it checks if certain conditions for a successful failover are met such as: if current node is local, if it's already the primary node, sync status & dbs status.
Depending on these conditions it performs one of the 3 actions: 
1. Failovers 
2. Reports that node is already the primary 
3. Warns if conditions for a successful failover are not met'
*/

CREATE OR ALTER PROCEDURE dbo.PreferredNodeforAG
AS
BEGIN
	--Declaring the variables
    DECLARE @Result int = 0; 
    DECLARE @StartTime Datetime = GetDate();
	DECLARE @NODE VARCHAR (100) = 'SQLNODE1' --> Please select a preferred node for the AG.
	DECLARE @AG VARCHAR (100) = 'AG1' --> Please select an AG for which you want the preferred node to be the primary.
	DECLARE @SqlStatement NVARCHAR(1000);

    WHILE DATEDIFF(SECOND, @StartTime, GETDATE()) < 120
    BEGIN 
        SELECT @Result = COUNT(*)
        FROM sys.dm_hadr_database_replica_states AS drs WITH (NOLOCK)
        INNER JOIN sys.availability_databases_cluster AS adc WITH (NOLOCK)
            ON drs.group_id = adc.group_id 
            AND drs.group_database_id = adc.group_database_id
        INNER JOIN sys.availability_groups AS ag WITH (NOLOCK)
            ON ag.group_id = drs.group_id
        INNER JOIN sys.availability_replicas AS ar WITH (NOLOCK)
            ON drs.group_id = ar.group_id 
            AND drs.replica_id = ar.replica_id
		--Conditions for successful failover
        WHERE ar.replica_server_name = @NODE 
            AND drs.is_local = 1 -- Verifies if the current node is local
            AND ar.availability_mode_desc = 'SYNCHRONOUS_COMMIT' -- The primary replica waits to commit a given transaction until the secondary replica has written the transaction to disk.
            AND drs.is_primary_replica = 0 -- Verifies that current node is not already the primary for the AG
            AND drs.synchronization_state_desc = 'SYNCHRONIZED' -- Verifies that data is in sync
            AND drs.synchronization_health_desc = 'HEALTHY' -- Status for synchronization
            AND drs.database_state_desc = 'ONLINE' -- Verifies that AG dbs are online
            AND ag.name = @AG; 

        IF @Result > 0 --Exit the loop if @Result > 0 & the conditions are met
            BREAK;

        WAITFOR DELAY '00:00:10'; --Wait 10 seconds before trying again
    END

    --FAILOVER if the above-mentioned conditions are met & @Result > 0
	IF @Result > 0
    BEGIN
		SET @SqlStatement = 'ALTER AVAILABILITY GROUP ' + QUOTENAME(@AG) + ' FAILOVER;';
		EXEC sp_executesql @SqlStatement;
        PRINT 'AG1 has successfully failed over'
    END
	--If @Result is 0, check whether @Node is already the primary or if the conditions for a successful failover are met.
    ELSE
    BEGIN
        IF EXISTS (
            SELECT *
            FROM sys.dm_hadr_database_replica_states AS drs WITH (NOLOCK)
            INNER JOIN sys.availability_groups AS ag WITH (NOLOCK)
                ON ag.group_id = drs.group_id
            INNER JOIN sys.availability_replicas AS ar WITH (NOLOCK)
                ON drs.group_id = ar.group_id 
                AND drs.replica_id = ar.replica_id
            WHERE ar.replica_server_name = @NODE 
                AND drs.is_local = 1 
                AND drs.is_primary_replica = 1 -- Check whether @Node is already the primary 
                AND ag.name = @AG 
        )
        BEGIN
            RAISERROR('AG has not failed over, the current node is already the primary', 10, 1);

        END
        ELSE
        BEGIN
            RAISERROR('Warning: Please check whether conditions for a successful failover are met for AG', 16, 1) WITH NOWAIT;
        END
    END
END;



