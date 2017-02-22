select
      r.session_id,
      s.login_name,
      s.program_name,
      r.start_time,
      r.status,
      r.command,
      r.wait_type,
      r.wait_time,
      r.last_wait_type,
      r.logical_reads,
      (r.logical_reads * 8192) as 'KB Read',
      r.writes,
      (r.writes * 8192) as 'KB Written',
      t.[text]
from sys.dm_exec_requests r
      cross apply sys.dm_exec_sql_text(sql_handle) t
      inner join sys.dm_exec_sessions s
      on r.session_id = s.session_id
      where s.is_user_process = 1 and
      (r.wait_type like 'PAGEIOLATCH%' or r.last_wait_type like 
 'PAGEIOLATCH%') and
      r.session_id != @@SPID