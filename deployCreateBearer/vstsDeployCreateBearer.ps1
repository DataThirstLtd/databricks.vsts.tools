[CmdletBinding()]
param()
# https://raw.githubusercontent.com/Microsoft/vsts-tasks/master/Tasks/MSBuildV1/MSBuild.ps1

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    # Get the inputs.
    [string]$region = Get-VstsInput -Name region
    [string]$applicationId = Get-VstsInput -Name applicationId
    [string]$spSecret = Get-VstsInput -Name spSecret
    [string]$subscriptionId = Get-VstsInput -Name subscriptionId
    [string]$tenantId = Get-VstsInput -Name tenantId
    [string]$resourceGroup = Get-VstsInput -Name resourceGroup
    [string]$workspace = Get-VstsInput -Name workspace

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

  
    Connect-Databricks -ApplicationId $applicationId -Secret $spSecret -Region $region -ResourceGroupName $resourceGroup -WorkspaceName $workspace -TenantId $tenantId -SubscriptionId $subscriptionId 
   
    $Token = Invoke-DatabricksAPI  -Method POST -API "api/2.0/token/create" -Body @{}
    
    $BearerToken = $Token.token_value
    Write-Host "##vso[task.setVariable variable=BearerToken; issecret=true]$BearerToken"
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}