# 🔐 Apple Distribution Certificate Guide

This guide walks you through generating a CSR (Certificate Signing Request) and obtaining an Apple Distribution certificate for App Store distribution.

## Prerequisites

- Apple Developer Account (paid membership required)
- OpenSSL installed on your system
- Access to Apple Developer Portal

## Step 1: Generate CSR

### Option A: Using the provided script (Recommended)

#### For macOS/Linux:
```bash
./generate_csr.sh
```

#### For Windows:
```powershell
.\generate_csr.ps1
```

### Option B: Manual OpenSSL commands

```bash
# Create certificates directory
mkdir certificates

# Generate 2048-bit RSA private key
openssl genrsa -out certificates/punchio_dist.key 2048

# Generate CSR (replace with your details)
openssl req -new -sha256 -key certificates/punchio_dist.key -out certificates/punchio_dist.csr \
  -subj "/emailAddress=YOUR_APPLE_ID@example.com/CN=Your Name/OU=Mobile/O=Your Organization/C=US"
```

## Step 2: Upload CSR to Apple Developer Portal

1. **Go to Apple Developer Portal**
   - Visit: https://developer.apple.com/account/resources/certificates/list
   - Sign in with your Apple ID

2. **Create New Certificate**
   - Click the "+" button
   - Select "Apple Distribution" under "Software"
   - Click "Continue"

3. **Upload CSR**
   - Click "Choose File"
   - Select `certificates/punchio_dist.csr`
   - Click "Continue"

4. **Download Certificate**
   - Click "Download" to get the `.cer` file
   - Save it as `certificates/punchio_dist.cer`

## Step 3: Install Certificate

### On macOS:
1. Double-click the `.cer` file
2. It will open in Keychain Access
3. Make sure it's in the "login" keychain
4. Verify the certificate shows "Apple Distribution: Your Name"

### On Windows:
1. Double-click the `.cer` file
2. Click "Install Certificate"
3. Choose "Current User" or "Local Machine"
4. Select "Place all certificates in the following store"
5. Click "Browse" and select "Personal"
6. Click "Next" and "Finish"

## Step 4: Export Certificate for CI/CD

For GitHub Actions or other CI/CD systems, you'll need to export the certificate:

### On macOS:
```bash
# Export certificate and private key as .p12 file
openssl pkcs12 -export -out certificates/punchio_dist.p12 \
  -inkey certificates/punchio_dist.key \
  -in certificates/punchio_dist.cer \
  -name "Apple Distribution: Your Name"
```

### On Windows:
Use Keychain Access or Certificate Manager to export as .p12

## Step 5: Configure CI/CD

### GitHub Actions Secrets:
Add these secrets to your repository:
- `CERTIFICATE`: Base64 encoded .p12 file
- `CERTIFICATE_PASSWORD`: Password for the .p12 file
- `PROVISIONING_PROFILE`: Base64 encoded provisioning profile

### Encode files for GitHub Secrets:
```bash
# Encode certificate
base64 -i certificates/punchio_dist.p12 -o certificates/punchio_dist.p12.base64

# Encode provisioning profile
base64 -i certificates/punchio_dist.mobileprovision -o certificates/punchio_dist.mobileprovision.base64
```

## Troubleshooting

### Common Issues:

1. **"Invalid CSR" error**
   - Ensure you're using the correct CSR file
   - Check that the CSR was generated with the same private key

2. **Certificate not found in keychain**
   - Make sure you installed it in the correct keychain
   - Try importing again

3. **Code signing fails**
   - Verify the certificate is valid and not expired
   - Check that the provisioning profile matches the certificate

### Verification Commands:

```bash
# Verify private key
openssl rsa -in certificates/punchio_dist.key -check

# Verify CSR
openssl req -in certificates/punchio_dist.csr -text -noout

# Verify certificate
openssl x509 -in certificates/punchio_dist.cer -text -noout
```

## Security Notes

- **Keep your private key secure** - never share `punchio_dist.key`
- **Backup your certificate** - you can't regenerate the same certificate
- **Use strong passwords** for .p12 exports
- **Store secrets securely** in your CI/CD system

## Next Steps

After obtaining your certificate:
1. Create an App Store provisioning profile
2. Update your build configuration
3. Test the build process
4. Submit to App Store Connect

## Files Generated

- `certificates/punchio_dist.key` - Private key (KEEP SECURE)
- `certificates/punchio_dist.csr` - Certificate Signing Request
- `certificates/punchio_dist.cer` - Apple Distribution Certificate
- `certificates/punchio_dist.p12` - Certificate + Private Key (for CI/CD)
