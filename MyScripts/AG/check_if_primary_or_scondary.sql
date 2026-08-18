IF 
 (select role_desc from sys.dm_hadr_availability_replica_states
where group_id = (select m.ag_id from sys.dm_hadr_name_id_map m where m.ag_name = N'AG-VDL-T' )
AND is_local = 1
) = N'PRIMARY'
SELECT 'PRIMARY, please execute job'
ELSE
RAISERROR ('SECONDARY, so no execute please', 16,1)


--alternative 2 

IF sys.fn_hadr_is_primary_replica('DatabaseName') <> 1
THROW 50000, 'This is not the primary replica.', 1;

/*
Next, on the Advanced tab, we need to change 
the On Failure Action to “Quit the job reporting success”, then click OK. */

IF sys.fn_hadr_is_primary_replica('WSS_Content') <> 1
BEGIN
    RAISERROR('This is not the primary replica. Current server: %s', 16, 1, @@SERVERNAME);
    RETURN;
END;
