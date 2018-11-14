[CmdletBinding()]
param()
# https://raw.githubusercontent.com/Microsoft/vsts-tasks/master/Tasks/MSBuildV1/MSBuild.ps1

Trace-VstsEnteringInvocation $MyInvocation
try {
    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    # Get the inputs.
    [string]$bearerToken = Get-VstsInput -Name bearerToken
    [string]$region = Get-VstsInput -Name region
    [string]$LocalRootFolder = Get-VstsInput -Name LocalRootFolder
    [string]$FilePattern = Get-VstsInput -Name FilePattern
    [string]$TargetLocation = Get-VstsInput -Name TargetLocation

    # Import the helpers.
    Import-Module -Name $PSScriptRoot\ps_modules\azure.databricks.cicd.tools\azure.databricks.cicd.tools.psm1
    # Change the error action preference to 'Continue' so that each solution will build even if
    # one fails. Since the error action preference is being changed from 'Stop' (the default for
    # PowerShell3 handler) to 'Continue', errors will no longer be terminating and "Write-VstsSetResult"
    # needs to explicitly be called to fail the task. Invoke-BuildTools handles calling
    # "Write-VstsSetResult" on nuget.exe/msbuild.exe failure.
    #$global:ErrorActionPreference = 'Continue'

    Add-DatabricksDBFSFile -BearerToken $BearerToken -Region $Region -LocalRootFolder $LocalRootFolder -FilePattern $FilePattern  -TargetLocation $TargetLocation

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}