SELECT
	DER.session_id				AS [Blocked session ID]
	,DER.status					AS [Blocked status]
	,DER.start_time				AS [Blocked session start time]
	,DER.wait_time / 1000		AS [Blocked time (s)]
	,DER.wait_type				AS [Blocked wait type]
	,DES.host_name				AS [Blocked hostname]
	,DES.login_name				AS [Blocked login name]
	,MRSH2.text					AS [Bloced SQL text]
	,'-------->'				AS [-------->]
	,DER.blocking_session_id	AS [Blocking session ID]
	,DEC.connect_time			AS [Blocking session start time]
	,DEC.last_read				AS [Blocking last read]
	,DEC.last_write				AS [Blocking last write]
	,DES2.host_name				AS [Blocked hostname]
	,DES2.login_name				AS [Blocked login name]
	,MRSH.text					AS [Blocking SQL text]
	,DER2.wait_type				AS [Blocking WAIT type]
	,DER2.wait_time				AS [Blocking WAIT time]

FROM sys.dm_exec_requests AS DER
LEFT JOIN sys.dm_exec_connections AS DEC	ON DER.blocking_session_id = DEC.session_id
LEFT JOIN sys.dm_exec_sessions AS DES		ON DER.session_id = DES.session_id
LEFT JOIN sys.dm_exec_sessions AS DES2		ON DER.blocking_session_id = DES2.session_id
CROSS APPLY sys.dm_exec_sql_text(DEC.most_recent_sql_handle) AS MRSH
CROSS APPLY sys.dm_exec_sql_text(DER.sql_handle) AS MRSH2	
LEFT JOIN sys.dm_exec_requests AS DER2		ON DER.blocking_session_id = DER2.session_id
WHERE DER.blocking_session_id > 0
