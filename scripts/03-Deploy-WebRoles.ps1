
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

    $packageFile = Split-Path $DeploymentPathPackage -Leaf -Resolve
    $configFile = Split-Path $DeploymentPathConfig -Leaf -Resolve

    $affinityGroupName = "MsW{0}" -f $RegionName.Replace(" ", "")

    $storageAccountName = "md{0}" -f $affinityGroupName.ToLower()
    $accountContainer = "deployments"

    $storageKey = Get-AzureStorageKey -StorageAccountName $storageAccountName
    $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey.Primary
    
    $containerState = Get-AzureStorageContainer -Context $storageContext -Name "deployments" -ea 0

    # This step may take some time depending on latency to Azure.
    #$deployPackage = Set-AzureStorageBlobContent -File $DeploymentPathPackage -CloudBlobContainer $containerState.CloudBlobContainer -Context $storageContext  -Blob $packageFile
    $deployConfig = Set-AzureStorageBlobContent -File $DeploymentPathConfig -CloudBlobContainer $containerState.CloudBlobContainer -Context $storageContext  -Blob $configFile

    #$deployBlob = Get-AzureStorageBlob -blob $packageFile -Container $containerState.CloudBlobContainer.Name -Context $storageContext
    $configBlob = Get-AzureStorageBlob -blob $configFile -Container $containerState.CloudBlobContainer.Name -Context $storageContext

    # deployment to an empty slot only – use Set-AzureDeployment below to upgrade a slot
    #New-AzureDeployment -Slot "Production" -Package $deployBlob.ICloudBlob.Uri.AbsoluteUri –Configuration $configBlob.ICloudBlob.Uri.AbsoluteUri -ServiceName "testweb" 
    #Get-AzureDeployment -ServiceName "iPowerAU-Web" -Slot "Staging"
}

$rootPath = "C:\Work\uha-azure-sample\"
$eastProjectName = "MvcMusicStoreAUEast"
$southEastProjectName =""

If($rootPath -eq "C:\Work\uha-azure-sample\"
)
{
    Write-Host
    Write-Host "ERROR: you must set your root project path."
    Exit 1
}

New-AzureCloudServiceDeployment -RegionName "West US" -DeploymentPathPackage "C:\Work\uha-azure-sample\web-app-tier\MvcMusicStore.Azure\bin\MvcMusicStoreAUEast\app.publish\MvcMusicStore.Azure.cspkg" -DeploymentPathConfig "C:\Work\uha-azure-sample\web-app-tier\MvcMusicStore.Azure\bin\MvcMusicStoreAUEast\app.publish\ServiceConfiguration.Cloud.cscfg"