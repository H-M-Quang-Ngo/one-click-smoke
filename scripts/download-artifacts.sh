#!/usr/bin/env bash
#
# Download latest CVE Scanner artifacts from GitHub releases
#
# Downloads:
# - cve-scanner.charm from canonical/cve-scanner-operator releases
# - cve-scanner.snap from canonical/cve-scanner releases
#
# Usage: ./scripts/download-artifacts.sh [output_dir]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$PROJECT_ROOT/artifacts}"

CHARM_REPO="canonical/cve-scanner-operator"
SNAP_REPO="canonical/cve-scanner"

get_latest_asset_url() {
    local repo="$1"
    local extension="$2"
    curl -sS "https://api.github.com/repos/$repo/releases/latest" \
        | jq -r --arg ext "$extension" '.assets[] | select(.name | endswith($ext)) | .browser_download_url' \
        | head -1
}

mkdir -p "$OUTPUT_DIR"

echo "Downloading latest artifacts to: $OUTPUT_DIR"

# Download charm
CHARM_URL=$(get_latest_asset_url "$CHARM_REPO" ".charm")
if [[ -z "$CHARM_URL" ]]; then
    echo "Error: No .charm asset found in $CHARM_REPO releases"
    exit 1
fi
echo "Downloading charm..."
curl -L -f -o "$OUTPUT_DIR/cve-scanner.charm" "$CHARM_URL"

# Download snap
SNAP_URL=$(get_latest_asset_url "$SNAP_REPO" ".snap")
if [[ -z "$SNAP_URL" ]]; then
    echo "Error: No .snap asset found in $SNAP_REPO releases"
    exit 1
fi
echo "Downloading snap..."
curl -L -f -o "$OUTPUT_DIR/cve-scanner.snap" "$SNAP_URL"

echo "Download complete"
