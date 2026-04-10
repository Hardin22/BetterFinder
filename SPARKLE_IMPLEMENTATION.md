# Sparkle Auto-Update Implementation - Summary

## Overview

Successfully implemented automatic update functionality for BetterFinder using [Sparkle](https://github.com/sparkle-project/Sparkle) framework.

## What Was Implemented

### 1. Sparkle Integration ✅

**Added Sparkle as SPM Dependency:**
- Modified `BetterFinder.xcodeproj/project.pbxproj`
- Added Sparkle 2.6.0+ as Swift Package Manager dependency
- Configured framework linking

**Created UpdateManager.swift:**
- `BetterFinder/Services/UpdateManager.swift`
- Manages automatic update checking
- Provides ObservableObject for SwiftUI integration
- Handles update preferences and notifications

**Integrated in BetterFinderApp.swift:**
- Added `@StateObject private var updateManager = UpdateManager()`
- Passed updateManager to environment
- Added "Check for Updates…" command in BetterFinder menu
- Integrated updateManager in Settings window

### 2. User Interface ✅

**Created UpdatesPreferencesView.swift:**
- `BetterFinder/Views/Preferences/UpdatesPreferencesView.swift`
- Added "Updates" tab in Preferences
- Controls for automatic update checking
- Controls for automatic download
- Display of last check time
- Information about Sparkle

**Updated PreferencesView.swift:**
- Added Updates tab to TabView
- Integrated updateManager environment

### 3. GitHub Actions Workflow ✅

**Modified `.github/workflows/release.yml`:**
- Added Sparkle CLI installation step
- Added appcast.xml generation step
- Added appcast signing step
- Updated release notes to mention auto-update feature
- Configured to upload appcast.xml to releases

### 4. Key Management ✅

**Created Key Generation Scripts:**
- `bin/generate_keys.sh` - Generates Ed25519 key pair
- `bin/print_public_key.sh` - Prints public key for Info.plist
- Made scripts executable

**Updated .gitignore:**
- Added `sparkle_keys/` to protect private keys

### 5. Configuration Files ✅

**Updated Info.plist:**
- Added Sparkle configuration keys:
  - `SUFeedURL` - Appcast feed URL
  - `SUPublicEDKey` - Public Ed25519 key (placeholder)
  - `SUEnableAutomaticChecks` - Enable automatic checks
  - `SUAutomaticallyUpdate` - Auto-install updates
  - `SUScheduledCheckInterval` - Check interval (24 hours)
  - `SUAllowsPrompts` - Allow update prompts
  - `SUShowReleaseNotes` - Show release notes
  - `SUMinimumSystemVersion` - Minimum macOS version

**Created Documentation:**
- `SPARKLE_SETUP.md` - Complete setup guide for developers
- Updated `README.md` - Added auto-update section

## Files Modified/Created

### Modified Files:
1. `BetterFinder.xcodeproj/project.pbxproj` - Added Sparkle dependency
2. `BetterFinder/BetterFinderApp.swift` - Integrated UpdateManager
3. `BetterFinder/Views/Preferences/PreferencesView.swift` - Added Updates tab
4. `BetterFinder/Info.plist` - Added Sparkle configuration
5. `.github/workflows/release.yml` - Added appcast generation
6. `.gitignore` - Protected private keys
7. `README.md` - Added auto-update documentation

### Created Files:
1. `BetterFinder/Services/UpdateManager.swift` - Update management
2. `BetterFinder/Views/Preferences/UpdatesPreferencesView.swift` - Updates UI
3. `bin/generate_keys.sh` - Key generation script
4. `bin/print_public_key.sh` - Public key printer
5. `SPARKLE_SETUP.md` - Setup documentation

## Next Steps to Complete Setup

### 1. Generate Ed25519 Keys

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

Copy the output and replace `YOUR_PUBLIC_ED25519_KEY_HERE` in `BetterFinder/Info.plist`.

### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

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

### 5. Test the Implementation

Build and test the app:

```bash
bash make-release.sh
```

Verify that:
- The "Updates" tab appears in Settings
- Update preferences work correctly
- The "Check for Updates…" command appears in the BetterFinder menu

### 6. Create First Release

When ready to release:

```bash
git tag v1.0.0
git push --tags
```

The GitHub Actions workflow will automatically:
- Build and sign the app
- Notarize the app
- Generate the appcast.xml
- Sign the appcast with your private key
- Create a GitHub Release with the DMG and appcast

## Features Implemented

✅ **Automatic Update Checking**
- Checks for updates every 24 hours
- Configurable in Settings → Updates

✅ **Manual Update Check**
- BetterFinder → Check for Updates…
- Keyboard shortcut support

✅ **Update Preferences**
- Toggle automatic checking
- Toggle automatic downloading
- View last check time

✅ **Security**
- Ed25519 signature verification
- Code signing integration
- Notarization support

✅ **User Experience**
- Release notes display
- Update progress indication
- Silent background checks

## Testing Checklist

- [ ] Generate Ed25519 keys
- [ ] Add public key to Info.plist
- [ ] Configure GitHub Secrets
- [ ] Update SUFeedURL in Info.plist
- [ ] Build and test locally
- [ ] Verify Updates tab in Settings
- [ ] Test "Check for Updates…" command
- [ ] Create test release
- [ ] Verify appcast generation
- [ ] Test update installation

## Troubleshooting

### Build Errors

If you encounter build errors related to Sparkle:

1. Clean build folder: `Product → Clean Build Folder`
2. Reset package caches: `File → Packages → Reset Package Caches`
3. Rebuild the project

### Update Not Working

If updates don't appear:

1. Verify the public key in Info.plist
2. Check GitHub Secrets are configured
3. Verify the appcast.xml is generated
4. Check the download URL prefix

### Signature Verification Failed

If signature verification fails:

1. Verify the private key in GitHub Secrets
2. Ensure the public key matches the private key
3. Check that the appcast was signed correctly

## Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [SPARKLE_SETUP.md](SPARKLE_SETUP.md) - Detailed setup guide

## Support

For issues with Sparkle integration:

1. Check the [Sparkle Issues](https://github.com/sparkle-project/Sparkle/issues)
2. Review the [Sparkle Documentation](https://sparkle-project.org/documentation/)
3. Open an issue in the BetterFinder repository

---

**Implementation Date:** 2026-04-10
**Sparkle Version:** 2.6.0+
**Status:** ✅ Complete (pending configuration)
