DECLARE @path_to_health_session nvarchar(1000) = 'C:\temp\winpcadb\*.xel'

SELECT
    T.sdnodes.value('(event/@timestamp)[1]','datetime') as [timestamp],
	T.sdnodes.value('(/event/data/text)[1]','varchar(255)') as Component,
	T.sdnodes.value('(/event/data/value/resource/@outOfMemoryExceptions)[1]','bigint') as [OOM Exceptions],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[1]','bigint')/(1024*1024*1024) as [Available Physical Memory (GB)],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[3]','bigint')/(1024*1024*1024) as [Available Paging File (GB)],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[5]','int') as [Percent of Committed Memory in WS],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[6]','bigint') as [Page Faults],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[12]','bigint')/1024 as [VM Committed (MB)],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[13]','bigint')/(1024*1024) as [Locked Pages Allocated (GB)],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[14]','bigint')/(1024*1024) as [Large Pages Allocated (GB)],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[17]','bigint')/(1024*1024) as [Target Committed (GB)],
	T.sdnodes.value('(/event/data/value/resource/memoryReport/entry/@value)[18]','bigint')/(1024*1024) as [Current Committed (GB)]
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
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='RESOURCE'