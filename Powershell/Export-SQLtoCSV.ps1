<#
.SYNOPSIS 
    Export-SQLtoCSV
.DESCRIPTION 
.NOTES 
    Author      : Michal Weis
    Version     : 1.0

#>


[CmdletBinding()]
Param
(
        [Parameter(Mandatory= $False,ValueFromPipeline= $True)] 
        [string]$SQLServer = "WINDCADB"
       
        ,[Parameter(Mandatory= $False,ValueFromPipeline= $True)]
        [string]$DBName = 'MDB'

        ,[Parameter(Mandatory= $False,ValueFromPipeline= $True)]
        [string]$ExportFile = 'data.csv'

        ,[Parameter(Mandatory= $True,ValueFromPipeline= $True)]
        [string]$SQLQuery
)

Set-StrictMode -Version latest

Function New-SQLConnection {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string]$SQLServer

        ,[Parameter(Mandatory= $True,ValueFromPipeline= $True)] 
        [string]$DBName

	)

   Try {
        $ConnectionString = "Data Source=$SQLServer;Integrated Security=SSPI;Initial Catalog=$DBName"
        $Connection = New-Object System.Data.SqlClient.SQLConnection($ConnectionString)
        $Connection.Open()
        
        Return $Connection
        
    } Catch {
        Return -1
        Write-Warning $Error[0]
    }
}

Function Get-SQLQuery {
    [CmdletBinding()]
	param(
        [Parameter(Mandatory= $True,ValueFromPipeline= $True)] 
        [object]$SQLConnection

        ,[Parameter(Mandatory= $True,ValueFromPipeline= $True)] 
        [string]$SQLQuery
    )

    Try {
        $Command = New-Object system.data.sqlclient.sqlcommand
        $Command.Connection = $SQLConnection
        $Command.CommandText = $SQLQuery
        $Result = $Command.ExecuteReader()
        
        $Datatable = New-Object System.Data.DataTable
        [void]$Datatable.Load($Result) 
        
        $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $Command
        $Dataset = New-Object System.Data.Dataset
        [void]$DataAdapter.Fill($Dataset)
    
        Return $Dataset.Tables[0]
    } Catch {
        Write-Warning $Error[0]
        Return -1
    }
}

Function Close-SQLConnection {
    [CmdletBinding()]
	param(
        [Parameter(Mandatory= $True,ValueFromPipeline= $True)] 
        [object]$SQLConnection
    )

    Try {
        $SQLConnection.close()
    } Catch {
        Write-Warning $Error[0]
    }
}

$Error.Clear()    
Write-Verbose "Start $(Get-Date)"
Write-Verbose "Connect to SQL $SQLServer"

$SQLConnection = New-SQLConnection -SQLServer $SQLServer -DBName $DBName
If ($SQLConnection -eq -1) {
    Write-Warning "Cannot connect to SQL $SQLServer : $Error[0]"
    Write-Verbose "End $(Get-Date)";
    Exit
}

Try {
    Write-Verbose 'Run query'
    $Result = Get-SQLQuery -SQLConnection $SQLConnection -SQLQuery $SQLQuery
    Close-SQLConnection -SQLConnection $SQLConnection
    If ($Result -eq -1) {
        Write-Verbose "End $(Get-Date)"
        Exit
    }

} Catch {
    Write-Warning "Error in invoke-SQLCMD : $Error[0]"
    Exit
}
Write-Verbose "Convert data to CSV > $ExportFile"
$Result | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | % {$_ -replace '"', ""} | Out-File ($ExportFile) -Force -Encoding UTF8 
Write-Verbose "End $(Get-Date)"