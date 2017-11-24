DECLARE @PathDB AS NVARCHAR(4000) = 'C:\Program Files\Microsoft SQL Server\MSSQL12.SQL2014\MSSQL\Data\'
DECLARE @PathLOG AS NVARCHAR(4000) = 'C:\Program Files\Microsoft SQL Server\MSSQL12.SQL2014\MSSQL\Data\'

DECLARE @tempFiles AS TABLE (ID INT IDENTITY(1,1),FileName NVARCHAR(255), Depth INT, IsFile INT)
DECLARE @TrigID AS INT

INSERT INTO @tempFiles
EXEC xp_dirtree @PathDB, 0, 1

DECLARE TrigCursor CURSOR FOR
SELECT ID FROM @TempFiles WHERE FileName LIKE '%.mdf'

OPEN TrigCursor
FETCH NEXT FROM TrigCursor INTO @TrigID
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @FullPath AS NVARCHAR(4000)
	SELECT @FullPath = @PathDB + [FileName] FROM @tempFiles WHERE ID = @TrigID
		
	/* Kontrola zda je db jiz attach
	*/
	IF (SELECT COUNT(*) FROM sys.master_files WHERE physical_name = @FullPath) = 0
	BEGIN
		DECLARE @DBNAME AS NVARCHAR(255)	
		SELECT @DBNAME = LEFT([FileName],CHARINDEX('.',[FileName])-1) FROM @tempFiles WHERE ID = @TrigID	
		
		DECLARE @LogFullName AS NVARCHAR(4000)	
		SELECT @LogFullName = @PathLOG + @DBNAME + '_log.ldf'
		
		DECLARE @QUERY AS NVARCHAR(4000)
		SET @QUERY = 'CREATE DATABASE [' + @DBNAME +'] ON (FILENAME = ' + quotename(@FullPath) + ' ),(FILENAME = ' + quotename(@LogFullName) + ' ) FOR ATTACH;'
		BEGIN TRY
			PRINT 'Attach DB ' + @DBNAME + ' ->  ' + @FullPath
			EXEC (@QUERY)
			PRINT 'Attach DB ' + @DBNAME + ' ->  OK'
		END TRY
		BEGIN CATCH
			PRINT '[Error]: ' + ERROR_MESSAGE()
		END CATCH


	END
	
	FETCH NEXT FROM TrigCursor INTO @TrigID
END
CLOSE TrigCursor   
DEALLOCATE TrigCursor