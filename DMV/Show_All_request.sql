SELECT
	DER.session_id				AS [Session ID]
	,DER.status					AS [Status]
	,DER.start_time				AS [Session start time]
	,DER.wait_time / 1000		AS [Wait time (s)]
	,DER.wait_type				AS [Wait type]
	,DES.host_name
	,(SELECT text FROM sys.fn_get_sql(DER.sql_handle)) AS SQLText
	,DES.cpu_time
	,DER.last_wait_type
FROM sys.dm_exec_requests AS DER
LEFT JOIN sys.dm_exec_sessions AS DES		ON DER.session_id = DES.session_id
--WHERE DER.status = 'running'
ORDER BY cpu_time DESC
