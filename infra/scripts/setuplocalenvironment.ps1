$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
& "$ScriptDir\createlocalsettings.ps1"
& "$ScriptDir\addclientip.ps1"