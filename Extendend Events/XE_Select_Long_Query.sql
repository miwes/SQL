/*
	Zapnute XE na rpc_completed a sql_statement_completed a duration vetzi nez chci :)

*/

;WITH DataXE AS 
(
SELECT
	DATEADD(hour,1,event_xml.value(N'(/event/@timestamp)[1]', N'datetime'))			AS [DateTime]
	,event_xml.value(N'(/event/data[@name="duration"]/value)[1]','int')/1000000 AS [Duration (s)]
	,event_xml.value(N'(/event/data[@name="statement"]/value)[1]','SYSNAME') AS [Statement]
	,event_xml.value(N'(/event/action[@name="client_hostname"]/value)[1]','SYSNAME') AS [Hostname]
	,event_xml.value(N'(/event/action[@name="database_name"]/value)[1]','SYSNAME') AS [Database]
	,event_xml.value(N'(/event/data[@name="result"]/text)[1]','SYSNAME') AS [Result]
	,event_xml.value(N'(/event/data[@name="object_name"]/value)[1]','SYSNAME') AS [ObjectName]
	,event_xml.value(N'(/event/data[@name="row_count"]/value)[1]','SYSNAME') AS [Rowcount]
	,event_xml.value(N'(/event/action[@name="session_id"]/value)[1]','SYSNAME') AS [SessionID]
	,event_xml.value(N'(/event/action[@name="username"]/value)[1]','SYSNAME') AS [Username]
	,CASE WHEN event_xml.value('(/event/action[@name="plan_handle"]/value)[1]', 'varchar(max)') <> '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
		THEN
			(SELECT query_plan FROM sys.dm_exec_query_plan(convert(varbinary(max), event_xml.value('(/event/action[@name="plan_handle"]/value)[1]', 'varchar(max)') ,2)))
		ELSE NULL
	 END AS [plan_handle]
	,XED AS [Raw_XML_Data]

FROM
	(SELECT CAST(event_data AS XML) AS XED FROM sys.fn_xe_file_target_read_file ('D:\AC\SQLLong*.xel',NULL,NULL,NULL)) AS Event_Table
	CROSS APPLY XED.nodes('//event') n (event_xml)
)
SELECT 
	*
FROM DataXE
ORDER BY [DateTime] DESC