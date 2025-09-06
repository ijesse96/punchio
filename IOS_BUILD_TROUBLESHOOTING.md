# iOS Build Troubleshooting Guide

## 🚨 **Common Issues and Solutions**

### 1. **Missing GitHub Secrets**
**Error:** `❌ ERROR: TEAM_ID secret is not set!`

**Solution:**
1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add these repository secrets:
   - `TEAM_ID`: Your Apple Developer Team ID (e.g., `MNRC5F55U3`)
   - `APPLE_ID`: Your Apple ID email
   - `APPLE_PASSWORD`: Your Apple ID password or app-specific password

### 2. **Code Signing Issues**
**Error:** `Code signing error` or `Provisioning profile`

**Solutions:**
- ✅ **Automatic Signing**: The workflow uses automatic code signing
- ✅ **Team ID**: Make sure your `TEAM_ID` secret matches your Apple Developer account
- ✅ **Bundle ID**: Verify `com.punchio.punchio` is registered in your Apple Developer account

### 3. **Flutter Build Failures**
**Error:** `Flutter build failed`

**Debugging Steps:**
1. Check the build log for specific errors
2. Verify Flutter dependencies: `flutter pub get`
3. Check iOS configuration: `flutter doctor`
4. Clean build: `flutter clean && flutter pub get`

### 4. **CocoaPods Issues**
**Error:** `Pod install failed`

**Solutions:**
- The workflow automatically runs `pod install --repo-update`
- If issues persist, check the `ios_build_fix.sh` script

## 🔍 **Debugging Your Build**

### **Step 1: Check the Build Log**
When your build fails, look for these patterns in the log:

```bash
# Look for these critical error patterns:
grep -i "error\|failed\|❌" build.log | head -20
grep -i "code.sign\|provisioning" build.log
grep -i "bundle.identifier\|development.team" build.log
```

### **Step 2: Verify Configuration**
The workflow automatically checks:
- ✅ Flutter doctor output
- ✅ iOS project structure
- ✅ Xcode project settings
- ✅ Environment variables
- ✅ Export options

### **Step 3: Common Error Patterns**

#### **Missing Secrets:**
```
❌ ERROR: TEAM_ID secret is not set!
❌ ERROR: APPLE_ID secret is not set!
❌ ERROR: APPLE_PASSWORD secret is not set!
```

#### **Code Signing:**
```
Code signing error: No profiles for 'com.punchio.punchio' were found
Provisioning profile doesn't match bundle identifier
```

#### **Bundle Identifier:**
```
Invalid bundle identifier: com.punchio.punchio
Bundle identifier conflicts with existing app
```

## 🛠️ **Quick Fixes**

### **Fix 1: Update GitHub Secrets**
1. Go to repository Settings → Secrets and variables → Actions
2. Add/update these secrets:
   ```
   TEAM_ID=MNRC5F55U3
   APPLE_ID=your-apple-id@example.com
   APPLE_PASSWORD=your-app-password
   ```

### **Fix 2: Verify Apple Developer Account**
1. Log into [Apple Developer Portal](https://developer.apple.com)
2. Verify your Team ID matches `MNRC5F55U3`
3. Ensure `com.punchio.punchio` bundle ID is registered
4. Check that automatic signing is enabled

### **Fix 3: Local Testing**
Test your configuration locally:
```bash
# Set environment variables
export TEAM_ID="MNRC5F55U3"
export APPLE_ID="your-apple-id@example.com"
export APPLE_PASSWORD="your-app-password"

# Run the build script
chmod +x build_ios.sh
./build_ios.sh
```

## 📊 **Build Process Flow**

1. **Setup**: Flutter, CocoaPods, dependencies
2. **Configuration**: iOS project settings, provisioning
3. **Verification**: Secrets, bundle ID, team ID
4. **Build**: `flutter build ipa` with proper signing
5. **Fallback**: Alternative xcodebuild if Flutter fails
6. **Debugging**: Comprehensive error capture on failure

## 🚀 **Success Indicators**

Your build is working when you see:
- ✅ `All required secrets are available`
- ✅ `iOS build configuration fixed!`
- ✅ `Build completed successfully!`
- ✅ Build artifacts uploaded

## 📞 **Getting Help**

If you're still having issues:

1. **Check the build logs** in GitHub Actions
2. **Download error artifacts** from failed builds
3. **Run the PowerShell analyzer**: `./analyze_build_logs.ps1`
4. **Verify your Apple Developer account** settings
5. **Test locally** with the same environment variables

## 🔧 **Advanced Debugging**

### **Enable Verbose Logging**
The workflow already uses `--verbose` flag for detailed output.

### **Check Specific Components**
```bash
# Check Flutter
flutter doctor -v

# Check iOS configuration
grep -n "DEVELOPMENT_TEAM\|PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj

# Check export options
cat ios/ExportOptions.plist
```

### **Manual Build Steps**
If automated build fails, try manual steps:
```bash
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release
```
