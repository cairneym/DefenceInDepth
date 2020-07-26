# Defence In Depth: Part1
First Part of a Full day session on Securing your Azure SQL Database

## Pre-requisites

You need to have access to an Azure Subscription and have Owner permissions within it. We will be adding Groups and Users to the associated Azure Active Directory and also applying other RBAC permissions throughout the workshop, so you will need these elevated permissions.

The simplest approach is to create a new Free Trial subscription which is sufficient to run all the exercises without any cost to you.

Your computer will also need to have Azure Powershell's *Az* module and also the *AzureAD* module installed.


## Part 1 : Securing the Platform

The first part of this workshop focusses on the Azure Platform, and the services and resources that exist there to help secure your Azure SQL Databases. Our plan for the workshop is to start from a very vanilla implementation of Azure SQL Database and then progressively harden it through each of the exercises.

You will learn what components can make a difference and will develop ARM templates to use to deploy these additional components properly configured.

At any stage, if you get stuck, there is a suggested solution in the ***Solution*** folder for each exercise.  There is also an ARM Template and deployment script in the ***Solution\CatchUp*** folder in each exercise which will bring your current Azure SQL Database deployment to the same configuration as the instructor's. This allows you to continue with the next exercise, or to join in at any stage of the workshop. However, please note that you will have to delete your current resources to redeploy from these templates.

Afterwards, take the templates away with you and practice / adapt to your own business rules to get the best solution for yourself.


### Exercise 00 - Deploy a baseline environment

Navigate to the **00_DeployBaseline** folder and folow the instructions in the file *Exercise0_Guidance.md*.


### Exercise 01 - Lock Down Access

Navigate to the **01_LockDownAccess** folder and folow the instructions in the file *Exercise1_Guidance.md*.


### Exercise 02 - Implement Audits and Vulnerability Scans

Navigate to the **02_AuditsAndVulnerabilityScans** folder and folow the instructions in the file *Exercise2_Guidance.md*.


### Exercise 03 - Azure Policies

Navigate to the **03_DeployPolicies** folder and folow the instructions in the file *Exercise2_Guidance.md*.

