SELECT SCHEMA_NAME(schema_id) AS SchemaName,name AS TableName
FROM sys.tables
WHERE 
--OBJECTPROPERTY(OBJECT_ID,'TableHasPrimaryKey') = 0
--AND 
is_replicated = 0
ORDER BY SchemaName, TableName;
GO