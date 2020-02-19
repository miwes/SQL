$reportServerUri = "http://sql/reportserver/ReportService2010.asmx?wsdl"
$rs = New-WebServiceProxy -Uri $reportServerUri -UseDefaultCredential -Namespace "SSRS"

$sourceFolderPath = "/Výroba"
$items = $rs.ListChildren($sourceFolderPath, $false)
$items | Where-Object { $_.TypeName -eq "Report" } | Foreach-Object {
    $filename = ("{0}.rdl" -f $_.Name)
 
    Write-Output ("Downloading ""{0}""..." -f $_.Path)
    $bytes = $rs.GetItemDefinition($_.Path)
    [System.IO.File]::WriteAllBytes("$pwd\$filename", $bytes)
}