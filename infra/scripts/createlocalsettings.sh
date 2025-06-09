#!/bin/bash

set -e

if [ ! -f "./app/local.settings.json" ]; then

    output=$(azd env get-values)

    # Initialize variables
    SqlConnection=""

    # Parse the output to get the endpoint URLs
    while IFS= read -r line; do
        if [[ $line == *"AZURE_SQL_CONNECTION_STRING_KEY"* ]]; then
            SqlConnection=$(echo "$line" | sed -E 's/^[^=]+="([^"]*)"/\1/' | sed -E 's/;? *User Id=[^;]+//I')
        fi
    done <<< "$output"

    cat <<EOF > ./local.settings.json
{
    "IsEncrypted": "false",
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "node",
        "WEBSITE_SITE_NAME": "ToDo-local",
        "AZURE_SQL_CONNECTION_STRING_KEY": "$SqlConnection"
    }
}
EOF

fi