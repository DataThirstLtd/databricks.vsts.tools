[CmdletBinding()]
param()
# https://raw.githubusercontent.com/Microsoft/vsts-tasks/master/Tasks/MSBuildV1/MSBuild.ps1

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"

    # Get the inputs.
    [string]$bearerToken = Get-VstsInput -Name bearerToken
    [string]$region = Get-VstsInput -Name region
    [string]$localPath = Get-VstsInput -Name localPath
    [string]$databricksPath = Get-VstsInput -Name databricksPath
    [string]$applicationId = Get-VstsInput -Name applicationId
    [string]$spSecret = Get-VstsInput -Name spSecret
    [string]$authMethod = Get-VstsInput -Name authMethod
    [string]$subscriptionId = Get-VstsInput -Name subscriptionId
    [string]$tenantId = Get-VstsInput -Name tenantId
    [string]$resourceGroup = Get-VstsInput -Name resourceGroup
    [string]$workspace = Get-VstsInput -Name workspace
    [string]$clean = Get-VstsInput -Name clean


    # Import the helpers.
    Import-Module -Name $PSScriptRoot\ps_modules\azure.databricks.cicd.tools\azure.databricks.cicd.tools.psm1
    $config = Import-PowerShellDataFile "$PSScriptRoot\ps_modules\azure.databricks.cicd.tools\azure.databricks.cicd.tools.psd1"
    Write-Output "Tools Version: " + $config.ModuleVersion

    # Change the error action preference to 'Continue' so that each solution will build even if
    # one fails. Since the error action preference is being changed from 'Stop' (the default for
    # PowerShell3 handler) to 'Continue', errors will no longer be terminating and "Write-VstsSetResult"
    # needs to explicitly be called to fail the task. Invoke-BuildTools handles calling
    # "Write-VstsSetResult" on nuget.exe/msbuild.exe failure.
    #$global:ErrorActionPreference = 'Continue'

    # Build each solution.
    if ($authMethod -eq "bearer"){
        Write-Output "Connecting via Bearer"
        Connect-Databricks -BearerToken $bearerToken -Region $region
    }
    else{
        Write-Output "Connecting via AAD"
        Connect-Databricks -ApplicationId $applicationId -Secret $spSecret -Region $region -ResourceGroupName $resourceGroup -WorkspaceName $workspace -TenantId $tenantId -SubscriptionId $subscriptionId
    }

    Write-Output "Clean $clean"
    if ($clean -eq "true"){
        Write-Output "Running with clean"
        Import-DatabricksFolder -LocalPath $localPath -DatabricksPath $databricksPath -Clean -Verbose
    }
    else{
        Write-Output "Running without clean"
        Import-DatabricksFolder -LocalPath $localPath -DatabricksPath $databricksPath -Verbose
    }
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}