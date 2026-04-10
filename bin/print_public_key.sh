#!/usr/bin/env bash
# print_public_key.sh - Print the public Ed25519 key for Sparkle
#
# This script prints the public key in the format needed for Info.plist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PUBLIC_KEY_FILE="$SCRIPT_DIR/../sparkle_keys/public_key.pem"

if [[ ! -f "$PUBLIC_KEY_FILE" ]]; then
    echo "❌ Public key not found at: $PUBLIC_KEY_FILE"
    echo "   Run bin/generate_keys.sh first to generate the key pair."
    exit 1
fi

echo "📋 Public key for Info.plist:"
echo ""
echo "<key>SUPublicEDKey</key>"
echo "<string>$(cat "$PUBLIC_KEY_FILE" | grep -v "PUBLIC KEY" | tr -d '\n')</string>"
