# Assumes you have setup your profile correctly

New-AzureTrafficManagerProfile -Name "MusicStoreFoProfile" -DomainName "musicstore.trafficmanager.net" -LoadBalancingMethod Failover -Ttl 300 -MonitorProtocol Http -MonitorPort 80 -MonitorRelativePath "/"