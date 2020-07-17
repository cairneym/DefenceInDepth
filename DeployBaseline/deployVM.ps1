# First ensure tour Azure account is connected
#Connect-AzAccount

# Now Prompt for the parameters to use
$adminUser = Read-Host -Prompt "Enter the admin account name for the VM "
$adminPwd = Read-Host -Prompt "Enter the password for the admin account " -AsSecureString
$vmName = Read-Host -Prompt "Enter the name of the VM "
$rgName = Read-Host -Prompt "Enter the Resource Group Name for this deployment "
$templateFile = "C:\Users\marti\OneDrive\MyCloudDocuments\SQL and Community\Presentations\Workshop= Defence in Depth - Securing your Data in Azure SQL Database\Deployments\DeployBaseline\AzureVMDeploy.json"
$templateParams = "C:\Users\marti\OneDrive\MyCloudDocuments\SQL and Community\Presentations\Workshop= Defence in Depth - Securing your Data in Azure SQL Database\Deployments\DeployBaseline\AzureVMDeployParams.json"

# Run the deployment
New-AzResourceGroupDeployment -ResourceGroupName  $rgName -TemplateFile $templateFile -TemplateParameterFile $templateParams -adminPassword $adminPwd -vmName $vmName -adminUser $adminUser
 