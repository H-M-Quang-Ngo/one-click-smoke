#!/usr/bin/env bash
# Deploy local .charm file using Juju CLI
#
# Usage: ./scripts/deploy_local_charm.sh <CHARM_SOURCE> <MODEL_NAME> <CHARM_FILE> <APP_NAME> [UNITS] [BASE]

set -euo pipefail

CHARM_SOURCE="${1:-}"

# Exit early if not local deployment (CharmHub path handles deployment via Terraform)
if [[ "$CHARM_SOURCE" != "local" ]]; then
  echo "[INFO] Skipping local charm deployment (charm-source=$CHARM_SOURCE)" >&2
  exit 0
fi

# Remaining args are for local deployment
shift

MODEL_NAME="${1:-}"
CHARM_FILE="${2:-}"
APP_NAME="${3:-}"
UNITS="${4:-1}"
BASE="${5:-}"

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $0 <CHARM_SOURCE> <MODEL_NAME> <CHARM_FILE> <APP_NAME> [UNITS] [BASE]" >&2
  exit 1
fi

# Deploy local charm
echo "[INFO] Deploying local charm: $CHARM_FILE" >&2
echo "[INFO]   Model: $MODEL_NAME" >&2
echo "[INFO]   Application: $APP_NAME" >&2
echo "[INFO]   Units: $UNITS" >&2
[[ -n "$BASE" ]] && echo "[INFO]   Base: $BASE" >&2

# Build deploy command
DEPLOY_CMD="juju deploy --model=$MODEL_NAME $CHARM_FILE $APP_NAME"
[[ "$UNITS" != "1" ]] && DEPLOY_CMD="$DEPLOY_CMD --num-units=$UNITS"
[[ -n "$BASE" ]] && DEPLOY_CMD="$DEPLOY_CMD --base=$BASE"

# Execute deployment
eval "$DEPLOY_CMD"

# Get model UUID for terraform import
MODEL_UUID=$(juju models --format=json | jq -r ".models[] | select(.name==\"$MODEL_NAME\") | .uuid")

# Output terraform import ID (model_uuid:app_name)
echo "${MODEL_UUID}:${APP_NAME}"

echo "[INFO] Deployment complete: ${MODEL_UUID}:${APP_NAME}" >&2
