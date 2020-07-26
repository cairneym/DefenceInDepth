# DefenceInDepth
Full day session on Securing your Azure SQL Database


## Exercise 1 : Locking Down Access

The SQL Server and Database deployed as a Baseline is immediately less secure than it could be. In this exercise, we will start to harden the deployment in line with the areas we have covered in the Speaker's Tutorial.

This deployment has opened up Public Firewall access to your workstation and also has enabled access from ALL Azure services. We want to remove explicitly enabled Firewall Rules, but still enable the VM that we deployed in the Baseline to have access to the SQL Server.

We also only have the *Server Admin* available to login and manage the resource. We want to aloow our *SQLAdmins* Azure Active Directory group to be administrators as well. At this stage, only admins will be permitted to connect, therefore our *NDC User1* Azure Active Directory user should not be able to connect.

### Tasks

Update your current deployment programmatically (PowerShell, ARM Template, Azure CLI) to do the following tasks:

**1.** Add an Azure Active Directory Administrator to the SQL Server. Set this to the *SQLAdmins* Group from your Azure Active Directory.  
**2.** Add a Virtual Network firewall rule to your SQL Server. This should add the Client-Subnet from your Virtual Network and initially tell it to *Ignore the missing Endpoint*.  
**3.** Change the setting for Allowing access from Azure services and resources and also remove the Firewall Rule for your Client IP Address.  
**4.** Update the Virtual Network to enable a Service Endpoint for SQL Server on the Client-Subnet. Make sure that the Service Endpoint is restricted to only the Azure Region where your Resources are deployed.  
**5.** Add Resource Locks for both the SQL Server and the VM to prevent accidental deletion.


#### Verification

To verify your deployment, first use SQL Server Management Studio or Azure Data Studio on your own computer and attempt to connect to the database using the same connection string as the Baseline verification used.  Confirm that you get denied.

Next, connect to your VM using RDP as per the Baseline verification. Attempt to connect using SSMS and using the *SQL Admin* login and password as before. Confirm that you are still able to connect using this method.

Next, you will need to login to the Azure Portal *https://portal.azure.com* as each of the Azure Active Directory users and set a new password. This is an Azure AD requirement where the password needs to be changed at first login to fully enable the accounts. If you do not do this then you will likely see an error like ***AADSTS50055: The password is expired.*** when you try to connect to SQL. 

Next, run SSMS from the VM and connect to your SQL Server using the connection string in the format ***\<your database mame\>.database.windows.net***. Use *SQL Server Authentication* and enter the Administrator credentials at the *User name* and *Password* boxes. You should be able to connect OK confirming that the VNET Service Endpoint is working.

Next, attempt to connect with the first user, ***user1@\<your domain name\>.onmicrosoft.com***. Use *Azure Active Directory - Password* and enter the new *Password* for this user. You should receive the message ***AADSTS50126: Error validating credentials due to invalid username or password.*** confirming that this user is not a member of the *SQLAdmins* Group and as we have not granted specific access to any database, it is not authorised.

Finally, connect with the second user, ***user2@\<your domain name\>.onmicrosoft.com***. Again, use *Azure Active Directory - Password* and enter the new password for this user. This one should connect successfully, confirming that the Azure Active Directory Adminisstrators for your SQL Server are working as expected.


#### References

[Active Directory Administrators](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-overview)  
[Virtual Network Service Endpoints](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)  
[Azure SQL Server IP Firewalls](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure)  
[Azure Resource Locks](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/lock-resources)  
[Azure AD Authentication](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-overview)  
[Issue with setting Service Endpoints with Workaround](https://github.com/Azure/azure-powershell/issues/8735)  
[ARM Templates do not remove Server IP Firewall Rules](https://social.msdn.microsoft.com/Forums/sqlserver/en-US/9de3ed38-351f-418f-a2fa-c43ca102906f/server-level-firewall-rules-not-being-removed-when-arm-template-is-updated?forum=ssdsgetstarted)  

#### Sample Solution

A sample PowerShell script to implement this is included in the **Solution** subdirectory of this section.


#### Catch Up

If you need to get to this stage directly, there is an ARM Template and script file in the **Solution\CatchUp** subdirectory of this section. This script will deploy to the current Resource Groups and will try to delete any respurces that don;t appear in the Template. Note however that some resources cannot be deleted even if they are no longer defined in the Template - these are know as *Proxy Resources*. SQL Server IP Firewall Rules are one such resources an so there is an extra PowerShell script command to remove these before applying the Template.