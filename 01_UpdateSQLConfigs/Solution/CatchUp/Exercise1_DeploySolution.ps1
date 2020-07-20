# Check whether the user is already logged in - prompt if not
$context = Get-AzContext

if (!$context) 
{
    Connect-AzAccount 
} 

# Make sure you are in the correct Context - this should return your Azure Tenant
Get-AzContext

# Make sure the required modules are installed
Install-Module AzureAD -Scope CurrentUser
Import-Module AzureAD

# Get the parameters needed to connect to AzureAD
$currContext = Get-AzContext
$tenantID = $CurrContext.Tenant.Id
$AccID = $currContext.Account.Id
$myAAD = Connect-AzureAD -TenantId $tenantID -AccountId $AccID

# Get the SQLAdmins Security Group ObjectId
$groupSID = $(Get-AzureADGroup -Filter "displayName eq 'SQLAdmins'").ObjectId

# Prompt for the parameters to use for the SQL Server and VMs
$randomiser = Read-Host -Prompt "Enter a 5 character string (lowercase letters and numbers) to ensure uniqueness of your SQL Server and VM "
$sqlName = Read-Host -Prompt "Enter the name of the SQL Server "
$sqlAdminUser = Read-Host -Prompt "Enter the admin account name for the SQL Server "
$sqlAdminPwd = Read-Host -Prompt "Enter the password for the SQL Server admin account " -AsSecureString
$vmName = Read-Host -Prompt "Enter the name of the VM "
$vmAdminUser = Read-Host -Prompt "Enter the admin account name for the VM "
$vmAdminPwd = Read-Host -Prompt "Enter the password for the VM admin account " -AsSecureString

# Set the paths to the ARM Template and Parameter files - they will be relative to this script file
$thisPath = $PSScriptRoot
$templateFile = "$thisPath\Exercise1_SolutionDeploy.json"
$templateParams = "$thisPath\Exercise1_SolutionDeployParams.json"

# Run the deployment
Write-Host -ForegroundColor Yellow $(Get-Date)
$rgName = 'NDC-Test'
New-AzResourceGroupDeployment -ResourceGroupName  $rgName -TemplateFile $templateFile -TemplateParameterFile $templateParams -sqlAdminLogin $sqlAdminUser -sqlAdminPassword $sqlAdminPwd -sqlServerName $sqlName -vmName $vmName -vmAdminLogin $vmAdminUser -vmAdminPassword $vmAdminPwd -randomiser $randomiser -adGroupSID $groupSID
Write-Host -ForegroundColor Yellow $(Get-Date)
