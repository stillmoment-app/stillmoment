#!/bin/bash
# Creates App Store Connect API Key JSON from .p8 file
# Usage: ./scripts/create-api-key-json.sh

set -e

P8_FILE="$HOME/.fastlane/stillmoment-appstore.p8"
JSON_FILE="$HOME/.fastlane/stillmoment-appstore.json"

if [ ! -f "$P8_FILE" ]; then
    echo "Error: .p8 file not found at $P8_FILE"
    exit 1
fi

if [ -z "$APP_STORE_CONNECT_KEY_ID" ] || [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    echo "Error: Environment variables not set."
    echo "Please set:"
    echo "  export APP_STORE_CONNECT_KEY_ID='your_key_id'"
    echo "  export APP_STORE_CONNECT_ISSUER_ID='your_issuer_id'"
    exit 1
fi

# Read .p8 and escape newlines for JSON
KEY_CONTENT=$(cat "$P8_FILE" | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# Create JSON file
cat > "$JSON_FILE" << EOF
{
  "key_id": "$APP_STORE_CONNECT_KEY_ID",
  "issuer_id": "$APP_STORE_CONNECT_ISSUER_ID",
  "key": "$KEY_CONTENT",
  "in_house": false
}
EOF

chmod 600 "$JSON_FILE"
echo "Created: $JSON_FILE"
