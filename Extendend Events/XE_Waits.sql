SELECT
	DATEADD(hour,1,event_xml.value(N'(/event/@timestamp)[1]', N'datetime'))			AS [DateTime]
	,event_xml.value(N'(/event/data[@name="wait_type"]/text)[1]','SYSNAME') AS [Statement]
	,event_xml.value(N'(/event/data[@name="duration"]/value)[1]','bigint') AS [Duration (s)]
	,event_xml.value(N'(/event/action[@name="database_name"]/value)[1]','SYSNAME') AS [Database]
	,event_xml.value(N'(/event/action[@name="sql_text"]/value)[1]','SYSNAME') AS [Statement]
	,XED
FROM
	(SELECT CAST(event_data AS XML) AS XED FROM sys.fn_xe_file_target_read_file ('D:\AC\SQL_Wait*.xel',NULL,NULL,NULL)) AS Event_Table
	CROSS APPLY XED.nodes('//event') n (event_xml)
ORDER BY 
	DATEADD(hour,1,event_xml.value(N'(/event/@timestamp)[1]', N'datetime'))	 DESC