#!/bin/bash

# iOS Build Log Analyzer
# This script helps identify key issues in long iOS build logs

echo "🔍 iOS Build Log Analyzer"
echo "========================="

if [ $# -eq 0 ]; then
    echo "Usage: $0 <log_file>"
    echo "Example: $0 build.log"
    exit 1
fi

LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Error: Log file '$LOG_FILE' not found"
    exit 1
fi

echo "📋 Analyzing: $LOG_FILE"
echo "📊 Total lines: $(wc -l < "$LOG_FILE")"
echo ""

# 1. Critical Errors
echo "🚨 CRITICAL ERRORS:"
echo "==================="
grep -i "error\|failed\|❌" "$LOG_FILE" | head -20
echo ""

# 2. Code Signing Issues
echo "🔐 CODE SIGNING ISSUES:"
echo "======================="
grep -i "code.sign\|provisioning\|certificate\|signing" "$LOG_FILE" | head -10
echo ""

# 3. Build Configuration Issues
echo "⚙️ BUILD CONFIGURATION:"
echo "======================="
grep -i "bundle.identifier\|development.team\|provisioning.profile" "$LOG_FILE" | head -10
echo ""

# 4. Flutter-specific Issues
echo "📱 FLUTTER ISSUES:"
echo "=================="
grep -i "flutter\|dart\|pub" "$LOG_FILE" | grep -i "error\|failed" | head -10
echo ""

# 5. Xcode Issues
echo "🛠️ XCODE ISSUES:"
echo "================"
grep -i "xcodebuild\|xcode" "$LOG_FILE" | grep -i "error\|failed" | head -10
echo ""

# 6. CocoaPods Issues
echo "📦 COCOAPODS ISSUES:"
echo "===================="
grep -i "pod\|cocoapods" "$LOG_FILE" | grep -i "error\|failed" | head -10
echo ""

# 7. Summary Statistics
echo "📈 SUMMARY:"
echo "==========="
echo "Total errors: $(grep -i "error" "$LOG_FILE" | wc -l)"
echo "Total warnings: $(grep -i "warning" "$LOG_FILE" | wc -l)"
echo "Build failures: $(grep -i "failed" "$LOG_FILE" | wc -l)"
echo ""

# 8. Most common error patterns
echo "🔍 MOST COMMON ERROR PATTERNS:"
echo "==============================="
grep -i "error" "$LOG_FILE" | sort | uniq -c | sort -nr | head -10
echo ""

echo "✅ Analysis complete!"
echo "💡 Tip: Focus on the CRITICAL ERRORS section first"
