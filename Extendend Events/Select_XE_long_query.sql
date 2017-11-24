;WITH DataXE AS 
(
SELECT
	DATEADD(hour,2,event_xml.value(N'(/event/@timestamp)[1]', N'datetime'))			AS [DateTime]
	,event_xml.value(N'(/event/data[@name="duration"]/value)[1]','bigint')/1000000 AS [Duration (s)]
	,event_xml.value(N'(/event/data[@name="statement"]/value)[1]','nvarchar(1000)') AS [Statement]
	,event_xml.value(N'(/event/data[@name="batch_text"]/value)[1]','nvarchar(1000)') AS [Batch_text]
	,event_xml.value(N'(/event/action[@name="client_hostname"]/value)[1]','SYSNAME') AS [Hostname]
	,event_xml.value(N'(/event/action[@name="database_name"]/value)[1]','SYSNAME') AS [Database]
	,event_xml.value(N'(/event/data[@name="result"]/text)[1]','SYSNAME') AS [Result]
	,event_xml.value(N'(/event/data[@name="object_name"]/value)[1]','SYSNAME') AS [ObjectName]
	,event_xml.value(N'(/event/data[@name="row_count"]/value)[1]','SYSNAME') AS [Rowcount]
	,event_xml.value(N'(/event/action[@name="session_id"]/value)[1]','SYSNAME') AS [SessionID]
	,event_xml.value(N'(/event/action[@name="username"]/value)[1]','SYSNAME') AS [Username]
	/*,CASE WHEN event_xml.value('(/event/action[@name="plan_handle"]/value)[1]', 'varchar(max)') <> '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'
		THEN
			(SELECT query_plan FROM sys.dm_exec_query_plan(convert(varbinary(max), event_xml.value('(/event/action[@name="plan_handle"]/value)[1]', 'varchar(max)') ,2)))
		ELSE NULL
	 END AS [plan_handle]*/
	,XED AS [Raw_XML_Data]

FROM
	(SELECT CAST(event_data AS XML) AS XED FROM sys.fn_xe_file_target_read_file ('D:\AC\SQL_Long*.xel',NULL,NULL,NULL)) AS Event_Table
	CROSS APPLY XED.nodes('//event') n (event_xml)
--WHERE
--	DATEADD(hour,2,event_xml.value(N'(/event/@timestamp)[1]', N'datetime')) > '2017-05-08 22:30:00.000'
--	AND DATEADD(hour,2,event_xml.value(N'(/event/@timestamp)[1]', N'datetime')) < '2017-05-08 23:10:00.000'
--AND event_xml.value(N'(/event/action[@name="database_name"]/value)[1]','SYSNAME')  = 'mdb'
)
SELECT 
	DateTime
	,[Duration (s)]
	,CASE WHEN Statement IS NULL 
		THEN REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(MAX),[batch_text]),CHAR(13),''), CHAR(10), ''), CHAR(9), '')
		ELSE REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(MAX),[Statement]),CHAR(13),''), CHAR(10), ''), CHAR(9), '') 
	 END AS [Statement]
	,Hostname
	,[Database]
	,Result
	,ObjectName
	,[Rowcount]
	,SessionID
	,Username
	,Raw_XML_Data
FROM DataXE
ORDER BY DateTime DESC
