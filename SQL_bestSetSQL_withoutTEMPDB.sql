/*
	Nastavovaci skript pro SQL - TempDB, MaxMemory, MaxDOP, kompres backup

	Michal Weis 2016
	V1.3.2
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
DECLARE @i AS INT = 1
DECLARE @tempDBName AS NVARCHAR(MAX)
DECLARE @tempDBNamePath AS NVARCHAR(MAX)
DECLARE @NoOfNUMA INT 
DECLARE @NoOfLogCPU INT
DECLARE @NoOfCPUPerNUMA INT

SET @numberCPU = (SELECT cpu_count FROM sys.dm_os_sys_info)
SET @maxMemory =((SELECT physical_memory_kb FROM sys.dm_os_sys_info) / 1000) * 0.8

/* povol nastaveni */
EXEC dbo.sp_configure 'show advanced options', 1;
RECONFIGURE;

/* zapnuti optimalizace pro ADHOC query */
EXEC sp_configure 'optimize for ad hoc workloads', 1

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
EXEC sp_configure 'cost threshold for parallelism', 50 ;  

RECONFIGURE;
EXEC dbo.sp_configure 'show advanced options', 0;
RECONFIGURE;
