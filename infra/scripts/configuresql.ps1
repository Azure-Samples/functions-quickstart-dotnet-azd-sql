# configuresql.ps1 - Configure Azure SQL DB: create ToDo table, enable change tracking, add UAMI user
# Usage: ./configuresql.ps1

param()

$ErrorActionPreference = 'Stop'

# Get environment values from azd
$output = azd env get-values
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read the current azd environment.'
}

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

if (-not $SQL_SERVER -or -not $SQL_DATABASE -or -not $UAMI_CLIENT_ID -or -not $UAMI_NAME) {
    throw 'The azd environment is missing the SQL server, database, or managed identity values.'
}

# Use static SQL files in the same folder as this script
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Download and install sqlcmd if not present in $SCRIPT_DIR
$SQLCMD_BASEURL = "https://github.com/microsoft/go-sqlcmd/releases/download/"
$SQLCMD_VERSION = "v1.8.2"
$sqlcmdPath = Join-Path $SCRIPT_DIR $(if ($IsWindows) { 'sqlcmd.exe' } else { 'sqlcmd' })
if (-not (Test-Path $sqlcmdPath)) {
    Write-Host "sqlcmd not found in $SCRIPT_DIR. Downloading..."
    if ($IsWindows) {
        $os = 'windows'
        $extension = '.zip'
    } elseif ($IsMacOS) {
        $os = 'darwin'
        $extension = '.tar.bz2'
    } elseif ($IsLinux) {
        $os = 'linux'
        $extension = '.tar.bz2'
    } else {
        throw 'Unsupported operating system'
    }

    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($architecture) {
        'X64' { $arch = 'amd64' }
        'Arm64' { $arch = 'arm64' }
        default { throw "Unsupported architecture: $architecture" }
    }
    $URL = "$($SQLCMD_BASEURL)$($SQLCMD_VERSION)/sqlcmd-$os-$arch$extension"
    Write-Host "Downloading sqlcmd from: $URL"
    $archivePath = Join-Path $SCRIPT_DIR "sqlcmd_download$extension"
    Invoke-WebRequest -Uri $URL -OutFile $archivePath
    if ($URL -like '*.tar.bz2') {
        tar -xjf $archivePath -C $SCRIPT_DIR
        if ($LASTEXITCODE -ne 0) { throw 'Unable to extract the sqlcmd archive.' }
    } elseif ($URL -like '*.tar.gz') {
        tar -xzf $archivePath -C $SCRIPT_DIR
        if ($LASTEXITCODE -ne 0) { throw 'Unable to extract the sqlcmd archive.' }
    } elseif ($URL -like '*.zip') {
        Expand-Archive -Path $archivePath -DestinationPath $SCRIPT_DIR -Force
    } else {
        Write-Host "Unknown archive format for $URL"
        exit 1
    }
    Remove-Item $archivePath -Force
    if (-not (Test-Path $sqlcmdPath)) {
        throw "The sqlcmd executable was not found at $sqlcmdPath after extraction."
    }
    if (-not $IsWindows) {
        chmod +x $sqlcmdPath
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to make sqlcmd executable.'
        }
    }
}

# Run the scripts using sqlcmd from $SCRIPT_DIR
Write-Host "$sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -b -i $(Join-Path $SCRIPT_DIR 'sql_create_table.sql')"
& $sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -b -i (Join-Path $SCRIPT_DIR 'sql_create_table.sql')
if ($LASTEXITCODE -ne 0) { throw 'Failed to create the ToDo table.' }

Write-Host "$sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -b -v SQL_DATABASE=$SQL_DATABASE -i $(Join-Path $SCRIPT_DIR 'sql_enable_change_tracking.sql')"
& $sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -b -v SQL_DATABASE=$SQL_DATABASE -i (Join-Path $SCRIPT_DIR 'sql_enable_change_tracking.sql')
if ($LASTEXITCODE -ne 0) { throw 'Failed to enable SQL change tracking.' }

Write-Host "$sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -b -v UAMI_NAME=$UAMI_NAME -v UAMI_CLIENT_ID=$UAMI_CLIENT_ID -i $(Join-Path $SCRIPT_DIR 'sql_add_uami_user.sql')"
& $sqlcmdPath -S $SQL_SERVER -d $SQL_DATABASE -G -b -v UAMI_NAME=$UAMI_NAME -v UAMI_CLIENT_ID=$UAMI_CLIENT_ID -i (Join-Path $SCRIPT_DIR 'sql_add_uami_user.sql')
if ($LASTEXITCODE -ne 0) { throw 'Failed to configure the managed identity SQL user.' }

Write-Host "SQL configuration complete."
