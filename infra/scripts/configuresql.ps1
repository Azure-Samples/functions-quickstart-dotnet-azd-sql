# configuresql.ps1 - Configure Azure SQL DB: create ToDo table, enable change tracking, add UAMI user
# Usage: ./configuresql.ps1

param()

$ErrorActionPreference = 'Stop'

# Get environment values from azd
$output = azd env get-values

# Initialize variables
$SQL_SERVER = ""
$SQL_DATABASE = ""
$UAMI_CLIENT_ID = ""
$UAMI_PRINCIPAL_ID = ""
$UAMI_NAME = ""

# Parse the output to get the resource names
foreach ($line in $output -split "`n") {
    if ($line -like 'AZURE_SQL_SERVER_NAME*') {
        $SQL_SERVER = $line.Split('=')[1].Trim('"')
    } elseif ($line -like 'AZURE_SQL_DATABASE_NAME*') {
        $SQL_DATABASE = $line.Split('=')[1].Trim('"')
    } elseif ($line -like 'USER_ASSIGNED_IDENTITY_CLIENT_ID*') {
        $UAMI_CLIENT_ID = $line.Split('=')[1].Trim('"')
    } elseif ($line -like 'USER_ASSIGNED_IDENTITY_PRINCIPAL_ID*') {
        $UAMI_PRINCIPAL_ID = $line.Split('=')[1].Trim('"')
    } elseif ($line -like 'USER_ASSIGNED_IDENTITY_NAME*') {
        $UAMI_NAME = $line.Split('=')[1].Trim('"')
    }
}

# Use static SQL files in the same folder as this script
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Download and install sqlcmd if not present in $SCRIPT_DIR
$SQLCMD_BASEURL = "https://github.com/microsoft/go-sqlcmd/releases/download/"
$SQLCMD_VERSION = "v1.8.2"
$sqlcmdPath = Join-Path $SCRIPT_DIR 'sqlcmd'
if (-not (Test-Path $sqlcmdPath)) {
    Write-Host "sqlcmd not found in $SCRIPT_DIR. Downloading..."
    $uname = $(uname -s).ToLower()
    $arch = $(uname -m)
    if ($uname -eq 'darwin') {
        if ($arch -eq 'arm64') {
            $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-darwin-arm64.tar.bz2"
        } else {
            $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-vdarwin-x64.tar.bz2"
        }
    } elseif ($uname -eq 'linux') {
        if ($arch -eq 'aarch64' -or $arch -eq 'arm64') {
            $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-linux-arm64.tar.bz2"
        } else {
            $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-linux-x64.tar.bz2"
        }
    } elseif ($env:OS -like '*Windows*') {
        if ($arch -eq 'x86_64' -or $arch -eq 'amd64') {
            $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-windows-amd64.zip"
        } elseif ($arch -eq 'arm64' -or $arch -eq 'aarch64') {
            $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-windows-arm.zip"
        } else {
            Write-Host "Unsupported Windows architecture: $arch"
            exit 1
        }
    } else {
        Write-Host "Unsupported OS: $uname"
        exit 1
    }
    Write-Host "Downloading sqlcmd from: $URL"
    $archivePath = Join-Path $SCRIPT_DIR 'sqlcmd_download'
    Invoke-WebRequest -Uri $URL -OutFile $archivePath
    if ($URL -like '*.tar.bz2') {
        tar -xjf $archivePath -C $SCRIPT_DIR
    } elseif ($URL -like '*.tar.gz') {
        tar -xzf $archivePath -C $SCRIPT_DIR
    } elseif ($URL -like '*.zip') {
        Expand-Archive -Path $archivePath -DestinationPath $SCRIPT_DIR -Force
    } else {
        Write-Host "Unknown archive format for $URL"
        exit 1
    }
    Remove-Item $archivePath -Force
    if ($uname -ne 'windows_nt') {
        chmod +x $sqlcmdPath
    }
}

# Run the scripts using sqlcmd from $SCRIPT_DIR
Write-Host "$sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -i $(Join-Path $SCRIPT_DIR 'sql_create_table.sql')"
& $sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -i (Join-Path $SCRIPT_DIR 'sql_create_table.sql')

Write-Host "$sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -v SQL_DATABASE=\"$SQL_DATABASE\" -i $(Join-Path $SCRIPT_DIR 'sql_enable_change_tracking.sql')"
& $sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -v SQL_DATABASE=$SQL_DATABASE -i (Join-Path $SCRIPT_DIR 'sql_enable_change_tracking.sql')

Write-Host "$sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -v UAMI_NAME=\"$UAMI_NAME\" UAMI_PRINCIPAL_ID=\"$UAMI_PRINCIPAL_ID\" -i $(Join-Path $SCRIPT_DIR 'sql_add_uami_user.sql')"
& $sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -v UAMI_NAME=$UAMI_NAME UAMI_PRINCIPAL_ID=$UAMI_PRINCIPAL_ID -i (Join-Path $SCRIPT_DIR 'sql_add_uami_user.sql')

Write-Host "SQL configuration complete."
