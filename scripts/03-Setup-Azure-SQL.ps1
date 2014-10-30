# Requires that you have SQL Server 2012 installed
Import-Module sqlps

# Helper Methods from: https://github.com/guangyang/azure-powershell-samples/blob/master/create-azure-sql.ps1

# Get the IP Range needed to be whitelisted for SQL Azure
Function Detect-IPAddress
{
    $ipregex = "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    $text = Invoke-RestMethod 'http://www.whatismyip.com/api/wimi.php'
    $result = $null

    If($text -match $ipregex)
    {
        $ipaddress = $matches[0]
        $ipparts = $ipaddress.Split('.')
        $ipparts[3] = 0
        $startip = [string]::Join('.',$ipparts)
        $ipparts[3] = 255
        $endip = [string]::Join('.',$ipparts)

        $result = @{StartIPAddress = $startip; EndIPAddress = $endip}
    }

    Return $result
}


# Generate connection string of a given SQL Azure database
Function Get-SQLAzureDatabaseConnectionString
{
    Param(
        [String]$DatabaseServerName,
        [String]$DatabaseName,
        [String]$UserName,
        [String]$Password
    )

    Return "Server=tcp:{0}.database.windows.net,1433;Database={1};User ID={2}@{0};Password={3};Trusted_Connection=False;Encrypt=True;Connection Timeout=30;" -f
        $DatabaseServerName, $DatabaseName, $UserName, $Password
}

# End Helpers

Function New-AzureSqlDatabaseWithFirewall
{
    Param(
        [String]$AzureLocation,
        [String]$UserName,
        [String]$Password,
        [String]$StartIPAddress,
        [String]$EndIPAddress
    )

    $serverContext = New-AzureSqlDatabaseServer -Location $AzureLocation -AdministratorLogin $UserName -AdministratorLoginPassword $Password

    New-AzureSqlDatabaseServerFirewallRule -ServerName $serverContext.ServerName -RuleName "ScriptClientMachine" -StartIpAddress $StartIPAddress -EndIpAddress $EndIPAddress -Verbose
    New-AzureSqlDatabaseServerFirewallRule -ServerName $serverContext.ServerName -RuleName "AllowAllAzureIP" -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0" -Verbose

    return $serverContext
}

$ipRange = Detect-IPAddress
$startIPAddress = $ipRange.StartIPAddress
$endIPAddress = $ipRange.EndIPAddress

$username = "demoadmin"
$password = "d3MO5Pec$!"
$databasName = "MvcMusicStore"

$primaryServerContext = New-AzureSqlDatabaseWithFirewall -AzureLocation "Australia East" -UserNamer $username -Password $password -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress
#$secondaryServerContext = New-AzureSqlDatabaseWithFirewall -AzureLocation "Australia Southeast" -UserNamer $username -Password $password -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress

$priumaryDbContext = New-AzureSqlDatabase -ConnectionContext $primaryContext -DatabaseName $databasName -MaxSizeGB 1 -Collation "SQL_Latin1_General_CP1_CI_AS" -Edition Basic

$sqlCmdConnection = "{0}@{1}.database.windows.net" -f $username, $primaryServerContext.ServerName

Invoke-Sqlcmd -InputFile "..\web-app-tier\MvcMusicStore-Create.sql" -ServerInstance $sqlCmdConnection