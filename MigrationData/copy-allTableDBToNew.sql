/*
    -------------- definovane uzivatelem --------------------
*/
DECLARE @SourceDB AS NVARCHAR(MAX)	= '[Integration]'
DECLARE @DestinationDB AS NVARCHAR(MAX) = '[Integration_collation]'
 
USE [SAP2SPIntegration_collation]
 
CREATE TABLE #migrateTable
(
    ID int IDENTITY(1,1) PRIMARY KEY
    ,tableName NVARCHAR(MAX)
	,rawtableName NVARCHAR(MAX)
)
 
 
DECLARE @SourceTable AS NVARCHAR(MAX)
	   ,@SourceTableRaw AS NVARCHAR(MAX)
	   ,@DestinationTable AS NVARCHAR(MAX)
	   ,@ID AS INT
	   ,@query AS NVARCHAR(MAX)
	   ,@result AS NVARCHAR(MAX) = ''
	   ,@resultOne AS NVARCHAR(MAX) = ''
	   ,@sqlcommand AS NVARCHAR(MAX)
	   ,@sqlColumns AS NVARCHAR(MAX)
	   ,@isIdentity AS INT
 
SET @sqlcommand = '
	INSERT INTO #migrateTable
	SELECT
	  ''['' + TABLE_SCHEMA + ''].[''+ TABLE_NAME + '']''
	  ,TABLE_NAME
	FROM
	  ' + @SourceDB + '.INFORMATION_SCHEMA.TABLES
	 WHERE TABLE_NAME <> ''MimoTuhle''
	 --WHERE TABLE_NAME = ''Tuhle chci''
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
		 @SourceTableRaw = rawtableName
		,@SourceTable = @SourceDB + '.' + [TableName] 
		,@DestinationTable = @DestinationDB + '.' + [TableName]
	FROM #migrateTable WHERE ID = @ID
 
	SET @resultOne = 'Start copy;' + @DestinationTable + CHAR(10);
	RAISERROR (@resultOne, 10, 1) WITH NOWAIT

	SET @query = N'
		SELECT @outputSqlColumns =  STRING_AGG(CAST(COLUMN_NAME AS NVARCHAR(MAX)),'','') FROM [SAP2SPIntegration].information_schema.columns WHERE TABLE_NAME= ''' + @SourceTableRaw + '''
		'
	EXECUTE sp_executesql @query, N'@outputSqlColumns nvarchar(max) out', @sqlColumns out

	BEGIN TRY

		SET @query = N'
			SELECT 
				@outputIsIdentity = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
			FROM sys.objects A
			INNER JOIN sys.identity_columns B
			ON A.[object_id]=B.[object_id]
			WHERE 
				A.type=''U''
				AND A.[Name] = ''' + @SourceTableRaw + '''';
		EXECUTE sp_executesql @query, N'@outputIsIdentity INT out', @outputIsIdentity = @isIdentity out

		IF @isIdentity <> 0 
		BEGIN
			SET @query = N' SET IDENTITY_INSERT ' + @DestinationTable + ' ON; '
			SET @query += N'INSERT INTO ' + @DestinationTable + '(' + @sqlColumns +  ') SELECT '+ @sqlColumns +' FROM ' + @SourceTable
			EXECUTE sp_executesql @query
			SET @query = N' SET IDENTITY_INSERT ' + @DestinationTable + ' OFF'
			EXECUTE sp_executesql @query
		END
		ELSE
		BEGIN
			SET @query = N'INSERT INTO ' + @DestinationTable + '(' + @sqlColumns +  ') SELECT '+ @sqlColumns +' FROM ' + @SourceTable
			EXECUTE sp_executesql @query
		END 
 
		SET @result += 'OK;' + @DestinationTable + CHAR(10);
		SET @resultOne = 'OK;' + @DestinationTable + CHAR(10);
		RAISERROR (@resultOne, 10, 1) WITH NOWAIT
 
    END TRY
 
    BEGIN CATCH 
	   SET @result += 'ERROR;' + @DestinationTable + ' ' + ERROR_MESSAGE() + CHAR(10);
	   SET @resultOne = 'ERROR;' + @DestinationTable + ' ' +  ERROR_MESSAGE() + CHAR(10);
	   RAISERROR (@resultOne, 10, 1) WITH NOWAIT
 
    END CATCH
 
    FETCH NEXT FROM ROW_CURSOR INTO @Id
END
 
DROP TABLE #migrateTable
 
PRINT ''
PRINT '-VYSLEDEK---------------'
PRINT @result
