[CmdletBinding()]
param()
# https://raw.githubusercontent.com/Microsoft/vsts-tasks/master/Tasks/MSBuildV1/MSBuild.ps1

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    # Get the inputs.
    [string]$bearerToken = Get-VstsInput -Name bearerToken
    [string]$region = Get-VstsInput -Name region
    [string]$secretScopeName = Get-VstsInput -Name secretScopeName
    [string]$secretName = Get-VstsInput -Name secretName
    [string]$secretValue = Get-VstsInput -Name secretValue
    [string]$applicationId = Get-VstsInput -Name applicationId
    [string]$spSecret = Get-VstsInput -Name spSecret
    [string]$authMethod = Get-VstsInput -Name authMethod
    [string]$subscriptionId = Get-VstsInput -Name subscriptionId
    [string]$tenantId = Get-VstsInput -Name tenantId
    [string]$resourceGroup = Get-VstsInput -Name resourceGroup
    [string]$workspace = Get-VstsInput -Name workspace

    # Import the helpers.
    Import-Module -Name $PSScriptRoot\ps_modules\azure.databricks.cicd.tools\azure.databricks.cicd.tools.psm1
    $config = Import-PowerShellDataFile "$PSScriptRoot\ps_modules\azure.databricks.cicd.tools\azure.databricks.cicd.tools.psd1"
    Write-Output "Tools Version: $($config.ModuleVersion)"

    # Change the error action preference to 'Continue' so that each solution will build even if
    # one fails. Since the error action preference is being changed from 'Stop' (the default for
    # PowerShell3 handler) to 'Continue', errors will no longer be terminating and "Write-VstsSetResult"
    # needs to explicitly be called to fail the task. Invoke-BuildTools handles calling
    # "Write-VstsSetResult" on nuget.exe/msbuild.exe failure.
    #$global:ErrorActionPreference = 'Continue'

    if ($authMethod -eq "bearer"){
        Connect-Databricks -BearerToken $bearerToken -Region $region
    }
    else{
        # Due to bug in Databricks API when using AAD auth secrets fail to create. Hack is to generate a bearer token and use that to auth instead then drop it.
        Connect-Databricks -ApplicationId $applicationId -Secret $spSecret -Region $region -ResourceGroupName $resourceGroup -WorkspaceName $workspace -TenantId $tenantId -SubscriptionId $subscriptionId 
        $Token = Invoke-DatabricksAPI -Method POST -API "api/2.0/token/create" -Body @{}
        Connect-Databricks -BearerToken $Token.token_value -Region $region
        $Drop = $True
    }
    Add-DatabricksSecretScope -ScopeName $secretScopeName -AllUserAccess -ErrorAction SilentlyContinue 
    Set-DatabricksSecret -ScopeName $secretScopeName -SecretName $secretName -SecretValue $secretValue 

    if ($Drop){
        $Body = @{"token_id"= $Token.token_info.token_id} 
        Invoke-DatabricksAPI  -Method POST -API "api/2.0/token/delete" -Body $Body
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}