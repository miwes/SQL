-- http://whoisactive.com/
-- 

DECLARE 
	@retention int = 7
	, @destination_table varchar(500) = 'WhoIsActive'
	, @destination_database sysname = 'WhoIsActive'
	, @schema varchar(max)
	, @SQL nvarchar(4000)
	, @parameters nvarchar(500)
	, @exists bit;
 
SET @destination_table = @destination_database + '.dbo.' + @destination_table;
 
--create the logging table
IF OBJECT_ID(@destination_table) IS NULL
BEGIN;
  EXEC sp_WhoIsActive  @get_transaction_info = 1,  @get_outer_command = 1,  @return_schema = 1,  @schema = @schema OUTPUT;
  PRINT @schema
  SET @schema = REPLACE(@schema, '<table_name>', @destination_table);  
  EXEC(@schema);
END;
 
--create index on collection_time
SET @SQL = 'USE ' + QUOTENAME(@destination_database) + '; IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(@destination_table) AND name = N''cx_collection_time'') SET @exists = 0';
SET @parameters = N'@destination_table varchar(500), @exists bit OUTPUT';
EXEC sp_executesql @SQL, @parameters, @destination_table = @destination_table, @exists = @exists OUTPUT;
 
IF @exists = 0
BEGIN;
  SET @SQL = 'CREATE CLUSTERED INDEX cx_collection_time ON ' + @destination_table + '(collection_time ASC)';
  EXEC (@SQL);
END;
 
--collect activity into logging table
EXEC dbo.sp_WhoIsActive @get_transaction_info = 1,  @get_outer_command = 1, @destination_table = @destination_table;  
 
--purge older data
SET @SQL = 'DELETE FROM ' + @destination_table + ' WHERE collection_time < DATEADD(day, -' + CAST(@retention AS varchar(10)) + ', GETDATE());';
EXEC (@SQL);