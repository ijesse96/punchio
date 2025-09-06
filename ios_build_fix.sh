#!/bin/bash

# iOS Build Fix Script for GitHub Actions
# This script addresses the provisioning profile issue

echo "=== Fixing iOS Build Configuration ==="

# 1. Copy the provisioning profile to the correct location
if [ -f "punchio.mobileprovision" ]; then
    echo "Copying provisioning profile to iOS directory..."
    cp punchio.mobileprovision ios/
    echo "Provisioning profile copied successfully"
else
    echo "Warning: punchio.mobileprovision not found in root directory"
fi

# 2. Update Xcode project to use the provisioning profile
echo "Updating Xcode project configuration..."

# Set the provisioning profile in the project
PROVISIONING_PROFILE_NAME="punchio"
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

# Add PROVISIONING_PROFILE_SPECIFIER to the build settings
sed -i.bak 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Automatic;\
				PROVISIONING_PROFILE_SPECIFIER = '"$PROVISIONING_PROFILE_NAME"';/g' "$PROJECT_FILE"

echo "Xcode project updated with provisioning profile specifier"

# 3. Verify the configuration
echo "=== Verifying Configuration ==="
echo "Checking for PROVISIONING_PROFILE_SPECIFIER in project file:"
grep -n "PROVISIONING_PROFILE_SPECIFIER" "$PROJECT_FILE" || echo "Not found - will use automatic signing"

echo "=== Configuration Complete ==="
