# Check whether the user is already logged in - prompt if not
$context = Get-AzContext

if (!$context) 
{
    Connect-AzAccount 
} 

# Make sure the required modules are installed
$azInstalled = $(Get-InstalledModule | Where-Object {$_.name -eq 'Az'}).name
if (-not($azInstalled)) {
    Install-Module Az
}
Import-Module Az
$aadInstalled = $(Get-InstalledModule | Where-Object {$_.name -eq 'AzureAD'}).name
if (-not($aadInstalled)) {
    Install-Module AzureAd -Scope CurrentUser
}
Import-Module AzureAD

# Make sure you are in the correct Context - this should return your Azure Tenant
Get-AzContext

# Get the parameters needed to connect to AzureAD
$currContext = Get-AzContext
$tenantID = $CurrContext.Tenant.Id
$AccID = $currContext.Account.Id
$myAAD = Connect-AzureAD -TenantId $tenantID -AccountId $AccID

# Get the info to create the new users
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$domainName = $myAAD.TenantDomain
$pwdStr = Read-Host -Prompt 'Enter the password for the new Azure AD Users ' -AsSecureString
$PasswordProfile.Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwdStr))

# Create two new users, one new Group and add one user to the group
$User1 = New-AzureADUser -DisplayName "NDC User1" -PasswordProfile $PasswordProfile -UserPrincipalName "user1@$domainName" -AccountEnabled $true -MailNickName "user1" 
if ($User1.AccountEnabled) {
    Write-Host -ForegroundColor Yellow "NDC User1 created successfully"
}
$User2 = New-AzureADUser -DisplayName "NDC User2" -PasswordProfile $PasswordProfile -UserPrincipalName "user2@$domainName" -AccountEnabled $true -MailNickName "user2" 
if ($User2.AccountEnabled) {
    Write-Host -ForegroundColor Yellow "NDC User2 created successfully"
}
$group = New-AzureADGroup -DisplayName "SQLAdmins" -MailEnabled $false -SecurityEnabled $true -MailNickname "NotSet"
if ($group.ObjectId) {
    Write-Host -ForegroundColor Yellow "SQLAdmins created successfully"
}

# Update the owner to be your primary login 
$me = Read-Host -Prompt 'Enter the Display Name for YOUR login for Azure AD '
$owner = Get-AzureADUser -Filter "displayName eq '$me'"

Add-AzureADGroupOwner -ObjectId "$($group.ObjectId)" -RefObjectId "$($owner.ObjectId)"

# Finally add one of the users to the group along with yourself
Add-AzureADGroupMember -ObjectId "$($group.ObjectId)" -RefObjectId "$($owner.ObjectId)"
$user = Get-AzureADUser -Filter "displayName eq 'NDC User2'"
Add-AzureADGroupMember -ObjectId "$($group.ObjectId)" -RefObjectId "$($user.ObjectId)"

# Report the Group members
Get-AzureADGroupMember -ObjectID $group.ObjectId -All $true | Select-Object -Property @{N='Group Members';E={$_.DisplayName}}

