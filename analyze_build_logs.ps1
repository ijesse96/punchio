# iOS Build Log Analyzer (PowerShell)
# This script helps identify key issues in long iOS build logs

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile
)

Write-Host "🔍 iOS Build Log Analyzer" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

if (-not (Test-Path $LogFile)) {
    Write-Host "❌ Error: Log file '$LogFile' not found" -ForegroundColor Red
    exit 1
}

$totalLines = (Get-Content $LogFile | Measure-Object -Line).Lines
Write-Host "📋 Analyzing: $LogFile" -ForegroundColor Yellow
Write-Host "📊 Total lines: $totalLines" -ForegroundColor Yellow
Write-Host ""

# 1. Critical Errors
Write-Host "🚨 CRITICAL ERRORS:" -ForegroundColor Red
Write-Host "===================" -ForegroundColor Red
Get-Content $LogFile | Select-String -Pattern "error|failed|❌" -CaseSensitive:$false | Select-Object -First 20
Write-Host ""

# 2. Code Signing Issues
Write-Host "🔐 CODE SIGNING ISSUES:" -ForegroundColor Magenta
Write-Host "=======================" -ForegroundColor Magenta
Get-Content $LogFile | Select-String -Pattern "code.sign|provisioning|certificate|signing" -CaseSensitive:$false | Select-Object -First 10
Write-Host ""

# 3. Build Configuration Issues
Write-Host "⚙️ BUILD CONFIGURATION:" -ForegroundColor Blue
Write-Host "=======================" -ForegroundColor Blue
Get-Content $LogFile | Select-String -Pattern "bundle.identifier|development.team|provisioning.profile" -CaseSensitive:$false | Select-Object -First 10
Write-Host ""

# 4. Flutter-specific Issues
Write-Host "📱 FLUTTER ISSUES:" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Get-Content $LogFile | Select-String -Pattern "flutter|dart|pub" -CaseSensitive:$false | Where-Object { $_.Line -match "error|failed" } | Select-Object -First 10
Write-Host ""

# 5. Xcode Issues
Write-Host "🛠️ XCODE ISSUES:" -ForegroundColor DarkYellow
Write-Host "================" -ForegroundColor DarkYellow
Get-Content $LogFile | Select-String -Pattern "xcodebuild|xcode" -CaseSensitive:$false | Where-Object { $_.Line -match "error|failed" } | Select-Object -First 10
Write-Host ""

# 6. CocoaPods Issues
Write-Host "📦 COCOAPODS ISSUES:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Get-Content $LogFile | Select-String -Pattern "pod|cocoapods" -CaseSensitive:$false | Where-Object { $_.Line -match "error|failed" } | Select-Object -First 10
Write-Host ""

# 7. Summary Statistics
Write-Host "📈 SUMMARY:" -ForegroundColor White
Write-Host "===========" -ForegroundColor White
$errorCount = (Get-Content $LogFile | Select-String -Pattern "error" -CaseSensitive:$false).Count
$warningCount = (Get-Content $LogFile | Select-String -Pattern "warning" -CaseSensitive:$false).Count
$failureCount = (Get-Content $LogFile | Select-String -Pattern "failed" -CaseSensitive:$false).Count

Write-Host "Total errors: $errorCount" -ForegroundColor Red
Write-Host "Total warnings: $warningCount" -ForegroundColor Yellow
Write-Host "Build failures: $failureCount" -ForegroundColor Red
Write-Host ""

# 8. Most common error patterns
Write-Host "🔍 MOST COMMON ERROR PATTERNS:" -ForegroundColor White
Write-Host "===============================" -ForegroundColor White
$errorLines = Get-Content $LogFile | Select-String -Pattern "error" -CaseSensitive:$false
$errorLines | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "$($_.Count): $($_.Name)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "✅ Analysis complete!" -ForegroundColor Green
Write-Host "💡 Tip: Focus on the CRITICAL ERRORS section first" -ForegroundColor Yellow
