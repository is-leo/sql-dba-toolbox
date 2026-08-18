-- Good overview of AG health and status (Query 16) (AG Status)
SELECT ag.name AS [AG Name], ar.replica_server_name, ar.availability_mode_desc, adc.[database_name], 
       drs.is_local, drs.is_primary_replica, drs.synchronization_state_desc, drs.is_commit_participant, 
	   drs.synchronization_health_desc, drs.recovery_lsn, drs.truncation_lsn, drs.last_sent_lsn, 
	   drs.last_sent_time, drs.last_received_lsn, drs.last_received_time, drs.last_hardened_lsn, 
	   drs.last_hardened_time, drs.last_redone_lsn, drs.last_redone_time, drs.log_send_queue_size, 
	   drs.log_send_rate, drs.redo_queue_size, drs.redo_rate, drs.filestream_send_rate, 
	   drs.end_of_log_lsn, drs.last_commit_lsn, drs.last_commit_time, drs.database_state_desc 
FROM sys.dm_hadr_database_replica_states AS drs WITH (NOLOCK)
INNER JOIN sys.availability_databases_cluster AS adc WITH (NOLOCK)
ON drs.group_id = adc.group_id 
AND drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag WITH (NOLOCK)
ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar WITH (NOLOCK)
ON drs.group_id = ar.group_id 
AND drs.replica_id = ar.replica_id
ORDER BY ag.name, ar.replica_server_name, adc.[database_name] OPTION (RECOMPILE);

--alternative 2
SELECT 
    ar.replica_server_name, 
    adc.database_name, 
    ag.name AS ag_name, 
    case HDRS.is_primary_replica
    when 1 then 'Primary Replica'
    else 'Secondary Replica'
    end as Replica,
    HDRS.synchronization_state_desc, 
    HDRS.synchronization_health_desc, 
    HDRS.recovery_lsn, 
    HDRS.truncation_lsn, 
    HDRS.last_sent_lsn, 
    HDRS.last_sent_time, 
    HDRS.last_received_lsn, 
    HDRS.last_received_time, 
    HDRS.last_hardened_lsn, 
    HDRS.last_hardened_time, 
    HDRS.last_redone_lsn, 
    HDRS.last_redone_time, 
    HDRS.log_send_queue_size, 
    HDRS.log_send_rate, 
    HDRS.redo_queue_size, 
    HDRS.redo_rate, 
    HDRS.filestream_send_rate, 
    HDRS.end_of_log_lsn, 
    HDRS.last_commit_lsn, 
    HDRS.last_commit_time
FROM sys.dm_hadr_database_replica_states AS HDRS
INNER JOIN sys.availability_databases_cluster AS adc 
    ON HDRS.group_id = adc.group_id AND 
    HDRS.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
    ON ag.group_id = HDRS.group_id
INNER JOIN sys.availability_replicas AS ar 
    ON HDRS.group_id = ar.group_id AND 
    HDRS.replica_id = ar.replica_id



--monitoring
select replica_server_name,endpoint_url, availability_mode_desc,
failover_mode_desc,secondary_role_allow_connections_desc,create_date,
backup_priority,read_only_routing_url,seeding_mode_desc,read_write_routing_url 
from sys.availability_replicas

--about replicas
select * from sys.dm_hadr_availability_replica_cluster_nodes

select * from sys.dm_hadr_availability_replica_cluster_states


select db_name(database_id) as [Database],is_primary_replica,
synchronization_state_desc,database_state_desc,is_suspended,suspend_reason_desc,
recovery_lsn,truncation_lsn,last_sent_lsn,last_sent_time,last_received_lsn,last_received_time,last_hardened_lsn,log_send_queue_size,log_send_rate,redo_queue_size,
redo_rate,end_of_log_lsn,last_commit_lsn,last_commit_time,secondary_lag_seconds 
from sys.dm_hadr_database_replica_states

