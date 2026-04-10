# Sparkle Auto-Update Setup Guide

This guide explains how to configure Sparkle for automatic updates in BetterFinder.

## Overview

BetterFinder now includes automatic update checking powered by [Sparkle](https://github.com/sparkle-project/Sparkle), the standard framework for macOS app updates.

## Features

- ✅ Automatic updates every 24 hours
- ✅ Manual update check in BetterFinder → Check for Updates…
- ✅ All updates are signed and verified before installation
- ✅ Configure update behavior in Settings → Updates
- ✅ Ed25519 signature verification for security

## Initial Setup

### 1. Generate Ed25519 Keys

Run the key generation script:

```bash
cd /Users/lucabarrella/Documents/BetterFinder
bash bin/generate_keys.sh
```

This will create:
- `sparkle_keys/private_key.pem` - Keep this secret!
- `sparkle_keys/public_key.pem` - Add this to Info.plist

### 2. Add Public Key to Info.plist

Run the print public key script:

```bash
bash bin/print_public_key.sh
```

Copy the output and replace `YOUR_PUBLIC_ED25519_KEY_HERE` in `BetterFinder/Info.plist`:

```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_ED25519_KEY_HERE</string>
```

### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description |
|-------------|-------------|
| `SPARKLE_PRIVATE_KEY` | The private Ed25519 key (contents of `sparkle_keys/private_key.pem` without the "PRIVATE KEY" header/footer) |

To get the private key value:

```bash
cat sparkle_keys/private_key.pem | grep -v "PRIVATE KEY" | tr -d '\n'
```

### 4. Update SUFeedURL in Info.plist

Replace `${GITHUB_REPOSITORY}` in `BetterFinder/Info.plist` with your actual repository:

```xml
<key>SUFeedURL</key>
<string>https://github.com/yourusername/BetterFinder/releases.atom</string>
```

## Building and Releasing

### Local Testing

To test the update mechanism locally:

1. Build the app:
   ```bash
   bash make-release.sh
   ```

2. Test the appcast generation (requires Sparkle CLI):
   ```bash
   brew install sparkle
   generate_appcast build/ --download-url-prefix file://$(pwd)/build/
   ```

### Creating a Release

When you're ready to release a new version:

1. Tag the commit:
   ```bash
   git tag v1.0.0
   git push --tags
   ```

2. The GitHub Actions workflow will automatically:
   - Build and sign the app
   - Notarize the app
   - Generate the appcast.xml
   - Sign the appcast with your private key
   - Create a GitHub Release with the DMG and appcast

3. Users will be notified of the update automatically

## Configuration Options

### Update Settings in Info.plist

| Key | Default | Description |
|-----|---------|-------------|
| `SUEnableAutomaticChecks` | `true` | Enable automatic update checks |
| `SUAutomaticallyUpdate` | `false` | Automatically install updates without prompting |
| `SUScheduledCheckInterval` | `86400` | Check interval in seconds (24 hours) |
| `SUAllowsPrompts` | `true` | Allow prompts for updates |
| `SUShowReleaseNotes` | `true` | Show release notes in update dialog |
| `SUMinimumSystemVersion` | `15.0` | Minimum macOS version required |

### User Preferences

Users can configure update behavior in **BetterFinder → Settings → Updates**:

- Automatically check for updates
- Automatically download updates
- View last check time

## Security

### Ed25519 Signatures

Sparkle uses Ed25519 for cryptographic signatures:

- **Public key**: Embedded in the app (Info.plist)
- **Private key**: Stored securely in GitHub Secrets
- **Appcast**: Signed with private key, verified with public key
- **Updates**: Only signed updates are accepted

### Code Signing & Notarization

All updates are:

1. Code signed with Developer ID Application
2. Notarized by Apple
3. Stapled with notarization ticket
4. Signed with Ed25519 for Sparkle verification

## Troubleshooting

### Updates Not Appearing

1. Check that the appcast.xml is generated correctly
2. Verify the Ed25519 signature is valid
3. Ensure the download URL prefix is correct
4. Check that the version number in the app matches the release tag

### Signature Verification Failed

1. Verify the public key in Info.plist matches the private key
2. Check that the private key in GitHub Secrets is correct
3. Ensure the appcast was signed with the correct private key

### App Won't Launch After Update

1. Verify the app is code signed
2. Check notarization status
3. Ensure the app bundle structure is intact

## Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [Ed25519 Cryptography](https://ed25519.cr.yp.to/)

## Support

For issues with Sparkle integration:

1. Check the [Sparkle Issues](https://github.com/sparkle-project/Sparkle/issues)
2. Review the [Sparkle Documentation](https://sparkle-project.org/documentation/)
3. Open an issue in the BetterFinder repository
