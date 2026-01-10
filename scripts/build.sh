#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source centralized config
source "$PROJECT_DIR/scripts/config.sh"

BUILD_DIR="$PROJECT_DIR/build"
XCODEPROJ="$PROJECT_DIR/$XCODEPROJ_NAME"
CONFIGURATION="Release"

echo "🔨 Building $APP_NAME..."
echo "📁 Project directory: $PROJECT_DIR"

# Clean build directory
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Build the project
echo "⚙️  Building Release configuration..."
xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 Application: $APP_PATH"
    echo ""

    # Show app info
    echo "📊 App Info:"
    echo "   Bundle ID: $BUNDLE_ID"
    echo "   Version: $(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")"
    echo ""

    # Optionally copy to Applications folder
    read -p "Copy to /Applications? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Kill running instance
        if pgrep -x "$APP_NAME" > /dev/null; then
            echo "🛑 Stopping running instance..."
            pkill -x "$APP_NAME"
            sleep 1
        fi

        # Reset accessibility permissions (required for ad-hoc signed builds)
        echo "🔐 Resetting accessibility permissions..."
        tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

        echo "📋 Copying to /Applications..."
        if [ -d "/Applications/$APP_NAME.app" ]; then
            echo "⚠️  Removing existing app..."
            rm -rf "/Applications/$APP_NAME.app"
        fi
        cp -r "$APP_PATH" /Applications/
        echo "✅ Copied to /Applications/$APP_NAME.app"
        echo ""
        echo "💡 Launch $APP_NAME and grant Accessibility permission when prompted"
    fi
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
