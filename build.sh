#!/bin/bash

# Exit on error
set -e

# Extract version from Version.swift
VERSION=$(grep -m 1 "static let version = " Sources/WNBASchedule/Version.swift | cut -d '"' -f 2)
BUILD=$(grep -m 1 "static let build = " Sources/WNBASchedule/Version.swift | cut -d '"' -f 2)

echo "Building WNBASchedule version $VERSION (build $BUILD)..."
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

# Sign the application
if [ -n "$APPLE_DEVELOPER_CERTIFICATE_P12_BASE64" ] && [ -n "$APPLE_DEVELOPER_CERTIFICATE_PASSWORD" ]; then
  echo "Code signing the application with Developer ID..."
  
  # Create keychain
  KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
  KEYCHAIN_PASSWORD="temporary-password"
  
  # Create temporary keychain
  security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  
  # Import certificate to keychain
  echo $APPLE_DEVELOPER_CERTIFICATE_P12_BASE64 | base64 --decode > certificate.p12
  security import certificate.p12 -k "$KEYCHAIN_PATH" -P "$APPLE_DEVELOPER_CERTIFICATE_PASSWORD" -T /usr/bin/codesign
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  
  # List available identities to find the correct one
  echo "Available signing identities:"
  security find-identity -v -p codesigning "$KEYCHAIN_PATH"
  
  # Get the first available identity HASH (not the name)
  IDENTITY_HASH=$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -o '[A-F0-9]\{40\}' | head -1)
  
  if [ -z "$IDENTITY_HASH" ]; then
    echo "No signing identity found in keychain. Using ad-hoc signing instead."
    /usr/bin/codesign --force --options runtime --sign - "$APP_DIR" --deep
  else
    echo "Signing with identity hash: $IDENTITY_HASH"
    # Sign the app with entitlements using the hash and specifying the keychain
    /usr/bin/codesign --force --options runtime --entitlements "Info/WNBASchedule.entitlements" \
      --sign "$IDENTITY_HASH" \
      --keychain "$KEYCHAIN_PATH" \
      "$APP_DIR" --deep --timestamp
  fi
  
  # Verify signature
  echo "Verifying signature..."
  codesign -vvv --deep --strict "$APP_DIR" || echo "Warning: Signature verification failed, but continuing..."
  
  # Clean up
  rm certificate.p12
else
  echo "No Developer ID certificate provided, using ad-hoc signing instead..."
  
  # Check if entitlements file exists and is readable
  if [ -r "Info/WNBASchedule.entitlements" ]; then
    echo "Using entitlements file..."
    # Ad-hoc signing with entitlements
    /usr/bin/codesign --force --options runtime --entitlements "Info/WNBASchedule.entitlements" --sign - "$APP_DIR" --deep
  else
    echo "Entitlements file not found or not readable, using basic ad-hoc signing..."
    # Basic ad-hoc signing without entitlements
    /usr/bin/codesign --force --options runtime --sign - "$APP_DIR" --deep
  fi
  
  echo "Note: App is signed with ad-hoc signature. Users will need to right-click and select Open"
  echo "or use 'xattr -cr WNBASchedule.app' after downloading to bypass Gatekeeper."
fi

echo "Application bundle created: $APP_DIR"
echo "To run the application, use: open $APP_DIR"