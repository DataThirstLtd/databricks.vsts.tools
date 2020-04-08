[CmdletBinding()]
param()
# https://raw.githubusercontent.com/Microsoft/vsts-tasks/master/Tasks/MSBuildV1/MSBuild.ps1

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"

    # Get the inputs.
    [string]$bearerToken = Get-VstsInput -Name bearerToken
    [string]$region = Get-VstsInput -Name region
    [string]$applicationId = Get-VstsInput -Name applicationId
    [string]$spSecret = Get-VstsInput -Name spSecret
    [string]$authMethod = Get-VstsInput -Name authMethod
    [string]$subscriptionId = Get-VstsInput -Name subscriptionId
    [string]$tenantId = Get-VstsInput -Name tenantId
    [string]$resourceGroup = Get-VstsInput -Name resourceGroup
    [string]$workspace = Get-VstsInput -Name workspace
    [string]$SourcePath = Get-VstsInput -Name SourcePath

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

    # Build each solution.
    if ($authMethod -eq "bearer"){
        Write-Output "Connecting via Bearer"
        Connect-Databricks -BearerToken $bearerToken -Region $region
    }
    else{
        Write-Output "Connecting via AAD"
        Connect-Databricks -ApplicationId $applicationId -Secret $spSecret -Region $region -ResourceGroupName $resourceGroup -WorkspaceName $workspace -TenantId $tenantId -SubscriptionId $subscriptionId
    }

    $json = (Get-Content -Path $SourcePath) | ConvertFrom-Json 
    Write-Output $json
    
    $Request = @{}
    $json.psobject.properties | ForEach-Object { $Request[$_.Name] = $_.Value }
    $Request.Remove('cluster_id')
    $Request.Remove('cluster_source')
    $ClusterName = $Request['cluster_name']

    $Cluster = (Get-DatabricksClusters | Where-Object {$_.cluster_name -eq $ClusterName})
    $ClusterId = $Cluster.cluster_id
   

    if ($ClusterId){
        Write-Output "Found existing cluster $ClusterId"
        
        # Work out if cluster has changed to prevnet unecessary restart
        $ExistingCluster = @{}
        $Cluster.psobject.properties | ForEach-Object { $ExistingCluster[$_.Name] = $_.Value }
        $ExistingCluster.Remove('cluster_id')
        $res = @()
        foreach ($k in $Request.keys){
            if ($Request[$k].GetType().Name -eq "PSCustomObject"){
                $newHashTable = @{}
                $Request[$k].psobject.properties | ForEach-Object { $newHashTable[$_.Name] = $_.Value }
                foreach ($subk in $newHashTable.keys){
                    if ($newHashTable[$subk] -ne $ExistingCluster[$k].$subk){
                        $res += $k
                        continue
                    }
                }
            }
            elseif ($Request[$k] -ne $ExistingCluster[$k]){
                $res += $k
            }
        }
        
        if ($res.Count -gt 0){
            Write-Output "Cluster $ClusterId found - editing"
            $Request['cluster_id'] = $ClusterId
            $ClusterId = (Invoke-DatabricksAPI -API "api/2.0/clusters/edit" -Method POST -Body $Request).cluster_id
        }
        else
        {
            Write-Output "Cluster exists and is unchanged - skipping"
        }
    }
    else{
        Write-Output "Cluster $ClusterName not found - creating"
        $ClusterId = (Invoke-DatabricksAPI -API "api/2.0/clusters/create" -Method POST -Body $Request).cluster_id
        Write-Output "Created Cluster $ClusterId"
    }

    Write-Host "##vso[task.setVariable variable=DatabricksClusterId;]$ClusterId"
    Write-Host "##vso[task.setVariable variable=Extension.DatabricksClusterId;]$ClusterId"

    
    
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}