/*
CXPACKET
• Often indicates nothing more than that certain queries are executing with parallel?ism; 
CXPACKET waits in the server are not an immediate sign of problems, although 
they may be the symptom of another problem, associated with one of the other high 
value wait types in the instance

SOS_SCHEDULER_YIELD
• This means that the computer is too busy and has too many 
tasks to handle. The tasks that are running are taking too long (exceeded their quantum 
and have to yield to other tasks)
to complete and are having to wait in line to continue. 
This is a sign that the computer's CPU is working too hard and needs more resources. 
It could mean that the computer needs more memory, a faster CPU, or that there are too 
many tasks running at the same time.

THREADPOOL
• A task had to wait to have a worker bound to it, in order to execute. This could 
be a sign of worker thread starvation, requiring an increase in the number of 
CPUs in the server, to handle a highly concurrent workload, or it can be a sign of 
blocking, resulting in a large number of parallel tasks consuming the worker threads 
for long periods.

LCK_*
•These wait types signify that blocking is occurring in the system and that sessions 
have had to wait to acquire a lock of a specific type, which was being held by anoth?er database session. 
This problem can be investigated further using the information 
in the sys.dm_db_index_operational_stats

PAGEIOLATCH_*, IO_COMPLETION, WRITELOG
•These waits are commonly associated with disk I/O bottlenecks, though the root 
cause of the problem may be, and commonly is, a poorly performing query that is 
consuming excessive amounts of memory in the server. PAGEIOLATCH_* waits are 
specifically associated with delays in being able to read or write data from the data?base files. 
WRITELOG waits are related to issues with writing to log files. These waits 
should be evaluated in conjunction with the virtual file statistics as well as Physical 
Disk performance counters, to determine if the problem is specific to a single data?base, file, or disk, or is instance wide.

PAGELATCH_* 
is an event in SQL Server which indicates that a thread is waiting on a latch for a buffer. 
A latch is a lightweight synchronization object used to protect access to a database page in memory. 
When a thread needs to access a page, it requests a latch on the page. If the latch is already held 
by another thread, the requesting thread will wait until the latch is released. This wait time is 
recorded as a PAGELATCH_* event in SQL Server's performance statistics.

PAGELATCH_* events can occur due to various reasons, including high concurrent access to a page, 
contention for resources, slow disk I/O, or insufficient memory. If PAGELATCH_* events are happening 
frequently and causing performance issues, it can indicate a problem with the database design, 
indexing strategy, or hardware configuration, and may require further investigation and optimization.

LATCH_*
•These waits are associated with lightweight short-term synchronization objects that 
are used to protect access to internal caches, but not the buffer cache. These waits 
can indicate a range of problems, depending on the latch type. Determining the 
specific latch class that has the most accumulated wait time associated with it can 
be found by querying the sys.dm_os_latch_stats DMV.

ASYNC_NETWORK_IO
•This wait is often incorrectly attributed to a network bottleneck. In fact, the most 
common cause of this wait is a client application that is performing row-by-row 
processing of the data being streamed from SQL Server as a result set (client accepts 
one row, processes, accepts next row, and so on). Correcting this wait type generally 
requires changing the client-side code so that it reads the result set as fast as pos?sible, and then performs processing