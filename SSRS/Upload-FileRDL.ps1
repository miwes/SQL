$reportServerUri = "http://sql/reportserver/ReportService2010.asmx?wsdl"
$rs = New-WebServiceProxy -Uri $reportServerUri -UseDefaultCredential -Namespace "SSRS"

$targetFolderPath = "/Výroba"
$warnings = $null
 
Get-ChildItem *.rdl | Foreach-Object {
    $reportName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
 
    Write-Output "Uploading report ""$reportName"" to ""$targetFolderPath""..."
    $report = $rs.CreateCatalogItem(
        "Report",         # Catalog item type
        $reportName,      # Report name
        $targetFolderPath,# Destination folder
        $true,            # Overwrite report if it exists?
        $bytes,           # .rdl file contents
        $null,            # Properties to set.
        [ref]$warnings)   # Warnings that occured while uploading.
 
    $warnings | ForEach-Object {
        Write-Output ("Warning: {0}" -f $_.Message)
    }
 
    $referencedDataSourceName = (@($rs.GetItemReferences($report.Path, "DataSource")))[0].Name

    <#
    $dataSource = New-Object SSRS.DataSource
    $dataSource.Name = $referencedDataSourceName      # Name as used when designing the Report
    $dataSource.Item = New-Object SSRS.DataSourceReference
    $dataSource.Item.Reference = $targetDatasourceRef # Path to the shared data source as it is deployed here.
    $rs.SetItemDataSources($report.Path, [SSRS.DataSource[]]$dataSource)
    #>
}