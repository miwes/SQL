DECLARE @path_to_health_session nvarchar(1000) = 'C:\temp\*.xel'

SELECT
    T.sdnodes.value('(event/@timestamp)[1]','datetime') as [timestamp],
    T.sdnodes.value('(/event/data/value/queryProcessing/@maxWorkers)[1]','bigint') as [Max Workers],
	T.sdnodes.value('(/event/data/value/queryProcessing/@workersCreated)[1]','bigint') as [Workers Created],
	T.sdnodes.value('(/event/data/value/queryProcessing/@workersIdle)[1]','bigint') as [Idle Workers],
	T.sdnodes.value('(/event/data/value/queryProcessing/@pendingTasks)[1]','bigint') as [Pending Tasks],
	T.sdnodes.value('(/event/data/value/queryProcessing/@hasUnresolvableDeadlockOccurred)[1]','int') as [Unresolvable Deadlock],
	T.sdnodes.value('(/event/data/value/queryProcessing/@hasDeadlockedSchedulersOccurred)[1]','int') as [Deadlocked Schedulers]
FROM
(    
	SELECT bpr.query('.') as sdnodes
    FROM 
    (   select CAST(event_data AS XML) as target_data,*
        from sys.fn_xe_file_target_read_file(@path_to_health_session,NULL,NULL,NULL)
        where object_name like 'sp_server_diagnostics_component_result'
    ) AS X
    CROSS APPLY target_data.nodes('/event') AS n(bpr)
) as T
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='QUERY_PROCESSING'