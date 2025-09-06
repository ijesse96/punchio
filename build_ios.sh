#!/bin/bash

# Set environment variables for build
export FLUTTER_BUILD_MODE=release

echo "🔍 Debug: Starting iOS build with Apple Developer account..."
echo "📋 Current configuration:"
echo "   - Team ID: ${TEAM_ID:-'NOT SET'}"
echo "   - Bundle ID: com.punchio.punchio"
echo "   - Build mode: release"
echo "   - Apple ID: ${APPLE_ID:-'NOT SET'}"

# Verify secrets are available
if [ -z "$TEAM_ID" ]; then
  echo "❌ ERROR: TEAM_ID environment variable is not set!"
  echo "💡 Make sure to set TEAM_ID in your GitHub repository secrets"
  exit 1
fi
if [ -z "$APPLE_ID" ]; then
  echo "❌ ERROR: APPLE_ID environment variable is not set!"
  echo "💡 Make sure to set APPLE_ID in your GitHub repository secrets"
  exit 1
fi
if [ -z "$APPLE_PASSWORD" ]; then
  echo "❌ ERROR: APPLE_PASSWORD environment variable is not set!"
  echo "💡 Make sure to set APPLE_PASSWORD in your GitHub repository secrets"
  exit 1
fi

echo "✅ All required environment variables are set"

# Build iOS app with proper code signing using Apple Developer account
echo "🚀 Running: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --verbose"
flutter build ipa \
  --release \
  --export-options-plist=ios/ExportOptions.plist \
  --verbose 2>&1 | tee build.log || {
    echo "❌ Flutter build failed with exit code $?"
    echo ""
    echo "🔍 Key errors from build log:"
    grep -i "error\|failed\|❌" build.log | head -20
    echo ""
    echo "🔍 Checking build directory contents..."
    ls -la build/ || echo "No build directory found"
    ls -la ios/build/ || echo "No ios/build directory found"
    echo ""
    echo "🔍 Checking Flutter doctor..."
    flutter doctor -v
    echo ""
    echo "📋 Full build log saved to build.log"
    exit 1
  }

echo "✅ iOS build completed successfully!"