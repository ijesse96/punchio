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
echo "🚀 Running: flutter build ios --release --no-codesign --verbose"
flutter build ios \
  --release \
  --no-codesign \
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

echo "✅ Flutter build completed successfully!"

# Now create IPA using xcodebuild
echo "🚀 Creating IPA archive..."
cd ios

xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/Runner.xcarchive \
  archive 2>&1 | tee xcodebuild.log || {
    echo "❌ Xcode archive failed with exit code $?"
    echo ""
    echo "🔍 Key errors from xcodebuild log:"
    grep -i "error\|failed" xcodebuild.log | head -20
    echo ""
    echo "📋 Full xcodebuild log saved to xcodebuild.log"
    exit 1
  }

echo "✅ Archive created successfully!"

# Export IPA
echo "🚀 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ../ExportOptions.plist 2>&1 | tee export.log || {
    echo "❌ IPA export failed with exit code $?"
    echo ""
    echo "🔍 Key errors from export log:"
    grep -i "error\|failed" export.log | head -20
    echo ""
    echo "📋 Full export log saved to export.log"
    exit 1
  }

echo "✅ IPA export completed successfully!"
cd ..

echo "✅ iOS build and IPA creation completed successfully!"