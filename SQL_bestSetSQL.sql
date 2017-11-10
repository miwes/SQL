/*
	Nastavovaci skript pro SQL - TempDB, MaxMemory, MaxDOP, kompres backup

	Michal Weis 2016
	V1.3.2
		- pridana definice @tempDBSize
		- upraveno nastaveni MAXDOP
		- opraveno nastaveni MAXDOP
		- pridano zapnuti 'optimize for ad hoc workloads'
	10.11.2017
		- cost threshold
*/


DECLARE @numberCPU INT
DECLARE @maxMemory BIGINT
DECLARE @SQL NVARCHAR(MAX)
DECLARE @ParamDef NVARCHAR(MAX)
DECLARE @TempDB AS NVARCHAR(MAX)
DECLARE @TempDBPath AS NVARCHAR(MAX)
DECLARE @TempDBSize AS NVARCHAR(MAX) = 200 --velikost v MB
DECLARE @i AS INT = 1
DECLARE @tempDBName AS NVARCHAR(MAX)
DECLARE @tempDBNamePath AS NVARCHAR(MAX)
DECLARE @NoOfNUMA INT 
DECLARE @NoOfLogCPU INT
DECLARE @NoOfCPUPerNUMA INT

SET @numberCPU = (SELECT cpu_count FROM sys.dm_os_sys_info)
SET @maxMemory =((SELECT physical_memory_kb FROM sys.dm_os_sys_info) / 1000) * 0.8
SET @TempDB = (SELECT TOP(1) physical_name AS Location FROM sys.master_files WHERE database_id = DB_ID(N'tempdb'))
SET @TempDBPath = (SELECT LEFT(@TempDB,LEN(@TempDB)-CHARINDEX('\',REVERSE(@TempDB))+1))

/* povol nastaveni */
EXEC dbo.sp_configure 'show advanced options', 1;
RECONFIGURE;

/* zapnuti optimalizace pro ADHOC query */
EXEC sp_configure 'optimize for ad hoc workloads', 1


/* nastav TEMPDB dle poctu CPU */
-- nastav prvni soubor na @tempDBSize
SET @SQL = N'ALTER DATABASE tempdb MODIFY FILE( NAME = N''tempdev'', SIZE = ' + @TempDBSize + 'MB , FILEGROWTH = 10%)'
EXEC sp_executesql @SQL

-- pokud je vice nez 8 CPU, max. tempdb souboru bude 8
IF @numberCPU > 8 
BEGIN
   SET @numberCPU = 8
END

WHILE @i < @numberCPU
BEGIN
	SET @tempDBNamePath = (@TempDBPath + 'tempdb' + CONVERT(VARCHAR(MAX),@i) + '.ndf')
	SET @tempDBName = ('tempdev' + CONVERT(VARCHAR(MAX),@i))
	SET @SQL = N'ALTER DATABASE tempdb ADD FILE ( NAME = N''' + @tempDBName + ''', FILENAME = N''' + @tempDBNamePath + ''',SIZE = ' + @TempDBSize + 'MB , FILEGROWTH = 10%)'
	SET @ParamDef = N'@tempDBName NVARCHAR(MAX), @tempDBNamePath NVARCHAR(MAX)'
	PRINT @SQL
	EXEC sp_executesql @SQL, @ParamDef, @tempDBName = @tempDBName, @tempDBNamePath = @tempDBNamePath
			
	SET @i = @i + 1
END

/* maxdop dle poctu CPU - dle kb https://support.microsoft.com/cs-cz/kb/2806535 */
SELECT @NoOfNUMA = COUNT(*) FROM sys.dm_os_memory_nodes WHERE memory_node_id < 64
If @NoOfNUMA > 1  -- Vice jak 1 NUMA node
BEGIN
	SELECT @NoOfLogCPU = cpu_count FROM sys.dm_os_sys_info
	SELECT @NoOfCPUPerNUMA = @NoOfLogCPU / @NoOfNUMA 
	IF @NoOfCPUPerNUMA < 8
	BEGIN
		SET @SQL = N'EXEC dbo.sp_configure ''max degree of parallelism'',' + CONVERT(VARCHAR(MAX),@NoOfCPUPerNUMA)
		SET @ParamDef = N'@NoOfCPUPerNUMA int'
		PRINT @SQL
		EXEC sp_executesql @SQL, @ParamDef, @NoOfCPUPerNUMA = @NoOfCPUPerNUMA
	END
	ELSE
	BEGIN
		SET @SQL = N'EXEC dbo.sp_configure ''max degree of parallelism'', 8'
		PRINT @SQL
		EXEC sp_executesql @SQL
	END
END
ELSE
BEGIN
	SELECT @NoOfLogCPU = cpu_count FROM sys.dm_os_sys_info
	IF @NoOfLogCPU < 8
	BEGIN
		SET @SQL = N'EXEC dbo.sp_configure ''max degree of parallelism'',' + CONVERT(VARCHAR(MAX),@NoOfLogCPU)
		SET @ParamDef = N'@NoOfLogCPU int'
		PRINT @SQL
		EXEC sp_executesql @SQL, @ParamDef, @NoOfLogCPU = @NoOfLogCPU
	END
	ELSE
	BEGIN
		SET @SQL = N'EXEC dbo.sp_configure ''max degree of parallelism'', 8'
		PRINT @SQL
		EXEC sp_executesql @SQL
	END
END

/* maximalni pamet - 80% pameti serveru */
SET @SQL = N'EXEC sys.sp_configure ''max server memory (MB)'',' + CONVERT(VARCHAR(MAX),@maxMemory)
SET @ParamDef = N'@maxMemory int'
PRINT @SQL
EXEC sp_executesql @SQL, @ParamDef, @maxMemory = @maxMemory

/* nastaveni komprese na backupu*/
EXEC sp_configure 'backup compression default', 1 ;
							      
/* nastaveni cost threshold */
EXEC sp_configure 'cost threshold for parallelism', 25 ;  


RECONFIGURE;
EXEC dbo.sp_configure 'show advanced options', 0;
RECONFIGURE;
