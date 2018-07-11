# databricks.vsts.tools
VSTS Deployment Tasks for Databricks Objects

# VSTS Deployment Tasks
See marketplace https://marketplace.visualstudio.com/items?itemName=DataThirstLtd.databricksDeployScriptsTasks

Based upon PowerShell module available here: https://github.com/DataThirstLtd/azure.databricks.cicd.tools

# Deploy Scripts
This Task can deploy a folder of scripts from your repo/build into your Databricks Workspace. It assumes the files have been exported in "Source" format and are either Python (py), Scala, SQL or R files.

To export your scripts in bulk in the correct format see the link to the PowerShell module above and the Export function within it.

## How to use
- Install from the MarketPlace using the link above
- Create a new build or release in VSTS
- When adding tasks look under "Deploy" for Databricks Scripts
- Populate the variables as per the parameters section below

## Parameters
- Bearer Token - This is your API key, get it from the Databricks workspace for your user account
- Azure Region - The region your instance is in. This can be taken from the start of your workspace URL (it must not contain spaces)
- Source Files Path - the path to your scripts (note that sub folders will also be deployed)
- Target Files Path - this is the location in your workspace to deploy to, such as /Shared/MyCode - it must start /

# Deploy Secrets
## How to use
- Install from the MarketPlace using the link above
- Create a new build or release in VSTS
- When adding tasks look under "Deploy" for Databricks Secrets
- Populate the variables as per the parameters section below
- Repeat for each Secret required

## Parameters
- Bearer Token - This is your API key, get it from the Databricks workspace for your user account
- Azure Region - The region your instance is in. This can be taken from the start of your workspace URL (it must not contain spaces)
- Scope Name - The Scope to store your variable in
- Secret Name - The Key name
- Secret Value - Your secret value such as a password or key

# Libraries, Clusters, Jobs
These are on my ToDo list

For help please contact hello@datathirst.net or log an Issue in GitHub.
