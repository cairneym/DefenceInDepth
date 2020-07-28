# Defence In Depth: Part1
Full day session on Securing your Azure SQL Database


## Exercise 3 : Azure Policies and Role Based Access Control

We now have a pretty robust Template that we can make use of for our Azure SQL Database deployments which doesn't unneccesarily expose our servers to prying eyes. However, it is never going to be the only way that we deploy Azure SQL Database in our subscriptions. What other tools are at our disposal to ensure that our hard work in defining our Template isn't wasted through one inadequate deployment?

***Azure Policies*** allow us to further control *what* can be deployed into our subscriptions with the option to either **deny** or **correct** any non-compliant ones. We can also get an ongoing Health Check of all of our SQL Servers to ensure that they are staying compliant with our well crafted Template design.

The other major benefit of Azure Policies is that it can assess compliance at large scale since it considers the *infrastructure as code* design of our environment and looks for patterns in the JSON defintions at the selected scope. Just think how m,uch easier it is to query several thousand JSON documents to confirm a specific patterns in a property compared to having to run a T-SQL query against all those instances and databases. I have seen companies with several hundred thousands of databases where a basic query against each one could take a full day to complete!

In addition to the *Azure Policies* that check for out-of-compliance instances, *RBAC Roles* can ensure that only approved actors are able to perform certain actions in the subscription. We have already seen an example of applying a RBAC Role, where we limited the access to the Storage Accounts to only the SQL Server identity. As well as access controls though, *RBAC Roles* can also allow or deny activities such as who is permitted to deploy a new Azure SQL Database.


### Tasks

Implement mangement and control policies using PowerShell, ARM Template, Azure CLI to do the following tasks:

**1.** Review your ARM Template and identify at least 3 properties that you would like to be contolled in your Subscription. I suggest looking at multiple levels - e.g. Server properties, Vulnerability Assessment properties, Firewall properties. Compare with the Azure Template resource types and versions to identify the resource paths to the properties.       
**2.** Create a *JSON* Policy Definition for each property and save them in separate files. Configure at least one of these to accept a parameter that allows the required value to be adjusted. Create the corresponding Parameter *JSON* defintion in its own file.  
**3.** Decide on the ***Policy Rule Effect*** to apply for each definition. Ideally you can define a combination of ***Deny***, ***AuditIfNotExists*** and ***Audit*** effects.    
**4.** Create each *individual* Policy and assign them to your Resource Group.     
**5.** Test your deployment template with varying values related to the *Policy Defintions* and verify that any ***Deny*** Policy Effects are immediately enacted and those deployments fail. For ***Audit*** based Policy Definitions, you may have to wait a while before these show up in the Portal.  
**6.** Select at least 2 of your Policy Definitions and combine them into a single ***Policy Initiative***. You will need to remove the individualPolicy Assignments for these. Repeat the deployment tests to demonstrate that the deployment honours each of the individual Policy Definitions in the Intiative.   
**7.** Add one of your Azure AD users to the ***SQL DB Contributor*** Built-In Role and the other to the ***SQL Security Manager*** Built-In Role. From the Virtual Machine, login to the Azure Portal with each user (private browser sessions help here). Navigate to the *Subscription/Access Control (IAM)* blade. From *Role Assignments* click on *Add* and add the required role memberships.  
**8.** For each user, navigate to the *SQL Server/Advanced Data Security* blade and note the difference in access. Navigate to the *SQL Server/Manage Backups* blade and notice the different availability there.


#### Verification

Verification for this exercise is included in the Task Steps.

#### References

[Azure Policies](https://docs.microsoft.com/en-us/azure/governance/policy/overview)  
[Structure of an Azure Policy](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)  
[Azure Policy Initiatives](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure)  
[Understanding Policy Effects](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/effects)  
[ARM Resource types and schema versions](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/allversions)  
[Azure Role Based Access - Role Definitions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-definitions)  


#### Sample Solution

A sample PowerShell script to implement this is included in the **Solution** subdirectory of this section.
