#!/usr/bin/env bash
set -euo pipefail

# Submit the current version to Firefox Add-ons (AMO) on the listed channel.
# Usage: ./scripts/release-firefox.sh [--lint-only]
#
# Needs AMO_JWT_ISSUER / AMO_JWT_SECRET in .env.amo — create the key pair at
# https://addons.mozilla.org/en-US/developers/addon/api/key/
#
# Listed versions auto-publish once AMO's validation passes (usually minutes).
# The script submits and returns without waiting for approval; check
# https://addons.mozilla.org/en-US/developers/addons for the outcome.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LINT_ONLY=false
[[ "${1:-}" == "--lint-only" ]] && LINT_ONLY=true

VERSION=$(node -e "console.log(require('$ROOT_DIR/manifest.json').version)")

# Same file set as package.sh. Firefox ignores MV3 service_worker and uses
# background.scripts instead, so strip the Chrome-only key in the AMO build.
BUILD_DIR="$(mktemp -d)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR" "$WORK_DIR"' EXIT

cd "$ROOT_DIR"
cp -R manifest.json src data options icons "$BUILD_DIR/"
node -e "
  const fs = require('fs');
  const p = process.argv[1];
  const m = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (m.background) delete m.background.service_worker;
  fs.writeFileSync(p, JSON.stringify(m, null, 2) + '\n');
" "$BUILD_DIR/manifest.json"

echo "Linting Knockoffox v${VERSION} for Firefox..."
npx --yes web-ext@10 lint --source-dir "$BUILD_DIR"

if $LINT_ONLY; then
  echo "Lint OK (--lint-only, skipping submission)."
  exit 0
fi

ENV_FILE="$ROOT_DIR/.env.amo"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found. Copy .env.amo.example and fill in the AMO API key." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
: "${AMO_JWT_ISSUER:?AMO_JWT_ISSUER not set in .env.amo}"
: "${AMO_JWT_SECRET:?AMO_JWT_SECRET not set in .env.amo}"

# First listed AMO submissions require listing metadata and a version license.
# Use the manifest for listing copy, the release-notes file for version notes,
# and the repo license as a custom license because FSL-1.1-MIT is not a
# predefined AMO license slug.
node - "$ROOT_DIR" "$WORK_DIR" "$VERSION" <<'NODE'
const fs = require("fs");
const path = require("path");

const [rootDir, workDir, version] = process.argv.slice(2);
const manifest = JSON.parse(fs.readFileSync(path.join(rootDir, "manifest.json"), "utf8"));
const releaseNotesMd = fs.readFileSync(path.join(rootDir, "store-assets/release-notes.md"), "utf8");
const licenseText = fs.readFileSync(path.join(rootDir, "LICENSE"), "utf8");
const section = releaseNotesMd
  .split(/^## /m)
  .slice(1)
  .find((s) => s.split("\n")[0].trim() === version);
const notes = section ? section.split("\n").slice(1).join("\n").trim() : "";

const metadata = {
  name: { "en-US": manifest.name },
  summary: { "en-US": manifest.description },
  categories: { firefox: ["shopping"] },
  version: {
    custom_license: {
      name: { "en-US": "FSL-1.1-MIT" },
      text: { "en-US": licenseText }
    }
  }
};

if (notes) {
  metadata.version.release_notes = { "en-US": notes };
} else {
  console.error(`Warning: no '## ${version}' section in store-assets/release-notes.md — submitting without version notes.`);
}

fs.writeFileSync(path.join(workDir, "amo-metadata.json"), JSON.stringify(metadata, null, 2) + "\n");
NODE

echo "Submitting Knockoffox v${VERSION} to AMO (listed channel)..."
export WEB_EXT_API_KEY="$AMO_JWT_ISSUER"
export WEB_EXT_API_SECRET="$AMO_JWT_SECRET"
npx --yes web-ext@10 sign \
  --source-dir "$BUILD_DIR" \
  --artifacts-dir "$WORK_DIR/artifacts" \
  --channel listed \
  --approval-timeout 0 \
  --amo-metadata "$WORK_DIR/amo-metadata.json"

echo "Submitted v${VERSION}. AMO publishes automatically after validation:"
echo "  https://addons.mozilla.org/en-US/developers/addons"
