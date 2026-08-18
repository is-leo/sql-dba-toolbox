-- Displays the progress of several kinds of commands.  See BOL.
; with cte1 as
(
    select command                              as command,
           percent_complete   /  100.0          as percent_complete, 
           total_elapsed_time / 1000.0 / 60.0   as elapsed_minutes
      from sys.dm_exec_requests
     where percent_complete > 0.0
)
, cte2 as
(
    select command                                                               as command,
           cast(percent_complete * 100.0 as float(6))                            as percent_complete,
           cast(elapsed_minutes as int)                                          as elapsed_minutes,
           cast((elapsed_minutes / percent_complete) - elapsed_minutes as int)   as remaining_minutes
      from cte1
)
select command                                                           as 'Command',
       percent_complete                                                  as '% Complete', 
       elapsed_minutes                                                   as 'Elap Min',
       remaining_minutes                                                 as 'Left Mins',
       cast(dateadd(minute, remaining_minutes, getdate()) as nvarchar)   as 'ETA'
  from cte2
 order by percent_complete desc
