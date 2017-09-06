SELECT 
	SCHEMA_NAME(schema_id) AS [Schema Name]
	, name AS [Table Name]
	, is_replicated
	, OBJECTPROPERTY(OBJECT_ID,'TableHasPrimaryKey') AS [PrimaryKeyExist]
FROM sys.tables 
WHERE
 	is_replicated = 0
	and is_ms_shipped = 0
Order by name
GO