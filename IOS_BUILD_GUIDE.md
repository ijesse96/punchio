# 🍎 iPhone 14 Build Guide

## Option 1: GitHub Actions (Recommended)

### Step 1: Push to GitHub
```bash
git init
git add .
git commit -m "Initial commit with iOS build setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/punchio.git
git push -u origin main
```

### Step 2: Configure GitHub Actions
1. Go to your GitHub repository
2. Go to Settings → Secrets and variables → Actions
3. Add these secrets:
   - `APPLE_ID`: Your Apple Developer email
   - `APPLE_PASSWORD`: App-specific password
   - `TEAM_ID`: Your Apple Developer Team ID
   - `CERTIFICATE`: Your iOS certificate (base64 encoded)
   - `PROVISIONING_PROFILE`: Your provisioning profile (base64 encoded)

### Step 3: Configure Export Options
The project now includes two export configurations:
- `ios/ExportOptions.plist` - Updated for App Store distribution (app-store method)
- `ios/ExportOptions-appstore.plist` - Dedicated App Store export configuration

Both files use your Team ID: `MNRC5F55U3`

### Step 4: Build for App Store/TestFlight
- Push any change to trigger the build
- The build script now uses `app-store` export method by default
- Download the `.ipa` file from Actions → Artifacts
- Upload to App Store Connect for TestFlight or App Store distribution

### Step 5: App Store Distribution Requirements
For App Store/TestFlight distribution, ensure you have:
- **Apple Distribution Certificate** (not Apple Development)
- **App Store Provisioning Profile** (not Development or Ad Hoc)
- **App Store Connect** app record created
- **Bundle ID** matches: `com.punchio.punchio`

## Option 2: Codemagic (Easier)

### Step 1: Sign up at codemagic.io
- Connect your GitHub repository
- Select iOS platform

### Step 2: Configure build
- Add your Apple Developer credentials
- Set up code signing
- Build and download `.ipa`

## Option 3: Local macOS (If you have access)

### Step 1: Install Xcode
- Download from Mac App Store
- Install command line tools

### Step 2: Build
```bash
flutter build ios --release
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS archive
```

## Expected iPhone 14 Performance

- **Latency**: 15-30ms (vs 112ms on Android)
- **Buffer Size**: 256 samples (vs 1920 on Android)
- **IO Buffer**: 5ms (vs ~20ms on Android)
- **Sample Rate**: 48kHz

## Testing on iPhone 14

1. Install the app
2. Grant microphone permissions
3. Toggle "Real-time Monitoring"
4. Check latency display - should show 15-30ms
5. Test with headphones for best results

## Troubleshooting

- **Build fails**: Check Apple Developer account status
- **App won't install**: Check device UDID in provisioning profile
- **High latency**: Ensure you're using wired headphones
- **No audio**: Check microphone permissions in Settings
