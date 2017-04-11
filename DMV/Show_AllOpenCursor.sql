SELECT 
	DEC.dormant_duration / 10000 AS [Time s]
	,(SELECT text FROM sys.fn_get_sql(DEC.SQL_Handle)) AS SQLText
	,GETDATE() - DER.start_time
	,DEC.session_id
FROM sys.dm_exec_cursors (0) AS DEC
JOIN sys.dm_exec_sessions AS DES	ON DES.session_id = DEC.session_id
JOIN sys.dm_exec_requests AS DER	ON DER.session_id = DEC.session_id
ORDER BY DEC.dormant_duration DESC