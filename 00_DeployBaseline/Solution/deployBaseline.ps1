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
$templateFile = "$thisPath\BaselineDeploy.json"
$templateParams = "$thisPath\BaselineDeployParams.json"

# Get the current Client IP Address
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

# Run the deployment
Write-Host -ForegroundColor Yellow $(Get-Date)
$rgName = 'NDC-Test'
New-AzResourceGroupDeployment -ResourceGroupName  $rgName -TemplateFile $templateFile -TemplateParameterFile $templateParams -sqlAdminLogin $sqlAdminUser -sqlAdminPassword $sqlAdminPwd -sqlServerName $sqlName -vmName $vmName -vmAdminLogin $vmAdminUser -vmAdminPassword $vmAdminPwd -randomiser $randomiser -clientIP $myIP
Write-Host -ForegroundColor Yellow $(Get-Date)
