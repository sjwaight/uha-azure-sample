Function New-AzureCloudServiceDeployment
{
 Param(
        [String]$RegionName,
        [String]$DeploymentPathPackage, 
        [String]$DeploymentPathConfig
    )

    if (((Test-Path $DeploymentPathPackage) -eq $False) -or ((Test-Path $DeploymentPathConfig) -eq $False))
    {
        Write-Host "Deployment package and / or config do not exist at the supplied locations."
        Exit 1
    }

    $affinityGroupName = "MsW{0}" -f $RegionName.Replace(" ", "")
    $cloudServiceName = "dm{0}"-f $affinityGroupName

    # Build package blob storage filename
    $dateStamp = Get-Date -Format s
    $packageFile = Split-Path $DeploymentPathPackage -Leaf -Resolve
    $packageBlobFile = "{0}-{1}" -f $dateStamp, $packageFile

    $configFile = Split-Path $DeploymentPathConfig -Leaf -Resolve

    $storageAccountName = "md{0}" -f $affinityGroupName.ToLower()
    $accountContainer = "deployments"

    $storageKey = Get-AzureStorageKey -StorageAccountName $storageAccountName
    $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey.Primary
    
    $containerState = Get-AzureStorageContainer -Context $storageContext -Name "deployments" -ea 0

    # Upload deployment package - this step may take some time depending on latency to Azure Blob Storage.
    $deployPackage = Set-AzureStorageBlobContent -File $DeploymentPathPackage -CloudBlobContainer $containerState.CloudBlobContainer -Context $storageContext  -Blob $packageBlobFile -Force
    
    # Get Blob details so we can extract the URI for the deployment.
    $deployBlob = Get-AzureStorageBlob -blob $packageFile -Container $containerState.CloudBlobContainer.Name -Context $storageContext

    # deployment to an empty slot only – use Set-AzureDeployment instead to upgrade a slot
    New-AzureDeployment -Slot "Production" -Package $deployBlob.ICloudBlob.Uri.AbsoluteUri –Configuration $DeploymentPathConfig -ServiceName $cloudServiceName
}

#-----------------------------------------------------

$rootPath = "C:\Work\uha-azure-sample\web-app-tier"

If($rootPath -eq "C:\Work\uha-azure-sample\web-app-tier")
{
    Write-Host
    Write-Host "ERROR: you must set your root project path."
    Exit 1
}

$eastProjectName = "MvcMusicStoreAUEast"
$southEastProjectName = "MvcMusicStoreAUSoutheast"

$fullDeploymentPathEast = "{0}\MvcMusicStore.Azure\bin\{1}\app.publish\MvcMusicStore.Azure.cspkg" -f $rootPath, $eastProjectName
$fullConfigPathEast = "{0}\MvcMusicStore.Azure\bin\{1}\app.publish\ServiceConfiguration.Cloud.cscfg" -f $rootPath, $eastProjectName
$fullDeploymentPathSouthEast = "{0}\MvcMusicStore.Azure\bin\{1}\app.publish\MvcMusicStore.Azure.cspkg" -f $rootPath, $southEastProjectName
$fullConfigPathSouthEast = "{0}\MvcMusicStore.Azure\bin\{1}\app.publish\ServiceConfiguration.Cloud.cscfg" -f $rootPath, $southEastProjectName

New-AzureCloudServiceDeployment -RegionName "Australia East" -DeploymentPathPackage $fullDeploymentPathEast -DeploymentPathConfig $fullConfigPathEast
New-AzureCloudServiceDeployment -RegionName "Australia Southeast" -DeploymentPathPackage $fullDeploymentPathSouthEast -DeploymentPathConfig $fullConfigPathSouthEast