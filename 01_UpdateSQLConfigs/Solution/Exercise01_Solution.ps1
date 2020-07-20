# Check whether the user is already logged in - prompt if not
$context = Get-AzContext

if (!$context) 
{
    Connect-AzAccount 
} 

# Make sure you are in the correct Context - this should return your Azure Tenant
Get-AzContext

# Make sure the required modules are installed
$azInstalled = $(Get-InstalledModule | Where-Object {$_.name -eq 'Az'}).name
if (-not($azInstalled)) {
    Install-Module Az
}
Import-Module Az

# Prompt for the ServerName that we want to alter 
$uniquifier = Read-Host -Prompt "Enter the 5 character uniquifier that was used for creating your resources "
$sqlServer = "$(Read-Host -Prompt 'Enter the SQL Server name (without uniquifier extension)')-$uniquifier"

# Add an Azure AD Administrator to the SQL Server
## We need the following:
##     Is there an Administrator set alreaady? If so then skip
##     Add our default SQLAdmins AAD Group as the Administrator and confirm
try {
    $aadAdmin = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName NDC-Test -ServerName $sqlServer
    if ($aadAdmin.DisplayName) {
        Write-Host -ForegroundColor Magenta 'Azure AD Administrator already exists'
    } else {
        Write-Host -ForegroundColor Yellow "Setting Azure Active Directory Administrator to 'SQLAdmins' for SQL Server '$sqlServer'"
        $aadAdmin = Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName NDC-Test -ServerName $sqlServer -DisplayName 'SQLAdmins' 
        Write-Host -ForegroundColor Yellow "'$($aadAdmin.DisplayName)' is now an Administrator of '$sqlServer'"
    }
} catch {
    throw "$($_.Exception.InnerException.Message)"
}

# Add a Virtual Network Service Endpoint Firewall Rule to our SQL server
## We need the following:
##     Is there a Firewall Rule set alreaady? If so then skip
##     Add our NDC-VirtualNetwork/Client-Subnet and confirm
##     Remove all of the regular Firewall Rules
##     Remove the permission for Access from All Azure services
try{
    $vnetRule = Get-AzSqlServerVirtualNetworkRule -ResourceGroupName NDC-Test -ServerName $sqlServer
    if ($vnetRule) {
        $subNet = Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetRule.VirtualNetworkSubnetId
        Write-Host -ForegroundColor Magenta "Virtual Network Firewall Rule for the Subnet '$($subNet.Name) : $($subNet.AddressPrefix)' already exists"
    } else {
        Write-Host -ForegroundColor Yellow "Setting Virtual Network Firewall Rule for 'NDC-VirtualNetwork/Client-Subnet' for SQL Server '$sqlServer'"
        # Get the ID value for the Client-Subnet in the NDC-VirtualNetwork
        $netID = Get-AzVirtualNetwork -ResourceGroupName NDC-Test -Name NDC-VirtualNetwork
        $subnetID = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $netID -Name 'Client-Subnet'
        $vnetRule = New-AzSqlServerVirtualNetworkRule -ResourceGroupName NDC-Test -ServerName $sqlServer -VirtualNetworkRuleName 'Client-SubnetToSQL' -VirtualNetworkSubnetId $subnetID.Id -IgnoreMissingVnetServiceEndpoint
        Write-Host -ForegroundColor Yellow "Subnet '$($subnetID.Name) : $($subnetID.AddressPrefix)' is now permitted access to '$sqlServer'"
    }
    # Check for remaining IP Firewall Rules
    $IPRules = Get-AzSqlServerFirewallRule -ResourceGroupName NDC-Test -ServerName $sqlServer
    if ($IPRules) {
        Write-Host -ForegroundColor Yellow "Removing any IP Firewall Rules from SQL Server '$sqlServer', including 'Allow All Windows Azure IPs"
        Get-AzSqlServerFirewallRule -ResourceGroupName NDC-Test -ServerName $sqlServer | Remove-AzSqlServerFirewallRule 
    } else {
        Write-Host -ForegroundColor Magenta "All IP Firewall Rules have already been removed from SQL Server '$sqlServer', including 'Allow All Windows Azure IPs"
    }
} catch {
    throw "$($_.Exception.InnerException.Message)"
}

# Update the Virtual Network Subnet to have a Service Endpoint definition for Microsoft.Sql in our Azure Region
## We need the following:
##     Check whether the Subnet listed as a Virtual Network Firewall has a Service Endpopint for Microsoft.Sql in this region
##     If not then add this to the Subnet defintion
try {
    $serverLocation = $(Get-AzSqlServer -ResourceGroupName NDC-Test -ServerName $sqlServer).Location
    $vnetFWRule = $(Get-AzSqlServerVirtualNetworkRule -ResourceGroupName NDC-Test -ServerName $sqlServer).VirtualNetworkSubnetId
    $endpoints = $(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).ServiceEndpoints
    $validLocation = ''
    # If there are no endpoints or if there is no Microsoft.Sql to the SQL Server's region then create one
    if ($endpoints) {
        $endPointSet = $false
        $endPoints | Foreach-Object {
            Write-Host "Checking $($_.Service) in $($_.Locations)"
            if (($_.Service -eq 'Microsoft.Sql') -and (($_.Locations -eq '*') -or ($_.Locations -contains "$serverLocation"))) {
                $validLocation = $($_.Locations)
                $endPointSet = $true
            } 
        }
    }
    if ((-not($endPoints) ) -or (-not($endPointSet))) {
        Write-Host -ForegroundColor Yellow "Adding a Service Endpoint for 'Microsoft.Sql' to Subnet '$(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).Name' for Location '$serverLocation'"
        $ServiceEndPoints = New-Object 'System.Collections.Generic.List[Microsoft.Azure.Commands.Network.Models.PSServiceEndpoint]'
        $ServiceEndPoint = [Microsoft.Azure.Commands.Network.Models.PSServiceEndpoint]::new()
        $ServiceEndPoint.Service = "Microsoft.Sql"
        $ServiceEndPoint.Locations = @("$serverLocation")
        $ServiceEndPoints.Add($ServiceEndPoint)
        # Retain the existing Service Endpoints, if any
        $ServiceEndPoints += $endpoints

        # The following command is the way that it "should" now be set, but this has a long-standing issue (see link in instructions)
        ### Set-AzVirtualNetworkSubnetConfig -VirtualNetwork NDC-VirtualNetwork -Name $(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).Name -AddressPrefix $(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).AddressPrefix -ServiceEndpoint $ServiceEndPoints

        # So the workaround is to set it at a higher level - the Virtual Network.
        ## We now have to get a reference to the Virtual Network
        $vnet = Get-AzVirtualNetwork -ResourceGroupName NDC-Test -Name NDC-VirtualNetwork
        ## Now we update the Subnet through the Virtual Network
        $vnet.Subnets.Where({$_.Name -eq "$($(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).Name)"})[0].serviceEndpoints = $ServiceEndPoints
        ## Finally, update the Virtual Network
        $done = Set-AzVirtualNetwork -VirtualNetwork $vnet 

        Write-Host -ForegroundColor Yellow "Subnet '$(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).Name' is enabled for Service Endpoint connections for 'Microsoft.Sql' to Location '$serverLocation'"
    } else {
        Write-Host -ForegroundColor Magenta "Subnet '$(Get-AzVirtualNetworkSubnetConfig -ResourceId $vnetFWRule).Name' is already configured for 'Microsoft.Sql' to '$validLocation'"
    }
} catch {
    throw "$($_.Exception.InnerException.Message)"
}
