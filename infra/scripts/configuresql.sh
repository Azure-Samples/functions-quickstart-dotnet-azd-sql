#!/usr/bin/env bash
# configuresql.sh - Configure Azure SQL DB: create ToDo table, enable change tracking, add UAMI user
# Usage: ./configuresql.sh

set -euo pipefail

# Get environment values from azd
output=$(azd env get-values)

# Initialize variables
SQL_SERVER=""
SQL_DATABASE=""
UAMI_CLIENT_ID=""
UAMI_NAME=""

# Parse the output to get the resource names
while IFS= read -r line; do
    if [[ $line == AZURE_SQL_SERVER_NAME* ]]; then
        SQL_SERVER=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    elif [[ $line == AZURE_SQL_DATABASE_NAME* ]]; then
        SQL_DATABASE=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    elif [[ $line == USER_ASSIGNED_IDENTITY_CLIENT_ID* ]]; then
        UAMI_CLIENT_ID=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    elif [[ $line == USER_ASSIGNED_IDENTITY_NAME* ]]; then
        UAMI_NAME=$(echo "$line" | cut -d '=' -f 2 | tr -d '"')
    fi
done <<< "$output"

if [[ -z "$SQL_SERVER" || -z "$SQL_DATABASE" || -z "$UAMI_CLIENT_ID" || -z "$UAMI_NAME" ]]; then
    echo "The azd environment is missing the SQL server, database, or managed identity values." >&2
    exit 1
fi

# Use static SQL files in the same folder as this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Download and install sqlcmd if not present in $SCRIPT_DIR
SQLCMD_BASEURL="https://github.com/microsoft/go-sqlcmd/releases/download/"
SQLCMD_VERSION="v1.8.2"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    mingw*|msys*|cygwin*|windows_nt*) SQLCMD_PATH="$SCRIPT_DIR/sqlcmd.exe" ;;
    *) SQLCMD_PATH="$SCRIPT_DIR/sqlcmd" ;;
esac
if [ ! -x "$SQLCMD_PATH" ]; then
    echo "sqlcmd not found in $SCRIPT_DIR. Downloading..."
    ARCH=$(uname -m)
    if [[ "$OS" == "darwin" ]]; then
        # macOS
        if [[ "$ARCH" == "arm64" ]]; then
            URL="${SQLCMD_BASEURL}${SQLCMD_VERSION}/sqlcmd-darwin-arm64.tar.bz2"
        else
            URL="${SQLCMD_BASEURL}${SQLCMD_VERSION}/sqlcmd-darwin-amd64.tar.bz2"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            URL="${SQLCMD_BASEURL}${SQLCMD_VERSION}/sqlcmd-linux-arm64.tar.bz2"
        else
            URL="${SQLCMD_BASEURL}${SQLCMD_VERSION}/sqlcmd-linux-amd64.tar.bz2"
        fi
    elif [[ "$OS" == mingw* || "$OS" == msys* || "$OS" == cygwin* || "$OS" == windows_nt* ]]; then
        if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
            URL="${SQLCMD_BASEURL}${SQLCMD_VERSION}/sqlcmd-windows-amd64.zip"
        elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
            URL="${SQLCMD_BASEURL}${SQLCMD_VERSION}/sqlcmd-windows-arm64.zip"
        else
            echo "Unsupported Windows architecture: $ARCH"
            exit 1
        fi
    else
        echo "Unsupported OS: $OS"
        exit 1
    fi
    echo "Downloading sqlcmd from: $URL"
    cd "$SCRIPT_DIR"
    ARCHIVE="sqlcmd_download.${URL##*.}"
    curl -fL "$URL" -o "$ARCHIVE"
    if [[ "$URL" == *.tar.bz2 ]]; then
        tar xjf "$ARCHIVE"
    elif [[ "$URL" == *.tar.gz ]]; then
        tar xzf "$ARCHIVE"
    elif [[ "$URL" == *.zip ]]; then
        unzip -o "$ARCHIVE"
    else
        echo "Unknown archive format for $URL"
        exit 1
    fi
    rm "$ARCHIVE"
    if [[ ! -f "$SQLCMD_PATH" ]]; then
        echo "The sqlcmd executable was not found at $SQLCMD_PATH after extraction." >&2
        exit 1
    fi
    chmod +x "$SQLCMD_PATH"
    cd - > /dev/null
fi

# Run the scripts using sqlcmd from $SCRIPT_DIR
echo "$SQLCMD_PATH -S $SQL_SERVER -d $SQL_DATABASE -G -i $SCRIPT_DIR/sql_create_table.sql"
"$SQLCMD_PATH" -S "$SQL_SERVER" -d "$SQL_DATABASE" -G -b -i "$SCRIPT_DIR/sql_create_table.sql"

echo "$SQLCMD_PATH -S $SQL_SERVER -d $SQL_DATABASE -G -v SQL_DATABASE=\"$SQL_DATABASE\" -i $SCRIPT_DIR/sql_enable_change_tracking.sql"
"$SQLCMD_PATH" -S "$SQL_SERVER" -d "$SQL_DATABASE" -G -b -v SQL_DATABASE="$SQL_DATABASE" -i "$SCRIPT_DIR/sql_enable_change_tracking.sql"

echo "$SQLCMD_PATH -S $SQL_SERVER -d $SQL_DATABASE -G -v UAMI_NAME=\"$UAMI_NAME\" -v UAMI_CLIENT_ID=\"$UAMI_CLIENT_ID\" -i $SCRIPT_DIR/sql_add_uami_user.sql"
"$SQLCMD_PATH" -S "$SQL_SERVER" -d "$SQL_DATABASE" -G -b -v UAMI_NAME="$UAMI_NAME" -v UAMI_CLIENT_ID="$UAMI_CLIENT_ID" -i "$SCRIPT_DIR/sql_add_uami_user.sql"

echo "SQL configuration complete."
