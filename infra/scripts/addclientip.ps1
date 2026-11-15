param()

$ErrorActionPreference = 'Stop'

# Get environment values
$output = azd env get-values

# Parse the output to get the resource names and the resource group
$SqlServerName = $null
$ResourceGroup = $null
foreach ($line in $output -split "`n") {
    if ($line -like 'AZURE_SQL_SERVER_RESOURCE_NAME*') {
        $SqlServerName = $line.Split('=')[1].Trim('"')
    } elseif ($line -like 'RESOURCE_GROUP_NAME*') {
        $ResourceGroup = $line.Split('=')[1].Trim('"')
    }
}

# Read the config.json file to see if vnet is enabled
$ConfigFolder = ($ResourceGroup -split '-', 2)[1]
$jsonContent = Get-Content ".azure/$ConfigFolder/config.json" -Raw | ConvertFrom-Json
$EnableVirtualNetwork = $jsonContent.infra.parameters.vnetEnabled

if ($EnableVirtualNetwork -eq $false) {
    Write-Host "VNet is not enabled. Skipping adding the client IP to the network rule of the Azure SQL Database."
} else {
    Write-Host "VNet is enabled. Adding the client IP to the firewall rule of the Azure SQL Database."

    # Get the client IP
    $ClientIP = (Invoke-RestMethod -Uri 'https://api.ipify.org')

    # Check if the firewall rule already exists for this IP
    $azCmd = "az sql server firewall-rule list --resource-group '$ResourceGroup' --server '$SqlServerName' -o json"
    Write-Host $azCmd
    $rules = az sql server firewall-rule list --resource-group $ResourceGroup --server $SqlServerName -o json | ConvertFrom-Json
    $RuleExists = $rules | Where-Object { $_.startIpAddress -eq $ClientIP -and $_.endIpAddress -eq $ClientIP }

    if (-not $RuleExists) {
        Write-Host "Adding the client IP $ClientIP to the firewall rule of the Azure SQL Database server $SqlServerName"
        $createCmd = "az sql server firewall-rule create --resource-group '$ResourceGroup' --server '$SqlServerName' --name 'AllowMyIP' --start-ip-address '$ClientIP' --end-ip-address '$ClientIP'"
        Write-Host $createCmd
        az sql server firewall-rule create --resource-group $ResourceGroup --server $SqlServerName --name "AllowMyIP" --start-ip-address $ClientIP --end-ip-address $ClientIP | Out-Null
    } else {
        Write-Host "The client IP $ClientIP is already in the firewall rule of the Azure SQL Database server $SqlServerName"
    }
}