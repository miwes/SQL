SELECT 
	*
FROM sys.configurations
WHERE 
	NAME = 'max degree of parallelism'
	OR NAME = 'min server memory (MB)'
	OR NAME = 'max server memory (MB)'
	OR NAME = 'optimize for ad hoc workloads'
	OR NAME = 'cost threshold for parallelism'
    
--total memory
SELECT [Total_Physical_Memory_KB] FROM sys.dm_os_sys_memory;

--pocet CPU
SELECT cpu_count FROM sys.dm_os_sys_info;

--verze SQL
Select @@version;

--tempdb settings
SELECT
	name AS FileName,
	size*1.0/128 AS FileSizeinMB,
	CASE max_size
	WHEN 0 THEN 'Autogrowth is off.'
	WHEN -1 THEN 'Autogrowth is on.'
	ELSE 'Log file will grow to a maximum size of 2 TB.'
	END AutogrowthStatus,
	growth AS 'GrowthValue',
	'GrowthIncrement' =
	CASE
		WHEN growth = 0 THEN 'Size is fixed and will not grow.'
		WHEN growth > 0
		AND is_percent_growth = 0
		THEN 'Growth value is in 8-KB pages.'
		ELSE 'Growth value is a percentage.'
	END
FROM tempdb.sys.database_files;
