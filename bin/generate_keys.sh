#!/usr/bin/env bash
# generate_keys.sh - Generate Ed25519 keys for Sparkle
#
# This script generates a new Ed25519 key pair for signing Sparkle appcast.
# The private key should be kept secret and stored in GitHub Secrets.
# The public key should be added to the app's Info.plist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEYS_DIR="$SCRIPT_DIR/../sparkle_keys"
PRIVATE_KEY_FILE="$KEYS_DIR/private_key.pem"
PUBLIC_KEY_FILE="$KEYS_DIR/public_key.pem"

echo "🔐 Generating Ed25519 key pair for Sparkle..."

# Create keys directory if it doesn't exist
mkdir -p "$KEYS_DIR"

# Check if keys already exist
if [[ -f "$PRIVATE_KEY_FILE" && -f "$PUBLIC_KEY_FILE" ]]; then
    echo "⚠️  Keys already exist at:"
    echo "   Private: $PRIVATE_KEY_FILE"
    echo "   Public:  $PUBLIC_KEY_FILE"
    echo ""
    read -p "Do you want to overwrite existing keys? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted."
        exit 1
    fi
fi

# Generate Ed25519 key pair using openssl
openssl genpkey -algorithm Ed25519 -out "$PRIVATE_KEY_FILE"
openssl pkey -in "$PRIVATE_KEY_FILE" -pubout -out "$PUBLIC_KEY_FILE"

echo "✅ Keys generated successfully!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Add the public key to your app's Info.plist:"
echo "   <key>SUPublicEDKey</key>"
echo "   <string>$(cat "$PUBLIC_KEY_FILE" | grep -v "PUBLIC KEY" | tr -d '\n')</string>"
echo ""
echo "2. Store the private key in GitHub Secrets as SPARKLE_PRIVATE_KEY:"
echo "   $(cat "$PRIVATE_KEY_FILE" | grep -v "PRIVATE KEY" | tr -d '\n')"
echo ""
echo "3. Keep the private key file secure and never commit it to git!"
echo ""
echo "🔑 Key locations:"
echo "   Private: $PRIVATE_KEY_FILE"
echo "   Public:  $PUBLIC_KEY_FILE"
