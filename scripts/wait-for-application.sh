#!/usr/bin/env bash
# Wait for a Juju application to reach specified status
#
# Usage: ./scripts/wait-for-application.sh <MODEL> <APPLICATION> <STATUS_QUERY> [TIMEOUT]
#
# Examples:
#   ./scripts/wait-for-application.sh my-model my-app 'status=="active"'
#   ./scripts/wait-for-application.sh my-model my-app 'status=="active" || status=="blocked"'
set -euo pipefail

MODEL="${1:-}"
APPLICATION="${2:-}"
STATUS_QUERY="${3:-status==\"active\" || status==\"idle\"}"
TIMEOUT="${4:-20m0s}"

if [[ -z "$APPLICATION" ]]; then
  echo "Wait for a Juju application to reach specified status." >&2
  echo "" >&2
  echo "Usage: $0 <MODEL> <APPLICATION> <STATUS_QUERY> [TIMEOUT]" >&2
  echo "" >&2
  echo "Arguments:" >&2
  echo "  MODEL        - Juju model name" >&2
  echo "  APPLICATION  - Application name" >&2
  echo "  STATUS_QUERY - JQ query for status (default: 'status==\"active\" || status==\"idle\"')" >&2
  echo "  TIMEOUT      - Maximum wait time (default: 20m0s)" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $0 my-model grafana-agent 'status==\"active\"'" >&2
  echo "  $0 my-model cve-scanner 'status==\"active\" || status==\"blocked\"'" >&2
  exit 1
fi

echo "[INFO] Waiting for '$APPLICATION' in model '$MODEL' (query: $STATUS_QUERY, timeout: $TIMEOUT)..." >&2

juju wait-for application "$APPLICATION" \
  --model="$MODEL" \
  --timeout="$TIMEOUT" \
  --query="$STATUS_QUERY"

echo "[INFO] Application '$APPLICATION' is ready" >&2
