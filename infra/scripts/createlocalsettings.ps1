param()

$ErrorActionPreference = 'Stop'

if (-not (Test-Path "./app/local.settings.json")) {
    $output = azd env get-values
    $SqlConnection = ""
    foreach ($line in $output -split "`n") {
        if ($line -like '*AZURE_SQL_CONNECTION_STRING_KEY*') {
            $SqlConnection = $line -replace '^[^=]+="([^"]*)".*', '$1'
            # Remove User Id if present
            $SqlConnection = $SqlConnection -replace ';? *User Id=[^;]+', ''
        }
    }
    $localSettings = @{
        IsEncrypted = "false"
        Values = @{
            AzureWebJobsStorage = "UseDevelopmentStorage=true"
            FUNCTIONS_WORKER_RUNTIME = "node"
            WEBSITE_SITE_NAME = "ToDo-local"
            AZURE_SQL_CONNECTION_STRING_KEY = $SqlConnection
        }
    }
    $json = $localSettings | ConvertTo-Json -Depth 3
    Set-Content -Path "./local.settings.json" -Value $json
}