#!/usr/bin/env bash
# Import locally-deployed charm into Terraform state
#
# Usage: import-local-charm.sh <MODEL_NAME> <APP_NAME>
#
# Note: Run from Terraform working directory

set -euo pipefail

MODEL_NAME="${1:-}"
APP_NAME="${2:-}"

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $0 <MODEL_NAME> <APP_NAME>" >&2
  exit 1
fi

# Check if resource is already in state
RESOURCE_ADDRESS="juju_application.principal_imported[0]"
if terraform state show "$RESOURCE_ADDRESS" &>/dev/null; then
  echo "[INFO] Resource already in state: $RESOURCE_ADDRESS" >&2
  exit 0
fi

# Get model UUID
MODEL_UUID=$(juju models --format=json | jq -r ".models[] | select(.name==\"$MODEL_NAME\") | .uuid")

if [[ -z "$MODEL_UUID" || "$MODEL_UUID" == "null" ]]; then
  echo "[ERROR] Could not find model: $MODEL_NAME" >&2
  exit 1
fi

# Import the CLI-deployed application
IMPORT_ID="${MODEL_UUID}:${APP_NAME}"
echo "[INFO] Importing $RESOURCE_ADDRESS with ID: $IMPORT_ID" >&2

terraform import "$RESOURCE_ADDRESS" "$IMPORT_ID"

echo "[INFO] Import complete" >&2
