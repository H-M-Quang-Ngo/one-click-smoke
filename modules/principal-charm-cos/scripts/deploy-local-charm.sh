#!/usr/bin/env bash
# Deploy local .charm file using Juju CLI
#
# Usage: deploy-local-charm.sh <MODEL_NAME> <CHARM_FILE> <APP_NAME> [UNITS] [BASE]

set -euo pipefail

MODEL_NAME="${1:-}"
CHARM_FILE="${2:-}"
APP_NAME="${3:-}"
UNITS="${4:-1}"
BASE="${5:-}"

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: $0 <MODEL_NAME> <CHARM_FILE> <APP_NAME> [UNITS] [BASE]" >&2
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
MODEL_UUID=$(juju show-model "$MODEL_NAME" --format=json | jq -r ".[\"$MODEL_NAME\"] | .\"model-uuid\"")

# Output terraform import ID (model_uuid:app_name)
echo "${MODEL_UUID}:${APP_NAME}"

echo "[INFO] Deployment complete: ${MODEL_UUID}:${APP_NAME}" >&2
