# DefenceInDepth
Full day session on Securing your Azure SQL Database


## Exercise 3 : Azure Policies and Role Based Access Control

We now have a pretty robust Template that we can make use of for our Azure SQL Database deployments which doesn't unneccesarily expose our servers to prying eyes. However, it is never going to be the only way that we deploy Azure SQL Database in our subscriptions. What other tools are at our disposal to ensure that our hard work in defining our Template isn't wasted through one inadequate deployment?

***Azure Policies*** allow us to further control *what* can be deployed into our subscriptions with the option to either **deny** or **correct** any non-compliant ones. We can also get an ongoing Health Check of all of our SQL Servers to ensure that they are staying compliant with our well crafted Template design.

The other major benefit of Azure Policies is that it can assess compliance at large scale since it considers the *infrastructure as code* design of our environment and looks for patterns in the JSON defintions at the selected scope. Just think how m,uch easier it is to query several thousand JSON documents to confirm a specific patterns in a property compared to having to run a T-SQL query against all those instances and databases. I have seen company's with several hundred thousands of databases where a basic query against each one could take a full day to complete!

In addition to the *Azure Policies* that check for out-of-compliance instances, *RBAC Roles* can ensure that only approved actors are able to perform certain actions in the subscription. We have already seen an example of applying a RBAC Role, where we limited the access to the Storage Accounts to only the SQL Server identity. As well as access controls though, *RBAC Roles* can also allow or deny activities such as who is permitted to deploy a new Azure SQL Database.


### Tasks

Update your current deployment programmatically (PowerShell, ARM Template, Azure CLI) to do the following tasks:

**1.** Create 2 new Storage Accounts in the same Azure Region as your SQL Server. These can be any level of redundancy and performance that you choose, but should be *StorageV2* accounts. Restrict public access and ensure a suitable TLS version for the traffic. Each Storage Account must be configured to ***Allow trusted Microsoft services to access this storage account***.      
**2.** Ensure that your SQL Server has a *System Managed* identity within Azure. This can then be granted the ***Storage Blob Data Contributor*** RBAC role in each of the Storage Accounts that you created.  
**3.** Configure *Auditing* for ALL databases on your SQL Server and direct them to your first Storage Account. Ensure that a suitable retention setting is defined for the Audit Logs (suggestion is 180 days).  
**4.** Configure *Advanced Data Security* to save the Vulnerability Scans to the second Storage Account. Ensure that periodic scan are enabled and that appropriate notifications are in place. ***NOTE*** there appears to be a bug with the PowerShell cmdlet *Update-AzSqlServerVulnerabilityAssessmentSetting* and so you may need to configure part of this in the Azure Portal.     
**5.** Start an on-demand Vulnerability Assessment for the ***AdventureWorksLT*** database.  
**6.** Add Resource Locks for both Storage Accounts to prevent accidental deletion.  
**7.** Update the SQL Server connectivity to include a Private Endpoint located in the *Client-Subnet*. Once created, remove the VNET Firewall and also deny Public Access to the SQL Server.  


#### Verification

To verify your deployment, first use SQL Server Management Studio or Azure Data Studio on your own computer and attempt to connect to the database using the same connection string as used for the Baseline verification.  Confirm that you get denied and informed to connect via the Private Endpoint.

Next, connect to your VM using RDP as per the Baseline verification. Attempt to connect using SSMS with *SQL Server Authentication* using the *SQL Admin* login and password as before. Confirm that you are still able to connect using this method.

Next, navigate to the ***AdventureWorksLT*** database in the Azure Portal. From the Auditing blade, select *View Audit Logs* and confirm that some *Server Audit* records exist. The *Database Audit* logs should be empty as we have configured the Audits at the Server level and not the Database level.

Next, go back to SQL Server Management Studio and open a Query Window connected to either *master* or to *AdventureWorksLT* and execute the query:  
```
SELECT TOP(50) *   
FROM sys.fn_get_audit_file ('https://<your audit storage account name>.blob.core.windows.net/sqldbauditlogs/<your SQL Server name>/AdventureWorksLT/',default,default);
```  
Ensure that there is a correlation in the events between the query and the portal based on the *Event Time* and the *Event Type*. You will have to translate the *Event Type* between the full and abbreviated text in each location.    

Next, browse to the *sqldbauditlogs* container in the Auditing *Storage Account*. Confirm that you do not have access to the container. Repeat this for the *vulnerability-assessment* container in the other *Storage Account*.

Finally, to be able to see the *Vulnerability Assessments* for the databases, we need to make a further change. Add a further *Firewall Rule* for the Vulnerability Scan *Storage Account* to allow the *Client-Subnet* to have access to the *Storage Account*. You should now be able to connect to the VM and open a browser to the Azure Portal and from there view the Vulnerability Scan report for the *AdventureWorksLT* database. Further validate this by trying the same process from your own computer and observe that you cannot see the scan results from there. You should now also be able to browse to the *vulnerability-assessments* container in the *Storage Account* - note that this permission is provided through your *Owner* RBAC permissions rather than the firewall access only.

Examine the Vulnerability Scan output and identify any issue that reports *No baseline set*. Review the defintion and apply an approppriate baseline setting. Rerun the Vulnerability Assessment and confirm that the issue is no longer reported. 


#### References

[Secure Auditing to Storage Behind Firewalls](https://docs.microsoft.com/en-us/azure/azure-sql/database/audit-write-storage-account-behind-vnet-firewall)  
[Azure ID for Built-In RBAC Roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)  
[Add Role Assignments Using ARM Templates](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-template)  
[SQL Vulnerability Assessments](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-vulnerability-assessment)  
[Private Endpoints for Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/private-endpoint-overview)  


#### Sample Solution

A sample PowerShell script to implement this is included in the **Solution** subdirectory of this section.


#### Catch Up

If you need to get to this stage directly, there is an ARM Template and script file in the **Solution\CatchUp** subdirectory of this section. This Template is a full deployment, so you will need to delete your resources from this Resource Group in the Azure Portal before running it. It will provide the VM, Network and SQL Server to allow you to perform the validation steps and you can browse the resources and their configurations in the Portal.

***NOTE*** - as for the previous exercise, there seems to be a current bug with the ARM Templates applying an Audit to Storage Account setting. You may have to go to the Portal diectly afetr running this ARM Template (or use PowerShell) to update the Auditing setting to use the defined *Storage Account*. I have a current support case and bug report with Microsoft for this issue.