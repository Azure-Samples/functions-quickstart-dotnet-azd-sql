#!/bin/bash
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
cd "$project_root"

./infra/scripts/createlocalsettings.sh
./infra/scripts/addclientip.sh
./infra/scripts/configuresql.sh
