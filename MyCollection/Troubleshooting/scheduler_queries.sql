/*
A runnable task is one that is in the runnable queues, waiting for CPU time. Other 
tasks on the scheduler that are in the current_tasks_count but not the runnable_
tasks_count are ones that are either sleeping or waiting for a resource (lock, latch, I/O, 
memory, and so on) 

Again, there is no threshold value that represents the boundary between a "good" and 
"bad" number of runnable tasks, but the lower the better. A high number of runnable 
tasks, like a high signal wait time, indicates that there is not enough CPU for the current 
query load.

*/ 

SELECT scheduler_id , 
 current_tasks_count , 
 runnable_tasks_count
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255