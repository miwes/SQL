/*
    -------------- definovane uzivatelem --------------------
*/
DECLARE @SourceDB AS NVARCHAR(MAX)		= '[MM_Kompetence]'
DECLARE @DestinationDB AS NVARCHAR(MAX) = '[NEW]'

USE [MM_Kompetence]

CREATE TABLE #migrateTable
(
    ID int IDENTITY(1,1) PRIMARY KEY
    ,tableName NVARCHAR(MAX)
)


DECLARE @SourceTable AS NVARCHAR(MAX)
	   ,@DestinationTable AS NVARCHAR(MAX)
	   ,@ID AS INT
	   ,@query AS NVARCHAR(MAX)
	   ,@result AS NVARCHAR(MAX) = ''
	   ,@resultOne AS NVARCHAR(MAX) = ''
	   ,@sqlcommand AS NVARCHAR(MAX)

SET @sqlcommand = '
	INSERT INTO #migrateTable
	SELECT
	  ''['' + TABLE_SCHEMA + ''].''+ TABLE_NAME
	FROM
	  ' + @SourceDB + '.INFORMATION_SCHEMA.TABLES
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
		 @SourceTable=@SourceDB + '.' + [TableName] 
		,@DestinationTable = @DestinationDB + '.' + [TableName]
	FROM #migrateTable WHERE ID = @ID

	SET @resultOne = 'Start copy;' + @DestinationTable + CHAR(10);
	RAISERROR (@resultOne, 10, 1) WITH NOWAIT

	BEGIN TRY
		SET @query = 'INSERT INTO ' + @DestinationTable + ' SELECT * FROM ' + @SourceTable
		EXECUTE sp_executesql @query
	
		SET @result += 'OK;' + @DestinationTable + CHAR(10);
		SET @resultOne = 'OK;' + @DestinationTable + CHAR(10);
		RAISERROR (@resultOne, 10, 1) WITH NOWAIT

		WAITFOR DELAY '00:00:05'

    END TRY

    BEGIN CATCH 
	   SET @result += 'ERROR;' + @DestinationTable + CHAR(10);
	   SET @resultOne = 'ERROR;' + @DestinationTable + CHAR(10);
	   RAISERROR (@resultOne, 10, 1) WITH NOWAIT
   	   WAITFOR DELAY '00:00:05'

    END CATCH

    FETCH NEXT FROM ROW_CURSOR INTO @Id
END

DROP TABLE #migrateTable

PRINT ''
PRINT '-VYSLEDEK---------------'
PRINT @result
