/*
    -------------- definovane uzivatelem --------------------
*/
DECLARE @SourceDB AS NVARCHAR(MAX)		= '[SAP2SPIntegration]'
DECLARE @DestinationDB AS NVARCHAR(MAX) = '[SAP2SPIntegration_collation]'
 
USE [SAP2SPIntegration_collation]
 
CREATE TABLE #migrateTable
(
    ID int IDENTITY(1,1) PRIMARY KEY
    ,tableName NVARCHAR(MAX)
)
 
 
DECLARE @SourceTable AS NVARCHAR(MAX)
	   ,@SourceTableRaw AS NVARCHAR(MAX)
	   ,@DestinationTable AS NVARCHAR(MAX)
	   ,@ID AS INT
	   ,@query AS NVARCHAR(MAX)
	   ,@result AS NVARCHAR(MAX) = ''
	   ,@resultOne AS NVARCHAR(MAX) = ''
	   ,@sqlcommand AS NVARCHAR(MAX)
	   ,@sqlColunns AS NVARCHAR(MAX)
 
SET @sqlcommand = '
	INSERT INTO #migrateTable
	SELECT TOP 1
	  ''['' + TABLE_SCHEMA + ''].''+ TABLE_NAME
	FROM
	  ' + @SourceDB + '.INFORMATION_SCHEMA.TABLES
	  WHERE TABLE_NAME = ''UPE_OI_Z_HR_LN_GET_ORGEH2_ZHR_LN_GET_ORGEHProcessing''
'
-- vypis vsechny tabulky
EXEC (@sqlcommand)
 
DECLARE ROW_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR SELECT ID FROM #migrateTable
 
OPEN ROW_CURSOR
FETCH NEXT FROM ROW_CURSOR INTO @ID
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT 
		 @SourceTableRaw = [tableName]
		,@SourceTable = @SourceDB + '.' + [TableName] 
		,@DestinationTable = @DestinationDB + '.' + [TableName]
	FROM #migrateTable WHERE ID = @ID
 
	SET @resultOne = 'Start copy;' + @DestinationTable + CHAR(10);
	RAISERROR (@resultOne, 10, 1) WITH NOWAIT
 
	BEGIN TRY

		SELECT
			@sqlColunns = '(' + STRING_AGG(COLUMN_NAME,',') + ')'
		FROM [SAP2SPIntegration].information_schema.columns
		WHERE TABLE_NAME = @SourceTableRaw
			
		SET @query = ' SET IDENTITY_INSERT ' + @DestinationTable + ' ON' + CHAR(13)
		SET @query += 'INSERT INTO ' + @DestinationTable + ' ' + @sqlColunns +  'SELECT '+ @sqlColunns +' FROM ' + @SourceTable
		EXECUTE sp_executesql @query

		SET @query = ' SET IDENTITY_INSERT ' + @DestinationTable + ' OFF'
		EXECUTE sp_executesql @query
 
		SET @result += 'OK;' + @DestinationTable + CHAR(10);
		SET @resultOne = 'OK;' + @DestinationTable + CHAR(10);
		RAISERROR (@resultOne, 10, 1) WITH NOWAIT
 
    END TRY
 
    BEGIN CATCH 
	   SET @result += 'ERROR;' + @DestinationTable + ERROR_MESSAGE() + CHAR(10);
	   SET @resultOne = 'ERROR;' + @DestinationTable + ERROR_MESSAGE() + CHAR(10);
	   RAISERROR (@resultOne, 10, 1) WITH NOWAIT
 
    END CATCH
 
    FETCH NEXT FROM ROW_CURSOR INTO @Id
END
 
DROP TABLE #migrateTable
 
PRINT ''
PRINT '-VYSLEDEK---------------'
PRINT @result
