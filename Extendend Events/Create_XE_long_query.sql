-- long 10s >

CREATE EVENT SESSION [SQL Long Query] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[greater_than_uint64]([duration],(10000000)))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([duration]>(10000000))),
ADD EVENT sqlserver.sql_statement_completed(SET collect_statement=(1)
    ACTION(sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[greater_than_int64]([duration],(10000000)))) 
ADD TARGET package0.event_file(SET filename=N'D:\AC\SQL_LongQuery.xel',max_file_size=(200),max_rollover_files=(2))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


