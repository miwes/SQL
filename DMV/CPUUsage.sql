SELECT
    cpu_time, total_elapsed_time,
    session_Id, [DatabaseName] = DB_NAME(sp.dbid), Hostname, [User] = nt_username,
    [Status] = ER.status, [WaitType] = wait_type,
    [QueryText] = SUBSTRING (QT.text, ER.statement_start_offset/2, (CASE WHEN ER.statement_end_offset = -1
       THEN LEN(CONVERT(NVARCHAR(MAX), QT.text)) * 2
    ELSE ER.statement_end_offset END - ER.statement_start_offset)/2),
    [Parent Query] = qt.text, [Program] = program_name,  start_time
FROM sys.dm_exec_requests AS ER
INNER JOIN sys.sysprocesses AS SP ON ER.session_id = SP.spid
CROSS APPLY sys.dm_exec_sql_text(ER.sql_handle) AS QT
WHERE session_Id <> @@SPID
ORDER BY cpu_time DESC, total_elapsed_time DESC ;