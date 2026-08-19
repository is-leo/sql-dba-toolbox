
--  Create endpoints on all replicas using windows authentication

CREATE ENDPOINT [Hadr_endpoint]
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (
        ROLE = ALL
        );

--  Grant connect to the service account running partner instances


GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [abacos\svc_abacossql];


-- Sample create availability group statement for default settings
/*
-- https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/create-an-availability-group-transact-sql?view=sql-server-2017
*/


CREATE AVAILABILITY GROUP MyAG   
   FOR   
      DATABASE MyDB1, MyDB2   
   REPLICA ON   
      'COMPUTER01\AgHostInstance' WITH   
         (  
         ENDPOINT_URL = 'TCP://COMPUTER01.Adventure-Works.com:7022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL  
         ),  
      'COMPUTER02' WITH   
         (  
         ENDPOINT_URL = 'TCP://COMPUTER02.Adventure-Works.com:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL  
         );   
GO 

-- run on secondary instances to join AG

ALTER AVAILABILITY GROUP MyAG JOIN;  
GO  

-- Alter databases to come into the group on secondaries

ALTER DATABASE MyDB1 SET HADR AVAILABILITY GROUP = [MyAG];
ALTER DATABASE MyDB2 SET HADR AVAILABILITY GROUP = [MyAG];