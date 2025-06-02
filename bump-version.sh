#!/bin/bash

# Exit on error
set -e

# Check if version is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <new-version>"
    echo "Example: $0 1.1.0"
    exit 1
fi

NEW_VERSION=$1

# Validate version format (X.Y.Z)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

echo "Updating to version $NEW_VERSION..."

# Generate build number (YYYYMMDD)
BUILD_NUMBER=$(date +%Y%m%d)

# Update Version.swift
VERSION_FILE="Sources/WNBASchedule/Version.swift"
if [ -f "$VERSION_FILE" ]; then
    echo "Updating $VERSION_FILE..."
    awk -v ver="$NEW_VERSION" -v build="$BUILD_NUMBER" '
        /static let version =/ { print "    static let version = \"" ver "\""; next }
        /static let build =/ { print "    static let build = \"" build "\""; next }
        { print }
    ' "$VERSION_FILE" > "$VERSION_FILE.new"
    mv "$VERSION_FILE.new" "$VERSION_FILE"
else
    echo "Error: $VERSION_FILE not found"
    exit 1
fi

# Update Info.plist
INFO_FILE="Info/Info.plist"
if [ -f "$INFO_FILE" ]; then
    echo "Updating $INFO_FILE..."
    awk -v ver="$NEW_VERSION" '
        /<key>CFBundleVersion<\/key>/ { print; getline; print "    <string>" ver "</string>"; next }
        /<key>CFBundleShortVersionString<\/key>/ { print; getline; print "    <string>" ver "</string>"; next }
        { print }
    ' "$INFO_FILE" > "$INFO_FILE.new"
    mv "$INFO_FILE.new" "$INFO_FILE"
else
    echo "Error: $INFO_FILE not found"
    exit 1
fi

echo "Version updated to $NEW_VERSION (build $BUILD_NUMBER)"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit the changes: git commit -am \"Bump version to $NEW_VERSION\""
echo "3. Create a tag: git tag v$NEW_VERSION"
echo "4. Push changes and tag: git push && git push --tags"
echo ""
echo "The GitHub workflow will automatically create a release when the tag is pushed."