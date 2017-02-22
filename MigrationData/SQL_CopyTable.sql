
CREATE TABLE #migrateTable
(
    ID int IDENTITY(1,1) PRIMARY KEY
    ,tableName NVARCHAR(MAX)
)

/*
    -------------- definovane uzivatelem --------------------
*/

DECLARE @SourceDB AS NVARCHAR(MAX)		= '[NAV1-Rajapack].[dbo]'
DECLARE @DestinationDB AS NVARCHAR(MAX) = '[Rajapack_test].[dbo]'

INSERT INTO #migrateTable
SELECT 'Rajapack Slovak$'+[Name]
  FROM 
  [NAV1-Rajapack].[dbo].[Rajapack Slovak$Table]

/*
    -------------- definovane uzivatelem --------------------
*/

DECLARE @SourceTable AS NVARCHAR(MAX)
	   ,@DestinationTable AS NVARCHAR(MAX)
	   ,@ID AS INT
	   ,@query AS NVARCHAR(MAX)
	   ,@result AS NVARCHAR(MAX) = ''

DECLARE ROW_CURSOR CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR SELECT ID FROM #migrateTable

OPEN ROW_CURSOR
FETCH NEXT FROM ROW_CURSOR INTO @ID
WHILE @@FETCH_STATUS = 0
BEGIN
    -- stare jmeno tabulky
    SELECT @SourceTable=REPLACE([TableName],'/','_') FROM #migrateTable WHERE ID = @ID
	SET @SourceTable = REPLACE(@SourceTable,'.','_')
    -- preved na nove jmeno tabulky
	SET @DestinationTable = @SourceTable
    --SET @DestinationTable = REPLACE(@SourceTable,'rajapack czech','obaly')

    BEGIN TRY
		-- zkontroluj existenci docasne tabulky
		IF OBJECT_ID('tempdb..##tmpMojeTable') IS NOT NULL DROP TABLE ##tmpMojeTable

		-- nacti data do docasne tabulky
		SET @query = 'SELECT * INTO ##tmpMojeTable FROM ' + @SourceDB + '.[' + @sourceTable + ']'
		EXECUTE sp_executesql @query
		
		-- zahod sloupce timestamp
		ALTER TABLE ##tmpMojeTable DROP COLUMN [timestamp]
	
		SELECT * FROM ##tmpMojeTable

	    -- spust kopirovani a pred tim smaz cilove tabulky
	    SET @query = 'DELETE FROM ' + @DestinationDB + '.[' + @DestinationTable + ']'
		EXECUTE sp_executesql @query

		SET @query = 'INSERT INTO ' + @DestinationDB + '.[' + @DestinationTable +'] SELECT NULL,* FROM ##tmpMojeTable'
		EXECUTE sp_executesql @query

		DROP TABLE ##tmpMojeTable
		   
		SET @result += 'OK;' + @DestinationTable + CHAR(10);
		PRINT @DestinationTable + ' OK'
    END TRY
    BEGIN CATCH 
	   SET @result += 'ERROR;' + @DestinationTable + CHAR(10);
	   PRINT @DestinationTable + ' - ' + ERROR_MESSAGE()
    END CATCH

    FETCH NEXT FROM ROW_CURSOR INTO @Id
END

CLOSE ROW_CURSOR
DEALLOCATE ROW_CURSOR

DROP TABLE #migrateTable

PRINT ''
PRINT '-VYSLEDEK---------------'
PRINT @result