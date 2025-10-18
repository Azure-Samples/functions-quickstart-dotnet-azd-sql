$ErrorActionPreference = "Stop"
.\infra\scripts\createlocalsettings.ps1
.\infra\scripts\addclientip.ps1
.\infra\scripts\configuresql.ps1