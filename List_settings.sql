# show disk allocation unit - fsutil fsinfo ntfsinfo d:
#		 Bytes Per Cluster = allocation unit

SELECT
	'Instance name' as [name]
	,@@servername as [nastaveni]

UNION ALL

SELECT 
	'TCP port'  as [name]
	,local_tcp_port  as [nastaveni]
FROM   sys.dm_exec_connections
WHERE  session_id = @@SPID

UNION ALL

SELECT 
	'Microsoft SQL version' as [name]
	,@@version as [nastaveni]

UNION ALL

SELECT
	'Default path DB' as [name]
	,SERVERPROPERTY('InstanceDefaultDataPath') AS [nastaveni]

UNION ALL

SELECT
	'Default path LOG' as [name]
	,SERVERPROPERTY('InstanceDefaultLogPath') AS [nastaveni]

UNION ALL

SELECT 
	'SYSADMINS' as [name],
	CONVERT(NVARCHAR(4000),(
		SELECT p.name + ', ' 
		FROM sys.server_principals p
			JOIN sys.syslogins s ON p.sid = s.sid
		WHERE p.type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
		AND p.name NOT LIKE '##%'
		AND s.sysadmin = 1
		AND is_disabled = 0
		FOR XML PATH(''))) AS [Value]

UNION ALL

SELECT 
	'Default collaction' as [name]
     ,collation_name  as [value]
FROM 
    sys.databases
WHERE database_id = DB_ID()

UNION ALL

SELECT 
	'---- SQL settings ----' as [name]
	,'-----------------------------------------------------------------------------' as [value]
UNION ALL

SELECT 
	name
	,value_in_use as [nastaveni]

FROM sys.configurations
WHERE 
	NAME = 'max degree of parallelism'
	OR NAME = 'min server memory (MB)'
	OR NAME = 'max server memory (MB)'
	OR NAME = 'optimize for ad hoc workloads'
	OR NAME = 'cost threshold for parallelism'
