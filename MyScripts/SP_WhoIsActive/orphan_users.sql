exec sp_change_users_login 'report' -- find orphaned users
exec sp_change_users_login 'auto_fix', 'cgc_owner' -- map
 
--För att mappa en login mot en databasanvändare som redan finns i databasen kör man följande kommando
use <db>
go
ALTER USER xxxxx WITH LOGIN =[domän\anv]