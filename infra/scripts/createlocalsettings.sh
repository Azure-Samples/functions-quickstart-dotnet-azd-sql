#!/bin/bash

set -e

if [ ! -f "./local.settings.json" ]; then

    output=$(azd env get-values)

    # Initialize variables
    SqlConnection=""

    # Parse the output to get the endpoint URLs
    while IFS= read -r line; do
        if [[ $line == AZURE_SQL_CONNECTION_STRING_KEY=* ]]; then
            SqlConnection=$(printf '%s' "$line" | tr -d '\r' | sed -E 's/^[^=]+="([^"]*)".*/\1/; s/;? *[Uu][Ss][Ee][Rr] [Ii][Dd]=[^;]+//')
        fi
    done <<< "$output"

    if [[ -z "$SqlConnection" ]]; then
        echo "The azd environment is missing the SQL connection string." >&2
        exit 1
    fi
    SqlConnection=${SqlConnection//\\/\\\\}
    SqlConnection=${SqlConnection//\"/\\\"}

    cat <<EOF > ./local.settings.json
{
    "IsEncrypted": "false",
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
        "WEBSITE_SITE_NAME": "ToDo-local",
        "AZURE_SQL_CONNECTION_STRING_KEY": "$SqlConnection"
    }
}
EOF

fi