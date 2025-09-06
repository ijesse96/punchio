# Quick Debugging Commands for iOS Build Issues

## 🔍 **Immediate Actions When Build Fails**

### 1. **Check the Last 50 Lines of Logs**
```bash
# In GitHub Actions, look at the end of the log output
tail -50 build.log
```

### 2. **Search for Specific Error Patterns**
```bash
# Look for these critical patterns in your 5000-line log:
grep -i "error\|failed\|❌" build.log | head -20
grep -i "code.sign\|provisioning" build.log
grep -i "bundle.identifier\|development.team" build.log
```

### 3. **Common iOS Build Issues to Look For**

#### **Code Signing Issues:**
- `Code signing error`
- `Provisioning profile`
- `DEVELOPMENT_TEAM`
- `CODE_SIGN_IDENTITY`

#### **Bundle Identifier Issues:**
- `PRODUCT_BUNDLE_IDENTIFIER`
- `Invalid bundle identifier`

#### **Flutter Issues:**
- `Flutter build failed`
- `pub get failed`
- `Pod install failed`

#### **Xcode Issues:**
- `xcodebuild failed`
- `No such file or directory`
- `Command PhaseScriptExecution failed`

## 🛠️ **Quick Fixes to Try**

### 1. **Add These Debug Steps to Your Workflow:**
```yaml
- name: Debug iOS Configuration
  if: failure()
  run: |
    echo "🔍 Debugging iOS configuration..."
    echo "📋 Flutter doctor:"
    flutter doctor -v
    echo "📋 iOS project structure:"
    ls -la ios/
    echo "📋 Xcode project settings:"
    grep -n "DEVELOPMENT_TEAM\|PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

### 2. **Reduce Verbosity in Build Commands:**
```yaml
# Instead of --verbose, use:
flutter build ios --release --no-codesign
# Or capture errors only:
flutter build ios --release --no-codesign 2>&1 | grep -i "error\|failed"
```

### 3. **Add Log Filtering:**
```yaml
- name: Build with Error Capture
  run: |
    flutter build ios --release --no-codesign 2>&1 | tee build.log
    if [ $? -ne 0 ]; then
      echo "❌ Build failed! Key errors:"
      grep -i "error\|failed" build.log | head -10
      exit 1
    fi
```

## 📊 **Log Analysis Strategy**

### **Step 1: Find the Failure Point**
Look for the last `❌` or `error:` in the log

### **Step 2: Check Context**
Read 10-20 lines before and after the error

### **Step 3: Identify Root Cause**
Common patterns:
- Missing secrets (TEAM_ID, APPLE_ID)
- Wrong bundle identifier
- Code signing configuration
- Missing dependencies

### **Step 4: Apply Fix**
Based on the error, update your workflow or project configuration

## 🚀 **Pro Tips**

1. **Use the optimized workflow** I created above
2. **Run the PowerShell analyzer** on downloaded logs
3. **Focus on the first error** - subsequent errors are often cascading
4. **Check your secrets** are properly set in GitHub repository settings
5. **Verify bundle identifier** matches your Apple Developer account
