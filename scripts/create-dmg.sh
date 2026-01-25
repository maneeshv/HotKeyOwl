#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source centralized config
source "$PROJECT_DIR/scripts/config.sh"

BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

# Get version from app bundle
get_version() {
    if [ -d "$APP_PATH" ]; then
        defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0"
    else
        echo "1.0.0"
    fi
}

VERSION=$(get_version)
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
VOLUME_NAME="$APP_NAME"
TEMP_DIR="$BUILD_DIR/dmg-temp"

echo "📦 Creating DMG for $APP_NAME v$VERSION..."
echo ""

# Check if release build exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Release build not found at: $APP_PATH"
    echo ""
    read -p "Would you like to build the release version now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$PROJECT_DIR/scripts/build.sh"
        VERSION=$(get_version)
        DMG_NAME="$APP_NAME-$VERSION.dmg"
        DMG_PATH="$BUILD_DIR/$DMG_NAME"
    else
        echo "Run './scripts/build.sh' first to create a release build."
        exit 1
    fi
fi

# Clean up any existing temp directory and DMG
if [ -d "$TEMP_DIR" ]; then
    echo "🧹 Cleaning up previous temp directory..."
    rm -rf "$TEMP_DIR"
fi

if [ -f "$DMG_PATH" ]; then
    echo "🧹 Removing existing DMG..."
    rm -f "$DMG_PATH"
fi

# Create temporary directory for DMG contents
echo "📁 Preparing DMG contents..."
mkdir -p "$TEMP_DIR"

# Copy the app to temp directory
cp -r "$APP_PATH" "$TEMP_DIR/"

# Create symbolic link to Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Calculate size needed for DMG (app size + padding)
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 10))  # Add 10MB padding

echo "💿 Creating DMG image..."

# Create the DMG
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

# Clean up temp directory
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

# Generate SHA256 checksum
echo ""
echo "🔐 Generating checksum..."
CHECKSUM=$(shasum -a 256 "$DMG_PATH" | cut -d' ' -f1)

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "📊 Details:"
echo "   File: $DMG_PATH"
echo "   Size: $(du -h "$DMG_PATH" | cut -f1)"
echo "   SHA256: $CHECKSUM"
echo ""
echo "📝 Installation instructions for users:"
echo "   1. Mount the DMG by double-clicking it"
echo "   2. Drag $APP_NAME to the Applications folder"
echo "   3. Eject the DMG"
echo "   4. On first launch, if blocked by Gatekeeper:"
echo "      - System Settings → Privacy & Security → 'Open Anyway'"
echo "      - Or run: xattr -cr /Applications/$APP_NAME.app"
echo ""

# Save checksum to file
CHECKSUM_FILE="$BUILD_DIR/$DMG_NAME.sha256"
echo "$CHECKSUM  $DMG_NAME" > "$CHECKSUM_FILE"
echo "💾 Checksum saved to: $CHECKSUM_FILE"
