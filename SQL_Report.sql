-------------------------------------
-- Verze SQL serveru - https://sqlserverbuilds.blogspot.com/
-------------------------------------
SELECT 
	'Microsoft SQL version' as [name]
	,@@version as [nastaveni]

-------------------------------------
-- Datum posledniho backupu
-------------------------------------
SELECT 
	sdb.Name AS DatabaseName
	,COALESCE(CONVERT(VARCHAR(12), MAX(bus.backup_finish_date), 101),'-') AS LastBackUpTime
FROM sys.sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
GROUP BY sdb.Name
ORDER BY LastBackUpTime

-------------------------------------
-- Volne misto v databazich a logach
-------------------------------------
DECLARE @freeSpace TABLE (
							DBname NVARCHAR(255)
							, physical_name NVARCHAR(255)
							, type NVARCHAR(20)
							, sizeMB NVARCHAR(20)
							, FreeSpacePercent FLOAT
							, state_desc NVARCHAR(20)
							, Max_Size NVARCHAR(100)
							, Growth NVARCHAR(20)
						)

INSERT INTO @freeSpace
EXEC sp_msforeachdb 
	'USE [?]; 
		SELECT 
			''?'' as Name
			,DF.physical_name
			, CASE WHEN DF.Type  = 0 THEN ''DATA'' ELSE ''LOG'' END AS TYPE
			, CAST(CAST(Round(CAST(DF.size as decimal) * 8.0/1024.0,2) as decimal(18,2)) as NVARCHAR) AS sizeMB
			, CONVERT(FLOAT,CAST(
				(
					(CAST(Round(CAST(DF.size as decimal) * 8.0/1024.0,2) as decimal(18,2)) - CAST(FILEPROPERTY(DF.name, ''SpaceUsed'') * 8.0/1024.0 as decimal(18,2))
				) * 100) / (Round(CAST(DF.size as decimal) * 8.0/1024.0,2))
				as decimal(18,2))) AS FreeSpacePercent
			, DF.state_desc
			,CASE WHEN DF.[max_size]=-1 THEN ''Unlimited'' ELSE CONVERT(VARCHAR(10),CONVERT(bigint,DF.[max_size])*8) +'' KB'' END AS [Max_Size]
			,CASE DF.is_percent_growth WHEN 1 THEN CONVERT(VARCHAR(10),DF.growth) +''%'' ELSE Convert(VARCHAR(10),DF.growth*8) +'' KB'' END AS [Growth]
		FROM sys.database_files AS DF
	'
SELECT 
	* 
FROM @freeSpace
WHERE [Type] = 'DATA'
ORDER BY FreeSpacePercent

SELECT 
	* 
FROM @freeSpace
WHERE [Type] = 'LOG'
ORDER BY  FreeSpacePercent


-------------------------------------
-- Volne misto na diskach
-------------------------------------
SELECT 
	DISTINCT dovs.logical_volume_name AS LogicalName,
	dovs.volume_mount_point AS Drive,
	CONVERT(INT,dovs.available_bytes/1048576.0) AS FreeSpaceInMB
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
ORDER BY FreeSpaceInMB ASC

-------------------------------------
-- Chyby v errorlogu pro server
-------------------------------------
DECLARE @StartTime AS DATETIME
SELECT @StartTime = DATEADD(month,-1,GETDATE())
EXEC xp_readerrorlog 0, 1, N'error',N'',@StartTime, NULL,N'desc'
EXEC xp_readerrorlog 0, 1, N'failed',N'',@StartTime, NULL,N'desc'

-------------------------------------
-- Chyby v errorlogu pro agenta
-------------------------------------
DECLARE @StartTime AS DATETIME
SELECT @StartTime = DATEADD(month,-1,GETDATE())
EXEC xp_readerrorlog 0, 2, N'error',N'',@StartTime, NULL,N'desc'
EXEC xp_readerrorlog 0, 2, N'failed',N'',@StartTime, NULL,N'desc'

-------------------------------------
-- Chyby v SQL jobech
-------------------------------------
SELECT
     JobName = J.name
    ,H.*
FROM
    msdb.dbo.sysjobs AS J
    CROSS APPLY (
        SELECT TOP 1
            JobName = J.name
            ,StepNumber = T.step_id
            ,StepName = T.step_name
            ,StepStatus = CASE T.run_status
                WHEN 0 THEN 'Failed'
                WHEN 1 THEN 'Succeeded'
                WHEN 2 THEN 'Retry'
                WHEN 3 THEN 'Canceled'
                ELSE 'Running' END,
            ExecutedAt = msdb.dbo.agent_datetime(T.run_date, T.run_time),
            Message = T.message
        FROM
            msdb.dbo.sysjobhistory AS T
        WHERE
            T.job_id = J.job_id
			AND T.run_status <> 1
        ORDER BY
            T.instance_id DESC) AS H
WHERE J.Enabled = 1
ORDER BY
    J.name
