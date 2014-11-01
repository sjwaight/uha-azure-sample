Function New-DeploymentRegion($regionName)
{
    ####
    # Affinity Group
    ####

    $affinityGroupName = "MsW{0}" -f $regionName.Replace(" ", "")

    $existingGroup = Get-AzureAffinityGroup -Name $affinityGroupName -ErrorAction SilentlyContinue

    if($existingGroup -eq $null)
    {
        $affinityLabel = "Music Store Web {0}" -f $regionName
        $affinityDescription = "Affinity group for Music Store in {0} Region." -f $regionName

        Write-Host "Creating Affinity Group: $affinityGroupName"

        New-AzureAffinityGroup -Name $affinityGroupName -Location $regionName -Label $affinityLabel -Description $affinityDescription
    }
    else
    {
        Write-Host "Using existing Affinity Group: $affinityGroupName"
    }

    #####
    # Setup Storage for Deployment
    #####

    $storageAccountName = "md{0}" -f $affinityGroupName.ToLower()
    $accountContainer = "deployments"
    
    $exitstingStorage = Get-AzureStorageAccount -StorageAccountName $storageAccountName -ErrorAction SilentlyContinue

    if($existingStorage -eq $null)
    {
        Write-Host "Creating Storage Account: $storageAccountName"
        New-AzureStorageAccount -StorageAccountName $storageAccountName -Label $storageAccountName -AffinityGroup $affinityGroupName
    }
    else
    {
        Write-Host "Using existing Storage Account: $storageAccountName"
    }

    #####
    # Setup Container in Storage Account for Deployment
    #####

    $storageKey = Get-AzureStorageKey -StorageAccountName $storageAccountName
    $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey.Primary

    $existingContainer = Get-AzureStorageContainer -Context $storageContext -Name $accountContainer -ErrorAction SilentlyContinue

    if($existingContainer -eq $null)
    {
        New-AzureStorageContainer -Context $storageContext -Container $accountContainer
    }
    else
    {
       Write-Host "Using existing Storage Container: $accountContainer"
    }

    ####
    # Setup Cloud Service
    ####

    $cloudServiceName = "MusicStoreWeb{0}"-f $affinityGroupName

    $existingService = Get-AzureService -ServiceName $cloudServiceName -ErrorAction SilentlyContinue

    if($existingService -eq $null)
    {
        New-AzureService -Service $cloudServiceName -AffinityGroup $affinityGroupName
    }
    else
    {
        Write-Host "Cloud Service with name $cloudServiceName already exists"
    }
}

#-----------------------------------------------------

New-DeploymentRegion("West US")
#New-DeploymentRegion("Australia Southeast")