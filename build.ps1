

$Clean = $true

Set-Location $PSScriptRoot

Function DownloadModules($TaskFolder, $ModuleName){
    $TaskModuleFolder = Join-Path $TaskFolder "\ps_modules"
    $ModuleFolder = Join-Path $TaskModuleFolder $ModuleName
    if (Test-Path -Path $ModuleFolder){
        Remove-Item $ModuleFolder -Force -Recurse
    }
    mkdir $TaskModuleFolder -Force | Out-Null

    Save-Module -Name $ModuleName -Path $TaskModuleFolder

    Get-ChildItem $TaskModuleFolder\$ModuleName\*\* | % {
        Move-Item -Path $_.FullName -Destination $TaskModuleFolder\$ModuleName\
    }
}


$TaskFolder = "deployScriptsTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTaskSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}

$TaskFolder = "deploySecretTask"
if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "VstsTastfxkSDK"
}

if ((!(Test-Path -Path (Join-Path $TaskFolder "\ps_modules"))) -or ($Clean)){
    DownloadModules $TaskFolder "azure.databricks.cicd.tools"
}

# &tfx extension create --manifest-globs vss-extension.json --output-path ./bin
