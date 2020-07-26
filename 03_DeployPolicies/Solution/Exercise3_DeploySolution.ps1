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

$adInstalled = $(Get-InstalledModule | Where-Object {$_.name -eq 'AzureAD'}).name
if (-not($adInstalled)) {
    Install-Module AzureAD -Scope CurrentUser
}
Import-Module AzureAD

# Get the parameters needed to connect to AzureAD
$currContext = Get-AzContext
$tenantID = $CurrContext.Tenant.Id
$AccID = $currContext.Account.Id
$myAAD = Connect-AzureAD -TenantId $tenantID -AccountId $AccID

# Get the SQLAdmins Security Group ObjectId
$groupSID = $(Get-AzureADGroup -Filter "displayName eq 'SQLAdmins'").ObjectId

# Get the current Client IP Address
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

# Set the paths to the supporting files - they will be relative to this script file
$thisPath = $PSScriptRoot
$policyDefinition = "$thisPath\Exercise3_DenyTLSVersionPolicy.json"
$policyParameters = "$thisPath\Exercise3_DenyTLSVersionParam.json"
$testSQLDeployment = "$thisPath\Exercise3_SQLDeploy.json"

# Prompt for the parameters to use for the SQL Server and VMs
Write-Host " "
Write-Host " "
$randomiser = Read-Host -Prompt "Enter a 5 character string (lowercase letters and numbers) to ensure uniqueness of your SQL Server. Make sure this is a new randomiser "
Write-Host " "
Write-Host " "
$sqlRG = Read-Host -Prompt "Enter the Resource Group name for the SQL Server (suggest NDC-DB) "
$sqlName = Read-Host -Prompt "Enter the name of the SQL Server "
$sqlAdminUser = Read-Host -Prompt "Enter the admin account name for the SQL Server "
$sqlAdminPwd = Read-Host -Prompt "Enter the password for the SQL Server admin account " -AsSecureString

# Set the variables for the Policy Name and Assignment Name
$assignmentName = 'NDC-DB-MinTls-1_2'
$definitionName = 'SQLServerMinTlsVersion'

# First, we will make sure that the Policy is not currently deployed
Write-Host -ForegroundColor Yellow "Checking whether a Policy with this name is already assigned ... "
$isAssigned = Get-AzPolicyAssignment -Name $assignmentName -Scope (Get-AzResourceGroup $sqlRG).ResourceId -ErrorAction SilentlyContinue
if ($isAssigned){
    Write-Host -ForegroundColor Yellow " ... assignment found - removing "
    Remove-AzPolicyAssignment -Id $isAssigned.ResourceId 
    Write-Host -ForegroundColor Yellow " ... complete "
} else {
    Write-Host -ForegroundColor Yellow " ... no assignment exists "
}
# Next check is whether the Policy defintion exists - again we remove it if so
Write-Host -ForegroundColor Yellow "Checking whether a Policy with this name is already defined ... "
$isDefined = Get-AzPolicyDefinition -Name $definitionName -ErrorAction SilentlyContinue
if ($isDefined){
    Write-Host -ForegroundColor Yellow " ... definition found - removing "
    Remove-AzPolicyDefinition -Id $isDefined.ResourceId -Force
    Write-Host -ForegroundColor Yellow " ... complete "
} else {
    Write-Host -ForegroundColor Yellow " ... no definition exists "
}
Write-Host " "
Write-Host " "

# Now we go ahead and create the Defintion an Assignement
Write-Host -ForegroundColor Yellow "Creating new Policy definition '$definitionName' ... "
$newPolicy = New-AzPolicyDefinition -Name $definitionName `
                                    -DisplayName 'Ensure that a suitable minimum TLS value is set for SQL Server' `
                                    -Description 'Allows us to specify the Minimum TLS version - currently either 1.1 or 1.2 and denys any SQL Server deployment that has a lower version' `
                                    -Policy $policyDefinition `
                                    -Parameter $policyParameters

Write-Host -ForegroundColor Yellow " ... complete "

# Get the two values to test - first the Minimum for the Policy then the actual for the Deployment
$1_1 = New-Object System.Management.Automation.Host.ChoiceDescription '1.&1', 'TLS Value: 1.1'
$1_2 = New-Object System.Management.Automation.Host.ChoiceDescription '1.&2', 'TLS Value: 1.1'
$tlsOptions = [System.Management.Automation.Host.ChoiceDescription[]]($1_1, $1_2)
$title = 'Minimum TLS Version for the Policy'
$message = 'Enter the choice for the Minimum Acceptable TLS Version in your subscription'
# Get the policy value
$result = $host.ui.PromptForChoice($title, $message, $tlsOptions, 0)
switch ($result)
{
    0 {$policyTLSValue = '1.1'}
    1 {$policyTLSValue = '1.2'}
}

# then the deployment choice
$title = 'TLS Version to attempt to Deploy'
$message = 'Enter the choice for the TLS Version for your deployment'
$result = $host.ui.PromptForChoice($title, $message, $tlsOptions, 0)
switch ($result)
{
    0 {$deployTLSValue = '1.1'}
    1 {$deployTLSValue = '1.2'}
}

# Assign the Policy with the appropriate Parameter value
Write-Host -ForegroundColor Yellow "Creating new Policy definition '$definitionName' using '$policyTLSValue' as the minimum ... "
$newPolicy = New-AzPolicyAssignment -Name $assignmentName -PolicyDefinition $newPolicy -Scope (Get-AzResourceGroup $sqlRG).ResourceId -PolicyParameterObject @{'minTlsVersion'=$policyTLSValue}
Write-Host -ForegroundColor Yellow " ... complete "

# Finally we want to test the Policy and ensure that our deployment is allowed or denied appropriately
Write-Host " "
Write-Host " "
if ($policyTLSValue -le $deployTLSValue) {
    Write-Host -ForegroundColor Magenta "Based on your choices for the Policy and Deployment, the deployment should succeed"
} else {
    Write-Host -ForegroundColor Magenta "Based on your choices for the Policy and Deployment, the deployment should be denied"
}
Write-Host -ForegroundColor Yellow "Starting deployment of SQL Server"
try{
    $sqlDeploy = New-AzResourceGroupDeployment  -ResourceGroupName  $sqlRG `
                                                -TemplateFile $testSQLDeployment `
                                                -sqlAdminLogin $sqlAdminUser `
                                                -sqlAdminPassword $sqlAdminPwd `
                                                -sqlServerName $sqlName `
                                                -randomiser $randomiser `
                                                -clientIP $myIP `
                                                -tlsVersion $deployTLSValue `
                                                -Mode Incremental `
                                                -Force `
                                                -ErrorAction Stop
}
catch {
    Write-Host $Error[0].Exception
}
if ($sqlDeploy.Outputs.sqlServerName.value) {
    Write-Host -ForegroundColor Yellow "SQL Server resources deployed with TLS Version $($sqlDeploy.outputs.tlsVersion.value)"
    Write-Host -ForegroundColor Yellow "******************************************************************************************"
    Write-Host -ForegroundColor Yellow $(Get-Date)
} else {
    Write-Host -ForegroundColor Red "Failed to deploy SQL Server resources. The deployment value '$deployTLSValue' must be at least $policyTLSValue"
    Write-Host -ForegroundColor Red "******************************************************************************************"
    Write-Host -ForegroundColor Red $(Get-Date)
}