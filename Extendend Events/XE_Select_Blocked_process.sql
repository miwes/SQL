/*
	Vytvorit XE na events "blocked_process_report" - https://msdn.microsoft.com/en-us/library/ms191168.aspx
	
	Treshold je nutne nastavit (defaultne je vypnut), cas je v sekundach. Vypnuti trasholdu nastavit zase na 0.

	sp_configure 'show advanced options', 1 ;  
	GO  
	RECONFIGURE ;  
	GO  
	sp_configure 'blocked process threshold', 20 ;  
	GO  
	RECONFIGURE ;  
	GO  

*/

SELECT 
	DATEADD(hour,1,event_xml.value(N'(/event/@timestamp)[1]', N'datetime'))			AS [DateTime]
	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			'-'
		ELSE
			event_xml.value(N'(./data[@name="database_name"]/value)[1]', N'nvarchar(max)')
	END AS [DatabaseName]

	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			'DEADLOCK'
		ELSE
			event_xml.value(N'(./data[@name="lock_mode"]/text)[1]', N'nvarchar')
	END AS [LockMode]

	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			'1'
		ELSE
			CAST(event_xml.value(N'(/event/data[@name="duration"]/value)[1]','bigint')/1000000.0 AS decimal(6,2))														
	END AS [Duration (s)]

	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			ISNULL(event_xml.value(N'(/event/data[@name="xml_report"]/value/deadlock/process-list/process/@hostname)[2]','nvarchar(max)'),'-') 
			+ '\' + event_xml.value(N'(/event/data[@name="xml_report"]/value/deadlock/process-list/process/@loginname)[2]','nvarchar(max)')
		ELSE
			ISNULL(event_xml.value(N'(/event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process/@hostname)[1]','nvarchar(max)'),'-')
			+ '\' + event_xml.value(N'(/event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process/@loginname)[1]','nvarchar(max)')		
	END AS [Blocking]

	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			event_xml.value(N'(/event/data[@name="xml_report"]/value/deadlock/process-list/process/inputbuf)[1]','SYSNAME') 
		ELSE
			event_xml.value(N'(/event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process/inputbuf)[1]','SYSNAME')						
	END AS [Blocking Query]

	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			ISNULL(event_xml.value(N'(/event/data[@name="xml_report"]/value/deadlock/process-list/process/@hostname)[1]','nvarchar(max)'),'-') 
			+ '\' + event_xml.value(N'(/event/data[@name="xml_report"]/value/deadlock/process-list/process/@loginname)[1]','nvarchar(max)')
		ELSE
			ISNULL(event_xml.value(N'(/event/data[@name="blocked_process"]/value/blocked-process-report/blocked-process/process/@hostname)[1]','nvarchar(max)'),'-')
			+ '\' + event_xml.value(N'(/event/data[@name="blocked_process"]/value/blocked-process-report/blocked-process/process/@loginname)[1]','nvarchar(max)') 		
	END AS [Blocked]

	,CASE WHEN event_xml.value(N'(/event/data[@name="xml_report"]/value)[1]','nvarchar(max)') IS NOT NULL
		THEN
			event_xml.value(N'(/event/data[@name="xml_report"]/value/deadlock/process-list/process/inputbuf)[2]','SYSNAME') 
		ELSE
			event_xml.value(N'(/event/data[@name="blocked_process"]/value/blocked-process-report/blocked-process/process/inputbuf)[1]','SYSNAME')						
	END AS [Blocked Query]
	,XED AS [Raw_XML_Data]
FROM
	(SELECT CAST(event_data AS XML) AS XED FROM sys.fn_xe_file_target_read_file ('D:\AC\*.xel',NULL,NULL,NULL)) AS Event_Table
	CROSS APPLY XED.nodes('//event') n (event_xml)
ORDER BY event_xml.value(N'(/event/@timestamp)[1]', N'datetime') DESC