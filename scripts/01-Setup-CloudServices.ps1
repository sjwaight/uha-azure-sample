
# Setup Affinity Groups in our two target Regions (could be any two Azure Regions)

Function New-DeploymentRegion($regionName)
{
    $affinityGroupName = "MsW" + $regionName.Replace(" ", "")
    $affinityLabel = "Music Store Web " + $regionName
    $affinityDescription = "Affinity group for Music Store in " + $regionName + " Region."

    Write-Host "Creating Affinity Group: " + $affinityGroupName

    New-AzureAffinityGroup -Name $affinityGroupName -Location $regionName -Label $affinityLabel -Description $affinityDescription

    #####
    # Setup Storage for Deployment
    #####

    $storageAccountName = "MusicStoreDemo" + $affinityGroupName
    
    Write-Host "Creating Storage Account: " + $storageAccountName
        
    New-AzureStorageAccount -StorageAccountName $storageAccountName -Label $storageAccountName -AffinityGroup $affinityGroupName

    $storageKey = Get-AzureStorageKey -StorageAccountName $storageAccountName
    $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey.Primary

    New-AzureStorageContainer -Context $storageContext -Container "deployments"

    ####
    # Setup Cloud Service
    ####

    $cloudServiceName = "MusicStoreWeb" + $affinityGroupName

    New-AzureService -Service $cloudServiceName -AffinityGroup $affinityGroupName
}


New-DeploymentRegion("Australia East")
New-DeploymentRegion("Australia Southeast")