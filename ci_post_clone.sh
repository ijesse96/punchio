#!/bin/sh
set -euxo pipefail

# 1) Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"

flutter --version
flutter pub get
flutter precache --ios

# 2) CocoaPods (usually preinstalled, but safe to run)
cd ios
pod repo update
pod install --repo-update
