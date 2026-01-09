#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
XCODEPROJ="$PROJECT_DIR/ShortcutOverlay.xcodeproj"
SCHEME="ShortcutOverlay"
CONFIGURATION="Debug"

echo "🚀 Building and running ShortcutOverlay (Debug)..."

# Check if already running and kill it
if pgrep -x "ShortcutOverlay" > /dev/null; then
    echo "🛑 ShortcutOverlay is already running, stopping it..."
    pkill -x "ShortcutOverlay"
    sleep 1
fi

# Build the project
echo "⚙️  Building Debug configuration..."
xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/ShortcutOverlay.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "🎯 Launching ShortcutOverlay..."
    echo ""

    # Open the app
    open "$APP_PATH"

    echo "💡 Tips:"
    echo "   • Look for the keyboard icon in your menu bar"
    echo "   • Press and hold ⌘⌃0 to show shortcuts"
    echo "   • You may need to grant Accessibility permission"
    echo "   • Check Console.app for debug logs"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
