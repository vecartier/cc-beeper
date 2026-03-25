# Notarization Guide for CC-Beeper

CC-Beeper ships as an ad-hoc signed DMG by default. Ad-hoc signing works fine for direct distribution (GitHub Releases, direct download), but macOS Gatekeeper will warn users on first launch. This guide covers how to notarize the app for a seamless installation experience.

## Prerequisites

- Apple Developer Program membership ($99/year) at [developer.apple.com](https://developer.apple.com)
- A "Developer ID Application" certificate installed in your Keychain (created in Xcode or at developer.apple.com/account/resources/certificates/)
- An app-specific password generated at [appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Passwords

## Local Notarization

Run these commands from the project root after enrolling in the Apple Developer Program:

**1. Build with Developer ID signing:**

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" make dmg
```

Replace `Your Name (TEAMID)` with your certificate's Common Name (find it with `security find-identity -v -p codesigning`).

**2. Submit for notarization:**

```bash
xcrun notarytool submit CC-Beeper.dmg \
  --apple-id YOUR_APPLE_ID \
  --password YOUR_APP_PASSWORD \
  --team-id YOUR_TEAM_ID \
  --wait
```

- `YOUR_APPLE_ID` — your Apple ID email (e.g. `developer@example.com`)
- `YOUR_APP_PASSWORD` — the app-specific password generated at appleid.apple.com
- `YOUR_TEAM_ID` — your 10-character Team ID (visible at developer.apple.com/account)

**3. Staple the notarization ticket to the DMG:**

```bash
xcrun stapler staple CC-Beeper.dmg
```

**4. Verify notarization:**

```bash
spctl --assess --type open --context context:primary-signature CC-Beeper.dmg
```

Expected output: `CC-Beeper.dmg: accepted`

## GitHub Actions Notarization

To enable notarization in CI when pushing a release tag:

**1. Add repository secrets** (Settings > Secrets and variables > Actions):

| Secret | Value |
|--------|-------|
| `APPLE_ID` | Your Apple ID email |
| `APP_PASSWORD` | App-specific password from appleid.apple.com |
| `TEAM_ID` | Your 10-character Team ID |
| `SIGNING_IDENTITY` | `Developer ID Application: Your Name (TEAMID)` |
| `CERTIFICATE_BASE64` | Base64-encoded .p12 certificate (see below) |
| `CERTIFICATE_PASSWORD` | Password for the .p12 certificate |

**2. Export your Developer ID certificate as .p12** and base64-encode it:

```bash
# Export from Keychain Access: right-click cert > Export > .p12 format
# Then base64-encode it:
base64 -i DeveloperIDApplication.p12 | pbcopy
# Paste the output as CERTIFICATE_BASE64 secret
```

**3. Add a keychain import step** before the Build DMG step in `.github/workflows/release.yml`:

```yaml
- name: Import Certificate
  env:
    CERTIFICATE_BASE64: ${{ secrets.CERTIFICATE_BASE64 }}
    CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
  run: |
    echo "$CERTIFICATE_BASE64" | base64 --decode > /tmp/certificate.p12
    security create-keychain -p "" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "" build.keychain
    security import /tmp/certificate.p12 -k build.keychain \
      -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s \
      -k "" build.keychain
```

**4. Update the Build DMG step** to use the secret signing identity:

```yaml
- name: Build DMG
  env:
    SIGNING_IDENTITY: ${{ secrets.SIGNING_IDENTITY }}
  run: ./create-dmg.sh
```

**5. Uncomment the notarization step** in `.github/workflows/release.yml` (it is already present, commented out).

## Without Notarization

If you distribute without notarization, users on macOS will see a Gatekeeper warning on first launch. There are two workarounds:

**Option A — Right-click to open (easiest for users):**
Users right-click (or Control-click) the app in Applications and select "Open". The warning dialog will offer an "Open Anyway" button.

**Option B — Remove quarantine attribute via Terminal:**

```bash
xattr -cr /Applications/CC-Beeper.app
```

This removes the `com.apple.quarantine` extended attribute that triggers Gatekeeper.

Both workarounds are safe. They are appropriate for developer/early-adopter distribution. For general public release, notarization is recommended so users have a frictionless install experience.
