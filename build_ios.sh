#!/bin/bash

# iOS Build Script for GitHub Actions
# This script handles the iOS build with proper provisioning

set -e

echo "=== Starting iOS Build ==="

# 1. Setup environment
echo "Setting up build environment..."
export FLUTTER_ROOT=/Users/runner/hostedtoolcache/flutter/stable-3.24.0-arm64
export PATH="$FLUTTER_ROOT/bin:$PATH"

# 2. Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# 3. Setup iOS dependencies
echo "Setting up iOS dependencies..."
cd ios
pod install
cd ..

# 4. Copy provisioning profile if it exists
if [ -f "punchio.mobileprovision" ]; then
    echo "Copying provisioning profile..."
    cp punchio.mobileprovision ios/
fi

# 5. Build the iOS app
echo "Building iOS app..."
flutter build ipa \
    --release \
    --export-options-plist=ios/ExportOptions.plist \
    --verbose

echo "=== iOS Build Complete ==="
echo "IPA file location: build/ios/ipa/"
ls -la build/ios/ipa/
