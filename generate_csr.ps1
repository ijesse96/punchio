# Generate CSR for Apple Distribution Certificate
# PowerShell script for Windows users

Write-Host "🔐 Generating CSR for Apple Distribution Certificate..." -ForegroundColor Green

# Check if OpenSSL is available
try {
    $null = Get-Command openssl -ErrorAction Stop
    Write-Host "✅ OpenSSL found" -ForegroundColor Green
} catch {
    Write-Host "❌ OpenSSL is not installed or not in PATH" -ForegroundColor Red
    Write-Host "💡 Please install OpenSSL:" -ForegroundColor Yellow
    Write-Host "   - Download from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
    Write-Host "   - Or use Chocolatey: choco install openssl" -ForegroundColor Yellow
    exit 1
}

# Create certificates directory if it doesn't exist
if (!(Test-Path "certificates")) {
    New-Item -ItemType Directory -Path "certificates" | Out-Null
    Write-Host "📁 Created certificates directory" -ForegroundColor Green
}

# Generate 2048-bit RSA private key
Write-Host "🔑 Generating 2048-bit RSA private key..." -ForegroundColor Yellow
$keyResult = & openssl genrsa -out certificates/punchio_dist.key 2048 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Private key generated: certificates/punchio_dist.key" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to generate private key" -ForegroundColor Red
    Write-Host $keyResult -ForegroundColor Red
    exit 1
}

# Prompt for Apple ID email
Write-Host ""
$appleId = Read-Host "📧 Please enter your Apple ID email address"

# Prompt for Common Name (your name)
Write-Host ""
$commonName = Read-Host "👤 Please enter your name (Common Name)"

# Prompt for Organization
Write-Host ""
$organization = Read-Host "🏢 Please enter your organization name"

# Generate CSR
Write-Host ""
Write-Host "📝 Generating Certificate Signing Request..." -ForegroundColor Yellow
$csrResult = & openssl req -new -sha256 -key certificates/punchio_dist.key -out certificates/punchio_dist.csr -subj "/emailAddress=$appleId/CN=$commonName/OU=Mobile/O=$organization/C=US" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ CSR generated successfully: certificates/punchio_dist.csr" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to Apple Developer Portal: https://developer.apple.com/account/resources/certificates/list" -ForegroundColor White
    Write-Host "2. Click '+' to create a new certificate" -ForegroundColor White
    Write-Host "3. Select 'Apple Distribution' certificate type" -ForegroundColor White
    Write-Host "4. Upload the CSR file: certificates/punchio_dist.csr" -ForegroundColor White
    Write-Host "5. Download the generated certificate (.cer file)" -ForegroundColor White
    Write-Host "6. Import the certificate into your keychain" -ForegroundColor White
    Write-Host ""
    Write-Host "🔒 Keep your private key safe: certificates/punchio_dist.key" -ForegroundColor Yellow
    Write-Host "📄 CSR file ready for upload: certificates/punchio_dist.csr" -ForegroundColor Yellow
} else {
    Write-Host "❌ Failed to generate CSR" -ForegroundColor Red
    Write-Host $csrResult -ForegroundColor Red
    exit 1
}
