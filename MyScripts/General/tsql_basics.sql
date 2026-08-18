 
--Basic Info:
    Max number of dbs can be created  > 32 000
    Max db zise = 524 pb
    Max instances = 50  
    Max HA nodes up to 8
    MAX Memory OS = 24 tb
    Data stored in pages size of  8kb
    MAX Columns in the table  32 000
    Max data file size = 16 tb
    Max log file size = 2 tb



--SSMS shortcuts:
	ctrl + k, c or u         comment & uncomment command
    ctrl + shift - u         uppercase
    ctrl + shift - l         lowercase
    ctrl + L                 show estimated execution plan
    ctrl + M                 show actual execution plan
    ctrl + alt + p           trace query in profiler
    Shift + alt + s          show client statistics
    Ctrl + shift + q         query builder
    Ctrl + f5                parse a query before running (check syntax before actual execution)
    Ctrl + 1                 check current connections



--Quick status queries:
    select * from sys.dm_exec_requests
    sp_helpdb 'db_name'
    sp_help 'tbl_name'
    sp_helpfile
    sp_helpuser
    select * from sys.databases
    select * from sys.dm_os_sys_info
    select * from sys.dm_server_services




--To edit: C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\SqlWorkbenchProjectItems\Sql */