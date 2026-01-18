#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source centralized config
source "$PROJECT_DIR/scripts/config.sh"

BUILD_DIR="$PROJECT_DIR/build"
XCODEPROJ="$PROJECT_DIR/$XCODEPROJ_NAME"
CONFIGURATION="Debug"

echo "Building $APP_NAME (Debug)..."

# Build the project
echo "Building Debug configuration..."
xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="-"

APP_PATH="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "Build successful!"
    echo "App location: $APP_PATH"
else
    echo ""
    echo "Build failed!"
    exit 1
fi
