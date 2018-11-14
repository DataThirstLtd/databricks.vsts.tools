
$Config = 'Test'   # Test Or Prod
$Clean = $true

Set-Location $PSScriptRoot

Function setConfig($UseConfig){
    $UseConfig = $UseConfig.ToLower()
    Copy-Item ".\vss-extension.$UseConfig.json" ".\vss-extension.json" -Force
    $tasks = Get-ChildItem -Filter "task.$UseConfig.json" -File -Recurse -Depth 1
    foreach ($t in $tasks){
        $NewName = ($t.FullName).Replace(".$($UseConfig)","")
        Copy-Item $t.FullName $NewName -Force
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

    Save-Module -Name $ModuleName -Path $TaskModuleFolder

    Get-ChildItem $TaskModuleFolder\$ModuleName\*\* | % {
        Move-Item -Path $_.FullName -Destination $TaskModuleFolder\$ModuleName\
    }
}

setConfig $Config

Return

$TaskFolder = "deployScriptsTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}

$TaskFolder = "deploySecretTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}


# &tfx extension create --manifest-globs vss-extension.json --output-path ./bin
