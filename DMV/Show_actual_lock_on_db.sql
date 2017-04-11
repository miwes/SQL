DECLARE @dbid INT ; 
SET @dbid = DB_ID() ;

SELECT  resource_type
       ,resource_database_id
       ,OBJECT_NAME(resource_associated_entity_id)
       ,request_mode
       ,request_type
       ,request_session_id
	   ,DES.host_name
	   ,DES.login_name
	   ,CASE DES.transaction_isolation_level 
			WHEN 0 THEN 'Unspecified' 
			WHEN 1 THEN 'ReadUncommitted' 
			WHEN 2 THEN 'ReadCommitted' 
			WHEN 3 THEN 'Repeatable' 
			WHEN 4 THEN 'Serializable' 
			WHEN 5 THEN 'Snapshot' 
		END AS TRANSACTION_ISOLATION_LEVEL 
	   ,MRSH.text	

FROM    sys.dm_tran_locks AS DRL

LEFT JOIN sys.dm_exec_sessions AS DES		ON DRL.request_session_id = DES.session_id
LEFT JOIN sys.dm_exec_connections AS DEC	ON DRL.request_session_id = DEC.session_id
CROSS APPLY sys.dm_exec_sql_text(DEC.most_recent_sql_handle) AS MRSH

WHERE   resource_database_id = @dbid
		AND resource_type = 'OBJECT'