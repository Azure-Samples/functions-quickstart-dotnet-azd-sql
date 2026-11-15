$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$projectRoot = Join-Path $scriptDir '..\..'
Push-Location $projectRoot
try {
    & (Join-Path $scriptDir 'createlocalsettings.ps1')
    & (Join-Path $scriptDir 'addclientip.ps1')
    & (Join-Path $scriptDir 'configuresql.ps1')
} finally {
    Pop-Location
}