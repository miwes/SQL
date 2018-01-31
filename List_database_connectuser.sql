SELECT 
	SD.name AS [Database]
	,SUBSTRING(SMF.physical_name,0,LEN(SMF.physical_name)-CHARINDEX('\',REVERSE(SMF.physical_name))+1) AS [PathDB]
	,SD.state_desc			   AS [StateDB]
	,SS.hostname			   AS [FromHostname]
	,SS.nt_username			   AS [ConnectUser]	
	,suser_sname(SD.owner_sid) AS [Owner]
FROM sys.databases AS SD
LEFT JOIN sys.master_files AS SMF	ON SMF.database_id = SD.database_id AND SMF.type=0
LEFT JOIN sys.sysprocesses AS SS	ON SS.dbid = SD.database_id

GROUP BY SD.name
	,SUBSTRING(SMF.physical_name,0,LEN(SMF.physical_name)-CHARINDEX('\',REVERSE(SMF.physical_name))+1)
	,SD.state_desc
	,SS.hostname
	,SS.nt_username
	,SD.owner_sid