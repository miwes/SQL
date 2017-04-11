SELECT
	DER.session_id				AS [Blocked session ID]
	,DER.status					AS [Blocked status]
	,DER.start_time				AS [Blocked session start time]
	,DER.wait_time / 1000		AS [Blocked time (s)]
	,DER.wait_type				AS [Blocked wait type]
	,DES.host_name
	,(SELECT text FROM sys.fn_get_sql(DER.sql_handle)) AS SQLText
	,DES.cpu_time
FROM sys.dm_exec_requests AS DER
LEFT JOIN sys.dm_exec_sessions AS DES		ON DER.session_id = DES.session_id
WHERE DER.status = 'running'
ORDER BY cpu_time DESC
--WHERE DES.host_name LIKE 'WINPCAPA%'