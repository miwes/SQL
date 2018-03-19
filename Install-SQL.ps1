<#
.SYNOPSIS
    Install and config SQL
.NOTE
    Author:     Michal Weis
    06.03.2018 - Start
.EXAMPLE
#>

[cmdletbinding()]
Param(
	$FEATURES='SQLEngine'
	,$INSTANCENAME='SHPTEST'
	,$SQLCOLLATION='Latin1_General_CI_AS_KS_WS'
	,$SQLSYSADMINACCOUNTS='LAB\SQL sysadmins'
	,$SQLBACKUPDIR='S:\Microsoft SQL Server\MSSQL14.SHPTEST\MSSQL\Backup'
	,$SQLTEMPDBDIR='S:\Microsoft SQL Server\MSSQL14.SHPTEST\MSSQL\Data'
	,$SQLTEMPDBLOGDIR='L:\Microsoft SQL Server\MSSQL14.SHPTEST\MSSQL\Data'
	,$SQLUSERDBDIR='S:\Microsoft SQL Server\MSSQL14.SHPTEST\MSSQL\Data'
	,$SQLUSERDBLOGDIR='L:\Microsoft SQL Server\MSSQL14.SHPTEST\MSSQL\Data'
	,$TCPPORT=1460
)

Set-StrictMode -Version latest

$STRSQLBACKUPDIR = -join ("/SQLBACKUPDIR=",'"',$SQLBACKUPDIR,'"')
$STRSQLTEMPDBDIR = -join ("/SQLTEMPDBDIR=",'"',$SQLTEMPDBDIR,'"')
$STRSQLTEMPDBLOGDIR = -join ("/SQLTEMPDBLOGDIR=",'"',$SQLTEMPDBLOGDIR,'"')
$STRSQLUSERDBDIR = -join ("/SQLUSERDBDIR=",'"',$SQLUSERDBDIR,'"')
$STRSQLUSERDBLOGDIR = -join ("/SQLUSERDBLOGDIR=",'"',$SQLUSERDBLOGDIR,'"')

$allArguments = @('/q','/IACCEPTSQLSERVERLICENSETERMS','/ACTION=install','/AGTSVCSTARTUPTYPE=Automatic','/BROWSERSVCSTARTUPTYPE=disabled','/TCPENABLED=1',"/FEATURES=$FEATURES","/INSTANCENAME=$INSTANCENAME","/SQLSYSADMINACCOUNTS=$SQLSYSADMINACCOUNTS","/SQLCOLLATION=$SQLCOLLATION",$STRSQLBACKUPDIR,$STRSQLTEMPDBDIR,$STRSQLTEMPDBLOGDIR,$STRSQLUSERDBDIR,$STRSQLUSERDBLOGDIR)

Write-Verbose "Install SQL $INSTANCENAME"
& .\setup.exe $allArguments

Import-Module "C:\Program Files (x86)\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS" -DisableNameChecking

$SQLQuery = "
DECLARE @numberCPU INT
DECLARE @maxMemory BIGINT = 131072
DECLARE @SQL NVARCHAR(MAX)
DECLARE @ParamDef NVARCHAR(MAX)
DECLARE @i AS INT = 1
DECLARE @tempDBName AS NVARCHAR(MAX)
DECLARE @tempDBNamePath AS NVARCHAR(MAX)
DECLARE @NoOfNUMA INT 
DECLARE @NoOfLogCPU INT
DECLARE @NoOfCPUPerNUMA INT

SET @numberCPU = (SELECT cpu_count FROM sys.dm_os_sys_info)
--SET @maxMemory =((SELECT physical_memory_kb FROM sys.dm_os_sys_info) / 1000) * 0.8

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
RECONFIGURE;"

Write-Verbose "Setting SQL $INSTANCENAME"
Invoke-Sqlcmd -ServerInstance ".\$INSTANCENAME" -query $SQLQuery

Write-Verbose "Setting static TCP port on SQL $INSTANCENAME"
($Wmi = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $env:COMPUTERNAME)
($uri = "ManagedComputer[@Name='$env:COMPUTERNAME']/ ServerInstance[@Name='$INSTANCENAME']/ServerProtocol[@Name='Tcp']")
($Tcp = $wmi.GetSmoObject($uri))
$wmi.GetSmoObject($uri + "/IPAddress[@Name='IPAll']").IPAddressProperties[0].Value=""
$wmi.GetSmoObject($uri + "/IPAddress[@Name='IPAll']").IPAddressProperties[1].Value="$TCPPORT"
$Tcp.Alter()

$ServiceName = "MSSQL$" + $INSTANCENAME
Write-Verbose "Restarting service $ServiceName"
Restart-Service -Name $ServiceName -Force

Get-Service -name "*TELEMETRY*" | Stop-Service -passthru | Set-Service -startmode disabled