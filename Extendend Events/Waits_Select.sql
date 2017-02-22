SELECT
	event_xml.value(N'(/event/@timestamp)[1]', N'datetime')
	,event_xml.value('(./@name)', 'varchar(1000)') as Event_Name
    ,(event_xml.value('(./data[@name="wait_type"]/text)[1]', 'nvarchar(max)')) AS Wait_Type
    ,event_xml.value('(./data[@name="duration"]/value)[1]', 'int') as Duration
    ,event_xml.value('(./data[@name="opcode"]/text)[1]', 'varchar(100)') as Operation
    ,event_xml.value('(./action[@name="session_id"]/value)[1]', 'int') as SPID
    ,event_xml.value('(./action[@name="sql_text"]/value)[1]', 'nvarchar(max)') as TSQLQuery
    ,event_xml.value('(./action[@name="plan_handle"]/value)[1]', 'nvarchar(max)') as PlanHandle
FROM    
	(SELECT CAST(event_data AS XML) xml_event_data FROM sys.fn_xe_file_target_read_file('c:\ac\wait_analysis*.xel', NULL, NULL, NULL)) AS event_table
	CROSS APPLY xml_event_data.nodes('//event') n (event_xml)
WHERE  
	event_xml.value(N'(/event/@timestamp)[1]', N'datetime') > '12/08/2016 9:30'
	AND
	event_xml.value('(./@name)', 'varchar(1000)') IN ('wait_info','wait_info_external')   
	AND
	event_xml.value('(./data[@name="wait_type"]/text)[1]', 'nvarchar(max)') NOT IN (
        N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
        N'CHKPT',                           N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
        N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
        N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT')

