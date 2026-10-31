#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
PROFILE_NAME="${1:-}"
APP_PATH="$PROJECT_ROOT/dist/Pumpkin Pop.app"
ARCHIVE_PATH="$PROJECT_ROOT/dist/Pumpkin-Pop-Mac.zip"
REPORT_PATH="$PROJECT_ROOT/.build/notarization"

if [[ -z "$PROFILE_NAME" ]]; then
  printf 'Usage: bash scripts/notarize-mac.sh <local-keychain-profile>\n' >&2
  exit 1
fi
codesign --verify --deep --strict "$APP_PATH"
SIGNATURE_INFO="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1)"
if [[ "$SIGNATURE_INFO" != *"Authority=Developer ID Application:"* ]]; then
  printf 'A Developer ID Application signature is required. Rebuild with MAC_SIGNING_IDENTITY first.\n' >&2
  exit 1
fi
mkdir -p "$REPORT_PATH"
# Always submit an archive of the exact signed bundle being stapled below.
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"
# Credentials remain in the local Keychain, never in arguments or repository files.
xcrun notarytool submit "$ARCHIVE_PATH" --keychain-profile "$PROFILE_NAME" \
  --wait --timeout 10m --output-format json > "$REPORT_PATH/submission.json"
python3 - "$REPORT_PATH/submission.json" <<'PY'
import json, sys
with open(sys.argv[1]) as stream:
    submission = json.load(stream)
print('Notarization submission:', submission.get('id', 'unknown'))
if submission.get('status') != 'Accepted':
    sys.exit('Apple has not accepted this submission. Inspect .build/notarization/submission.json; do not distribute it as notarized.')
PY
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=2 "$APP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"
python3 - "$ARCHIVE_PATH" <<'PY'
from pathlib import Path
import hashlib, sys
archive = Path(sys.argv[1])
archive.with_name('SHA256SUMS.txt').write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
PY
printf 'Apple notarization accepted, ticket stapled, and Gatekeeper assessment passed: %s\n' "$ARCHIVE_PATH"
