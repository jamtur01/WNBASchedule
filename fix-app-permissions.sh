#!/bin/bash

# This script removes the quarantine attribute from the WNBASchedule app
# Run this if you're having trouble opening the app due to Gatekeeper restrictions

echo "Removing quarantine attribute from WNBASchedule.app..."

# Check if the app is in the current directory
if [ -d "WNBASchedule.app" ]; then
    xattr -c WNBASchedule.app
    echo "Done! Try opening the app now."
# Check if the app is in the Applications folder
elif [ -d "/Applications/WNBASchedule.app" ]; then
    xattr -c /Applications/WNBASchedule.app
    echo "Done! Try opening the app now."
else
    echo "WNBASchedule.app not found in current directory or Applications folder."
    echo "Please drag the app to this window and press Enter:"
    read APP_PATH
    
    if [ -d "$APP_PATH" ]; then
        xattr -c "$APP_PATH"
        echo "Done! Try opening the app now."
    else
        echo "Invalid path. Please make sure WNBASchedule.app exists."
    fi
fi

echo "Press Enter to exit..."
read