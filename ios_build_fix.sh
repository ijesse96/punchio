#!/bin/bash

# iOS Build Fix Script for GitHub Actions
# This script fixes common iOS build issues in CI/CD environments

set -e

echo "🔧 Fixing iOS build configuration for CI/CD..."

# Navigate to iOS directory
cd ios

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
rm -rf Pods/
rm -rf Podfile.lock

# Update CocoaPods
echo "📦 Updating CocoaPods..."
pod install --repo-update

# Fix Xcode project configuration for CI
echo "⚙️ Configuring Xcode project for CI..."

# Create a backup of the original project file
cp Runner.xcodeproj/project.pbxproj Runner.xcodeproj/project.pbxproj.backup

# Fix bundle identifier - remove the team ID prefix
sed -i '' 's/MNRC5F55U3\.com\.punchio\.punchio/com.punchio.punchio/g' Runner.xcodeproj/project.pbxproj
sed -i '' 's/MNRC5F55U3\.com\.punchio\.punchio/com.punchio.punchio/g' Runner.xcodeproj/project.pbxproj

# Set development team to empty for automatic signing
sed -i '' 's/DEVELOPMENT_TEAM = MNR5F55U3;/DEVELOPMENT_TEAM = "";/g' Runner.xcodeproj/project.pbxproj
sed -i '' 's/DEVELOPMENT_TEAM = MNR5F55U3;/DEVELOPMENT_TEAM = "";/g' Runner.xcodeproj/project.pbxproj

# Ensure code signing style is automatic
sed -i '' 's/CODE_SIGN_STYLE = Manual;/CODE_SIGN_STYLE = Automatic;/g' Runner.xcodeproj/project.pbxproj
sed -i '' 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Automatic;/g' Runner.xcodeproj/project.pbxproj

# Remove provisioning profile specifier
sed -i '' 's/PROVISIONING_PROFILE_SPECIFIER = .*;/PROVISIONING_PROFILE_SPECIFIER = "";/g' Runner.xcodeproj/project.pbxproj
sed -i '' 's/PROVISIONING_PROFILE_SPECIFIER = "";/PROVISIONING_PROFILE_SPECIFIER = "";/g' Runner.xcodeproj/project.pbxproj

# Additional fixes for CI environment
echo "🔧 Applying additional CI fixes..."

# Set code signing identity to automatic
sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Developer";/CODE_SIGN_IDENTITY = "Apple Development";/g' Runner.xcodeproj/project.pbxproj
sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Distribution";/CODE_SIGN_IDENTITY = "Apple Development";/g' Runner.xcodeproj/project.pbxproj

# Ensure automatic provisioning is enabled
sed -i '' 's/PROVISIONING_PROFILE_REQUIRED = YES;/PROVISIONING_PROFILE_REQUIRED = NO;/g' Runner.xcodeproj/project.pbxproj

echo "✅ iOS build configuration fixed!"
echo "📋 Configuration summary:"
echo "   - Bundle ID: com.punchio.punchio"
echo "   - Code Signing: Automatic"
echo "   - Development Team: (empty for CI)"
echo "   - Provisioning Profile: (empty for CI)"

cd ..

echo "🚀 Ready to build iOS app!"