#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source centralized config
source "$PROJECT_DIR/scripts/config.sh"

BUILD_DIR="$PROJECT_DIR/build"
XCODEPROJ="$PROJECT_DIR/$XCODEPROJ_NAME"
CONFIGURATION="Debug"

echo "🚀 Building and running $APP_NAME (Debug)..."

# Check if already running and kill it
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "🛑 $APP_NAME is already running, stopping it..."
    pkill -x "$APP_NAME"
    sleep 1
fi

# Build the project
echo "⚙️  Building Debug configuration..."
xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-"

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "🎯 Launching $APP_NAME..."
    echo ""

    # Open the app
    open "$APP_PATH"

    echo "💡 Tips:"
    echo "   • Look for the keyboard icon in your menu bar"
    echo "   • Press and hold your configured hotkey to show shortcuts"
    echo "   • You may need to grant Accessibility permission"
    echo "   • Check Console.app for debug logs"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
