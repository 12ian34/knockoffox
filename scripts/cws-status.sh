#!/usr/bin/env bash
set -euo pipefail

# Check current Chrome Web Store submission status for Knockoff.
# Usage: ./scripts/cws-status.sh [--json] [--env-file path]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.cws"
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

# Load env
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  export "$key=$value"
done < "$ENV_FILE"

for var in CWS_CLIENT_ID CWS_CLIENT_SECRET CWS_REFRESH_TOKEN CWS_EXTENSION_ID CWS_PUBLISHER_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "Error: Missing $var"
    exit 1
  fi
done

LOCAL_VERSION=$(node -e "console.log(require('$ROOT_DIR/manifest.json').version)")

# Get access token
TOKEN_RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=$CWS_CLIENT_ID" \
  -d "client_secret=$CWS_CLIENT_SECRET" \
  -d "refresh_token=$CWS_REFRESH_TOKEN" \
  -d "grant_type=refresh_token")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  if (d.error) { console.error('Auth error:', d.error_description || d.error); process.exit(1); }
  console.log(d.access_token);
")

# Fetch status
STATUS_RESPONSE=$(curl -s \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "x-goog-api-version: 2" \
  "https://chromewebstore.googleapis.com/v2/publishers/${CWS_PUBLISHER_ID}/items/${CWS_EXTENSION_ID}:fetchStatus")

# Parse response
node -e "
const fs = require('fs');
const status = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
const localVersion = '$LOCAL_VERSION';
const jsonOutput = $JSON_OUTPUT;

const publishedChannel = (status.publishedItemRevisionStatus?.distributionChannels || [])[0];
const publishedVersion = publishedChannel?.crxVersion || 'unknown';
const publishedState = status.publishedItemRevisionStatus?.lifecycleStatus || 'unknown';

const submittedChannel = (status.submittedItemRevisionStatus?.distributionChannels || [])[0];
const submittedVersion = submittedChannel?.crxVersion || publishedVersion;
const submittedState = status.submittedItemRevisionStatus?.lifecycleStatus || 'none';

const upToDate = localVersion === publishedVersion;
const pendingReview = submittedState === 'PENDING_REVIEW';

if (jsonOutput) {
  console.log(JSON.stringify({
    itemId: '$CWS_EXTENSION_ID',
    localVersion,
    publishedVersion,
    publishedState,
    submittedVersion,
    submittedState,
    upToDate,
    pendingReview
  }, null, 2));
} else {
  console.log('Knockoff Chrome Web Store Status');
  console.log('================================');
  console.log('Local version:     ' + localVersion);
  console.log('Published version: ' + publishedVersion);
  console.log('Published state:   ' + publishedState);
  console.log('Submitted version: ' + submittedVersion);
  console.log('Submitted state:   ' + submittedState);
  console.log('Up to date:        ' + (upToDate ? 'Yes' : 'No'));
  if (pendingReview) console.log('Version ' + submittedVersion + ' is pending review');
  if (!upToDate && !pendingReview) console.log('New version ' + localVersion + ' ready to publish');
}
" <<< "$STATUS_RESPONSE"
