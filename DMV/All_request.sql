SELECT
	DER.session_id				AS [Session ID]
	,DER.status					AS [Status]
	,DER.start_time				AS [Session start time]
	,DER.wait_time / 1000		AS [Blocked time (s)]
	,DER.wait_type				AS [Wait type]
	,DES.login_time				AS [Login time]
	,DES.login_name				AS [Login name]
	,DES.host_name				AS [Host name]
	,DES.program_name			AS [Program name]
--	,*
FROM sys.dm_exec_requests AS DER
LEFT JOIN sys.dm_exec_sessions AS DES		ON DER.session_id = DES.session_id
WHERE
	DES.is_user_process = 1
