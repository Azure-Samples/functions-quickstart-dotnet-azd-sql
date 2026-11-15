param()

$ErrorActionPreference = 'Stop'

if (-not (Test-Path "./local.settings.json")) {
    $output = azd env get-values
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to read the current azd environment.'
    }
    $SqlConnection = ""
    foreach ($line in $output -split "`n") {
        if ($line -like '*AZURE_SQL_CONNECTION_STRING_KEY*') {
            $SqlConnection = $line -replace '^[^=]+="([^"]*)".*', '$1'
            # Remove User Id if present
            $SqlConnection = $SqlConnection -replace ';? *User Id=[^;]+', ''
        }
    }
    if (-not $SqlConnection) {
        throw 'The azd environment is missing the SQL connection string.'
    }
    $localSettings = @{
        IsEncrypted = "false"
        Values = @{
            AzureWebJobsStorage = "UseDevelopmentStorage=true"
            FUNCTIONS_WORKER_RUNTIME = "dotnet-isolated"
            WEBSITE_SITE_NAME = "ToDo-local"
            AZURE_SQL_CONNECTION_STRING_KEY = $SqlConnection
        }
    }
    $json = $localSettings | ConvertTo-Json -Depth 3
    Set-Content -Path "./local.settings.json" -Value $json
}