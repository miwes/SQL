SELECT 
	database_id
	,CONVERT(VARCHAR(25)
	, DB.name) AS dbName
	,(SELECT SUM((size*8)/1024) FROM sys.master_files  WHERE DB_NAME(database_id) = db.name AND type_desc = 'rows') DATA_MB
	,(SELECT SUM((size*8)/1024) FROM sys.master_files 

WHERE DB_NAME(database_id) = db.name AND type_desc = 'log') AS [Log MB] FROM sys.databases DB
WHERE 
	name in (select name from sys.databases)
