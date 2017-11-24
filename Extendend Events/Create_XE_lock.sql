CREATE EVENT SESSION [SQL Locks] ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.database_id,sqlserver.sql_text)),
ADD EVENT sqlserver.xml_deadlock_report 
ADD TARGET package0.event_file(SET filename=N'D:\AC\SQLLogs.xel',max_file_size=(200),max_rollover_files=(2))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


