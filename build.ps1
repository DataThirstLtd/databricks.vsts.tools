
param([string]$Config = 'Test', # Test Or Prod
    [boolean]$Clean = $false,
    [string]$VersionMajor = "0",
    [string]$VersionMinor = "7",
    [string]$VersionPatch = "975"
)

Set-Location $PSScriptRoot

Function setConfig($UseConfig){
    $UseConfig = $UseConfig.ToLower()
    $Content = Get-Content ".\vss-extension.$UseConfig.json" -Raw
    $FullVersion = "$($VersionMajor).$($VersionMinor).$($VersionPatch)"
    $Content = $Content.Replace('{FullVersion}', $FullVersion)
    Set-Content ".\vss-extension.json" $Content

    $tasks = Get-ChildItem -Filter "task.$UseConfig.json" -File -Recurse -Depth 1
    foreach ($t in $tasks){
        $NewName = ($t.FullName).Replace(".$($UseConfig)","")
        $Content = Get-Content $t.FullName -Raw
        $Content = $Content.Replace('"{VersionMajor}"', $VersionMajor)
        $Content = $Content.Replace('"{VersionMinor}"', $VersionMinor)
        $Content = $Content.Replace('"{VersionPatch}"', $VersionPatch)
        Set-Content $NewName $Content
    }
    Return
}

Function DownloadModules($TaskFolder, $ModuleName){
    $TaskModuleFolder = Join-Path $TaskFolder "\ps_modules"
    $ModuleFolder = Join-Path $TaskModuleFolder $ModuleName
    if (Test-Path -Path $ModuleFolder){
        Remove-Item $ModuleFolder -Force -Recurse
    }
    New-Item -ItemType Directory $TaskModuleFolder -Force | Out-Null

    Save-Module -Name $ModuleName -Path $TaskModuleFolder -Force -Confirm:$false -AllowPrerelease

    Get-ChildItem $TaskModuleFolder\$ModuleName\*\* | % {
        Move-Item -Path $_.FullName -Destination $TaskModuleFolder\$ModuleName\
    }
}

setConfig $Config


$TaskFolder = "deployScriptsTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\VstsTaskSDK"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\azure.databricks.cicd.tools"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}

$TaskFolder = "deploySecretTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\VstsTaskSDK"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\azure.databricks.cicd.tools"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}

$TaskFolder = "deployDBFSFilesTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\VstsTaskSDK"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\azure.databricks.cicd.tools"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}
$TaskFolder = "deployCreateBearer"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\VstsTaskSDK"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}
$TaskFolder = "deployClusterTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\VstsTaskSDK"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules\azure.databricks.cicd.tools"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}


Remove-Item ./bin/*.* -Force -ErrorAction SilentlyContinue
&tfx extension create --manifest-globs vss-extension.json --output-path ./bin
