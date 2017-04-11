DECLARE @path_to_health_session nvarchar(1000) = 'C:\temp\*.xel'

SELECT
     T.sdnodes.value('(event/@timestamp)[1]','datetime') as [timestamp],
     T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)') as [component_name],
     T.sdnodes.value('(event/data[@name="state"]/text)[1]', 'varchar(100)') as [component_state],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@spinlockBackoffs)[1]', 'int') as [spinlockBackoffs],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@sickSpinlockTypeAfterAv)[1]', 'varchar(100)') as [sickSpinlockTypeAfterAv],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@isAccessViolationOccurred)[1]', 'int') as [isAccessViolationOccurred],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@writeAccessViolationCount)[1]', 'int') as [writeAccessViolationCount],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@intervalDumpRequests)[1]', 'int') as [intervalDumpRequests],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@nonYieldingTasksReported)[1]', 'int') as [nonYieldingTasksReported],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@pageFaults)[1]', 'bigint') as [pageFaults],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@systemCpuUtilization)[1]', 'int') as [systemCpuUtilization],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@sqlCpuUtilization)[1]', 'int') as [sqlCpuUtilization],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@BadPagesDetected)[1]', 'int') as [BadPagesDetected],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@BadPagesFixed)[1]', 'int') as [BadPagesFixed],
     T.sdnodes.value('(event/data[@name="data"]/value/system[1]/@LastBadPageAddress)[1]', 'nvarchar(30)') as [LastBadPageAddress]
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
WHERE T.sdnodes.value('(event/data[@name="component"]/text)[1]', 'varchar(100)')='SYSTEM'