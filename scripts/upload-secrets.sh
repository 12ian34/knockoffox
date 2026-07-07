#!/usr/bin/env bash
set -euo pipefail

# Upload CWS secrets from .env.cws to GitHub repo secrets via gh CLI.
# Usage: ./scripts/upload-secrets.sh [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.cws"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

REQUIRED_KEYS="CWS_CLIENT_ID CWS_CLIENT_SECRET CWS_REFRESH_TOKEN CWS_EXTENSION_ID CWS_PUBLISHER_ID"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

# Source the env file
set -a
source "$ENV_FILE"
set +a

# Validate all required keys
for key in $REQUIRED_KEYS; do
  if [[ -z "${!key:-}" ]]; then
    echo "Error: Missing required key $key in $ENV_FILE"
    exit 1
  fi
done

if ! $DRY_RUN; then
  if ! gh auth status &>/dev/null; then
    echo "Error: Not authenticated with gh. Run: gh auth login"
    exit 1
  fi
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  echo "Uploading secrets to $REPO..."
fi

for key in $REQUIRED_KEYS; do
  VALUE="${!key}"
  if $DRY_RUN; then
    MASKED="${VALUE:0:4}****"
    echo "[dry-run] Would set $key = $MASKED"
  else
    echo "  $key..."
    echo "$VALUE" | gh secret set "$key" --repo "$REPO"
  fi
done

echo "Done."
