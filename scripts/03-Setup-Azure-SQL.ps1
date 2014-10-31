#Import-Module Azure

# Helper Method from: https://github.com/guangyang/azure-powershell-samples/blob/master/create-azure-sql.ps1

# Create a PSCrendential object from plain text password.
# The PS Credential object will be used to create a database context, which will be used to create database.
Function New-PSCredentialFromPlainText
{
    Param(
        [String]$UserName,
        [String]$Password
    )

    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

    Return New-Object System.Management.Automation.PSCredential($UserName, $securePassword)
}
# End imported helpers

Function New-AzureSqlDatabaseWithFirewall
{
    Param(
        [String]$RegionName,
        [String]$UserName,
        [String]$Password,
        [String]$StartIPAddress,
        [String]$EndIPAddress,
        [Boolean]$IsPrimary
    )

    # Create Server
    $serverContext = New-AzureSqlDatabaseServer -Location $RegionName -AdministratorLogin $UserName -AdministratorLoginPassword $Password -Verbose

    # Setup Firewall Rules
    New-AzureSqlDatabaseServerFirewallRule -ServerName $serverContext.ServerName -RuleName "ScriptClientMachine" -StartIpAddress $StartIPAddress -EndIpAddress $EndIPAddress -Verbose | Out-Null 
    New-AzureSqlDatabaseServerFirewallRule -ServerName $serverContext.ServerName -RuleName "AllowAllAzureIP" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0" -Verbose | Out-Null 

    return $serverContext.ServerName
}

# ----------------------

# use a public IP lookup site to find out what your public IP address is
# this is required to setup firewall rules for Azure SQL Database
$myPublicIpAddress = "1.1.1.1"

If($myPublicIpAddress -eq "1.1.1.1")
{
    Write-Host
    Write-Host "ERROR: you must set your public IP address first in the script."
    Exit 1
}

$username = "demoadmin"
$password = "d3MO5Pec$!"
$databaseNames = @("MvcMusicStore", "aspnetdb")

# Set Server Instance in different Regions
$primaryServerName = New-AzureSqlDatabaseWithFirewall -RegionName "Australia East" -UserName $username -Password $password -StartIPAddress $myPublicIpAddress -EndIPAddress $myPublicIpAddress
$secondaryServerName = New-AzureSqlDatabaseWithFirewall -RegionName "Australia Southeast" -UserName $username -Password $password -StartIPAddress $myPublicIpAddress -EndIPAddress $myPublicIpAddress

# Provision each database and setup active read-only geo-replica
foreach ($db in $databaseNames) {
   
    # Create new empty database on Primary Server
    $credentials = New-PSCredentialFromPlainText -UserName $UserName -Password $Password   
    $serverIContext = New-AzureSqlDatabaseServerContext -ServerName $primaryServerName -Credential $credentials
    $priumaryDbContext = New-AzureSqlDatabase -ConnectionContext $serverIContext -DatabaseName $db -MaxSizeGB 1 -Collation "SQL_Latin1_General_CP1_CI_AS" -Edition Premium -Verbose

    # Starts the active geo-replication from primary server to secondary read-only replica
    Start-AzureSqlDatabaseCopy -ServerName $primaryServerName -DatabaseName $db -PartnerServer $secondaryServerName -ContinuousCopy
 }