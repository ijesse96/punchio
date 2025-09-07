#!/bin/bash

# Generate CSR for Apple Distribution Certificate
# This script creates a Certificate Signing Request for iOS App Store distribution

echo "🔐 Generating CSR for Apple Distribution Certificate..."

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo "❌ OpenSSL is not installed. Please install OpenSSL first."
    echo "💡 On macOS: brew install openssl"
    echo "💡 On Ubuntu: sudo apt-get install openssl"
    exit 1
fi

# Create certificates directory if it doesn't exist
mkdir -p certificates

# Generate 2048-bit RSA private key
echo "🔑 Generating 2048-bit RSA private key..."
openssl genrsa -out certificates/punchio_dist.key 2048

if [ $? -eq 0 ]; then
    echo "✅ Private key generated: certificates/punchio_dist.key"
else
    echo "❌ Failed to generate private key"
    exit 1
fi

# Prompt for Apple ID email
echo ""
echo "📧 Please enter your Apple ID email address:"
read -p "Apple ID: " APPLE_ID

# Prompt for Common Name (your name)
echo ""
echo "👤 Please enter your name (Common Name):"
read -p "Name: " COMMON_NAME

# Prompt for Organization
echo ""
echo "🏢 Please enter your organization name:"
read -p "Organization: " ORGANIZATION

# Generate CSR
echo ""
echo "📝 Generating Certificate Signing Request..."
openssl req -new -sha256 -key certificates/punchio_dist.key -out certificates/punchio_dist.csr \
  -subj "/emailAddress=${APPLE_ID}/CN=${COMMON_NAME}/OU=Mobile/O=${ORGANIZATION}/C=US"

if [ $? -eq 0 ]; then
    echo "✅ CSR generated successfully: certificates/punchio_dist.csr"
    echo ""
    echo "📋 Next steps:"
    echo "1. Go to Apple Developer Portal: https://developer.apple.com/account/resources/certificates/list"
    echo "2. Click '+' to create a new certificate"
    echo "3. Select 'Apple Distribution' certificate type"
    echo "4. Upload the CSR file: certificates/punchio_dist.csr"
    echo "5. Download the generated certificate (.cer file)"
    echo "6. Import the certificate into your keychain"
    echo ""
    echo "🔒 Keep your private key safe: certificates/punchio_dist.key"
    echo "📄 CSR file ready for upload: certificates/punchio_dist.csr"
else
    echo "❌ Failed to generate CSR"
    exit 1
fi
