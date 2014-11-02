if($args.Count -eq 0)
{
    Write-Host "ERROR: you must supply a unique traffic manager DNS prefix"
    Exit 1
}

$tmDomain = "{0}.trafficmanager.net" -f $args[0]

$trafficManProfile = New-AzureTrafficManagerProfile -Name "MusicStoreFoProfile" -DomainName $tmDomain -LoadBalancingMethod Failover -Ttl 300 -MonitorProtocol Http -MonitorPort 80 -MonitorRelativePath "/"

# these hostnames will need to be updated to match your actual ones.
$trafficManProfile = Add-AzureTrafficManagerEndpoint -TrafficManagerProfile $trafficManProfile -DomainName "dmmswaustraliaeast.cloudapp.net" -Status Enabled -Type CloudService
$trafficManProfile = Add-AzureTrafficManagerEndpoint -TrafficManagerProfile $trafficManProfile -DomainName "dmmswaustraliasoutheast.cloudapp.net" -Status Enabled -Type CloudService

Set-AzureTrafficManagerProfile –TrafficManagerProfile $trafficManProfile