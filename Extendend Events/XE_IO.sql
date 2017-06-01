DECLARE @path_to_health_session nvarchar(1000) = 'C:\temp\*.xel'

SELECT
    DATEADD(hour,2,T.sdnodes.value('(event/@timestamp)[1]','datetime')) AS [DateTime],
	T.sdnodes.value('(/event/data/text)[1]','varchar(255)') as Component,
	T.sdnodes.value('(/event/data/value/ioSubsystem/@ioLatchTimeouts)[1]','bigint') as [IO Latch Timeouts],
	T.sdnodes.value('(/event/data/value/ioSubsystem/@totalLongIos)[1]','bigint') as [Total Long IOs],
	T.sdnodes.value('(/event/data/value/ioSubsystem/longestPendingRequests/pendingRequest/@filePath)[1]','varchar(8000)') as [Longest Pending Request File],
	T.sdnodes.value('(/event/data/value/ioSubsystem/longestPendingRequests/pendingRequest/@duration)[1]','bigint') as [Longest Pending IO Duration]

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
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='IO_SUBSYSTEM'