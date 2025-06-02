#!/bin/bash

# Exit on error
set -e

echo "Building WNBASchedule..."
swift build -c release

echo "Creating application bundle..."
APP_DIR="WNBASchedule.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/WNBASchedule "$MACOS_DIR/"

# Copy Info.plist
cp Info/Info.plist "$CONTENTS_DIR/"

# Copy resources
cp Sources/WNBASchedule/Resources/basketball-icon.txt "$RESOURCES_DIR/"

echo "Application bundle created: $APP_DIR"
echo "To run the application, use: open $APP_DIR"