param([string]$File)
$fileList = $File -replace '(\[|\])' -split ',' | ForEach-Object { $_.trim() }
$storageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName -Verbose
$count = 0
$DeploymentScriptOutputs = @{}
foreach ($fileName in $fileList) {
    Write-Host "Copying $fileName to $env:StorageContainerName in $env:StorageAccountName."
    Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/mslearn-arm-deploymentscripts-sample/$fileName" -OutFile $fileName
    $blob = Set-AzStorageBlobContent -File $fileName -Container $env:StorageContainerName -Blob $fileName -Context $storageAccount.Context
    $DeploymentScriptOutputs[$fileName] = @{}
    $DeploymentScriptOutputs[$fileName]['Uri'] = $blob.ICloudBlob.Uri
    $DeploymentScriptOutputs[$fileName]['StorageUri'] = $blob.ICloudBlob.StorageUri
    $count++
}
Write-Host "Finished copying $count files."
