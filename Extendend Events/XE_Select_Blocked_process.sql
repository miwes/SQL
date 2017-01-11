/*
	Vytvorit XE na events "blocked_process_report"
	
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
	event_xml.value(N'(/event/@timestamp)[1]', N'datetime') AS [DateTime]
	,DB_NAME(event_xml.value(N'(./data[@name="database_id"]/value)[1]', N'int')) AS [DatabaseName]
	,event_xml.value(N'(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(max)') AS [Client_app_name]
	,event_xml.value(N'(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS [Client_Hostname]
	,event_xml.value(N'(./data[@name="lock_mode"]/text)[1]', N'nvarchar') AS [LockMode]
	,event_xml.value(N'(/event[@name="blocked_process_report"]/data[@name="duration"]/value)[1]','bigint') / 1000 /1000 AS [duration (s)]
	,event_xml.query(N'(/event[@name="blocked_process_report"]/data[@name="blocked_process"]/value/blocked-process-report)[1]') AS [Blocked_process_report]
	,event_xml.query(N'(event/data[@name="xml_report"]/value/deadlock)[1]') AS [Deadlock_graph]
	,XED AS [Raw_XML_Data]
FROM
	(SELECT CAST(event_data AS XML) AS XED FROM sys.fn_xe_file_target_read_file ('D:\AC\*.xel',NULL,NULL,NULL)) AS Event_Table
	CROSS APPLY XED.nodes('//event') n (event_xml)
ORDER BY event_xml.value(N'(/event/@timestamp)[1]', N'datetime') DESC