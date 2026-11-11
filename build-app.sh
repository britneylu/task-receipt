#!/bin/bash

# stops the script as soon as any required command fails
set -e

# names the app and all folders used while packaging it
APP_NAME="TaskReceipt"
DISPLAY_NAME="Task Receipt"
BUILD_DIR=".build/release"
DIST_APP="dist/$DISPLAY_NAME.app"
PACKAGE_DIR=$(mktemp -d "/tmp/taskreceipt-build.XXXXXX")
PACKAGE_APP="$PACKAGE_DIR/$DISPLAY_NAME.app"
CONTENTS_DIR="$PACKAGE_APP/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
APPLICATIONS_APP="/Applications/$DISPLAY_NAME.app"
LEGACY_APPLICATIONS_APP="/Applications/$APP_NAME.app"
SIGNING_IDENTITY="Apple Development: britneylu100@yahoo.com (UUBHC67X4C)"
ENTITLEMENTS_FILE="TaskReceipt.entitlements"
PROVISIONING_PROFILE="TaskReceipt.provisionprofile"

# removes the temporary unsigned packaging folder when the script finishes
trap 'rm -rf "$PACKAGE_DIR"' EXIT

# builds an optimized release version of the Swift executable
echo "Building $DISPLAY_NAME..."

swift build -c release --build-system native

# creates a fresh macOS .app folder structure
echo "Creating app bundle..."

# creates the folders macOS expects inside an application bundle
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# copies the executable and icon into their bundle locations
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "ReceiptIcon.icns" "$RESOURCES_DIR/ReceiptIcon.icns"

# copies resource bundles required by firebase and its dependencies
for bundle in "$BUILD_DIR"/*.bundle; do
    [ -d "$bundle" ] || continue
    cp -R "$bundle" "$RESOURCES_DIR/"
done

# includes firebase configuration when the project has been connected
if [ -f "GoogleService-Info.plist" ]; then
    cp "GoogleService-Info.plist" "$RESOURCES_DIR/GoogleService-Info.plist"
fi

# writes the metadata macOS uses to identify and launch the app
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
<dict>

    <key>CFBundleName</key>
    <string>Task Receipt</string>

    <key>CFBundleDisplayName</key>
    <string>Task Receipt</string>

    <key>CFBundleExecutable</key>
    <string>TaskReceipt</string>

    <key>CFBundleIdentifier</key>
    <string>com.britney.taskreceipt</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleVersion</key>
    <string>1.0</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0</string>

    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>

    <key>CFBundleIconFile</key>
    <string>ReceiptIcon</string>

    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>

</dict>
</plist>
EOF

# registers the google callback scheme from firebase configuration
if [ -f "GoogleService-Info.plist" ]; then
    REVERSED_CLIENT_ID=$(
        /usr/libexec/PlistBuddy \
            -c "Print :REVERSED_CLIENT_ID" \
            "GoogleService-Info.plist" 2>/dev/null || true
    )

    if [ -n "$REVERSED_CLIENT_ID" ]; then
        /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$CONTENTS_DIR/Info.plist"
        /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$CONTENTS_DIR/Info.plist"
        /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$CONTENTS_DIR/Info.plist"
        /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED_CLIENT_ID" "$CONTENTS_DIR/Info.plist"
    fi
fi

# stops with a clear message when the apple signing identity is unavailable
if ! security find-identity -v -p codesigning | grep -Fq "$SIGNING_IDENTITY"; then
    echo "Apple Development signing identity was not found"
    echo "Open Xcode Settings, choose Apple Accounts, and install the development certificate"
    exit 1
fi

# stops when xcode has not created the local development provisioning profile yet
if [ ! -f "$PROVISIONING_PROFILE" ]; then
    echo "Task Receipt provisioning profile was not found"
    echo "Build the TaskReceiptSigning helper target in Xcode first"
    exit 1
fi

# embeds the xcode managed profile that authorizes the keychain entitlement
cp "$PROVISIONING_PROFILE" "$CONTENTS_DIR/embedded.provisionprofile"

# signs the complete app so firebase and google can use the shared keychain group
echo "Signing $DISPLAY_NAME..."

# removes finder metadata that apple code signing does not allow inside app bundles
xattr -cr "$PACKAGE_APP"

codesign \
    --force \
    --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS_FILE" \
    --options runtime \
    --timestamp=none \
    "$PACKAGE_APP"

# verifies both the signature and the app bundle structure before installation
codesign --verify --deep --strict --verbose=2 "$PACKAGE_APP"

# keeps a signed distribution copy inside the project folder
rm -rf "$DIST_APP"
mkdir -p "dist"
ditto --norsrc --noextattr "$PACKAGE_APP" "$DIST_APP"

# closes the installed copy before replacing it
echo "Closing old version if it is running..."

osascript -e "tell application \"$DISPLAY_NAME\" to quit" 2>/dev/null || true
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true

# gives macOS a moment to finish shutting down the old process
sleep 1

# replaces the app currently installed in Applications
echo "Installing updated app..."

rm -rf "$APPLICATIONS_APP"
rm -rf "$LEGACY_APPLICATIONS_APP"

cp -R "$PACKAGE_APP" "/Applications/"

# opens the newly installed version
echo "Launching updated app..."

open "$APPLICATIONS_APP"

# prints a confirmation after every step succeeds
echo ""
echo "Done!"
echo "$DISPLAY_NAME has been updated in Applications."
