# 🔐 GitHub Secrets Setup Guide

This guide shows you how to add the required secrets to your GitHub repository for iOS App Store distribution.

## 📋 Required GitHub Secrets

You need to add these secrets to your GitHub repository:

### 1. Certificate and Provisioning Profile
- `IOS_CERT_P12_BASE64` - Base64 encoded .p12 certificate file
- `IOS_PROFILE_BASE64` - Base64 encoded .mobileprovision file
- `IOS_CERT_PASSWORD` - Password for the .p12 file

### 2. Apple Developer Account Info
- `IOS_TEAM_ID` - Your 10-character Apple Developer Team ID
- `IOS_BUNDLE_ID` - Your app's bundle identifier
- `APPLE_ID` - Your Apple ID email
- `APPLE_PASSWORD` - App-specific password

### 3. Optional
- `APP_DISPLAY_NAME` - Your app's display name

## 🚀 How to Add Secrets to GitHub

### Step 1: Go to Repository Settings
1. Navigate to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add Each Secret
Click **New repository secret** for each item below:

#### IOS_CERT_P12_BASE64
- **Name:** `IOS_CERT_P12_BASE64`
- **Value:** Paste the base64 encoded .p12 file (already in your clipboard)

#### IOS_PROFILE_BASE64
- **Name:** `IOS_PROFILE_BASE64`
- **Value:** Paste the base64 encoded .mobileprovision file (already in your clipboard)

#### IOS_CERT_PASSWORD
- **Name:** `IOS_CERT_PASSWORD`
- **Value:** The password you set when creating the .p12 file

#### IOS_TEAM_ID
- **Name:** `IOS_TEAM_ID`
- **Value:** `MNRC5F55U3` (your team ID)

#### IOS_BUNDLE_ID
- **Name:** `IOS_BUNDLE_ID`
- **Value:** `com.punchio.punchio`

#### APPLE_ID
- **Name:** `APPLE_ID`
- **Value:** `xxwodie@gmail.com`

#### APPLE_PASSWORD
- **Name:** `APPLE_PASSWORD`
- **Value:** Your app-specific password (generate in Apple ID settings)

#### APP_DISPLAY_NAME (Optional)
- **Name:** `APP_DISPLAY_NAME`
- **Value:** `Punchio`

## 🔑 App-Specific Password Setup

If you don't have an app-specific password yet:

1. Go to [Apple ID Settings](https://appleid.apple.com/)
2. Sign in with your Apple ID
3. Go to **Security** section
4. Click **Generate Password** under **App-Specific Passwords**
5. Label it "GitHub Actions" or similar
6. Copy the generated password
7. Add it as `APPLE_PASSWORD` secret

## ✅ Verification

After adding all secrets, your repository should have these secrets:
- ✅ IOS_CERT_P12_BASE64
- ✅ IOS_PROFILE_BASE64
- ✅ IOS_CERT_PASSWORD
- ✅ IOS_TEAM_ID
- ✅ IOS_BUNDLE_ID
- ✅ APPLE_ID
- ✅ APPLE_PASSWORD
- ✅ APP_DISPLAY_NAME (optional)

## 🚀 Next Steps

Once all secrets are added:
1. Push any change to trigger GitHub Actions
2. The build will use your certificate and provisioning profile
3. Download the generated .ipa file from Actions → Artifacts
4. Upload to App Store Connect for TestFlight or App Store distribution

## 🔒 Security Notes

- Never commit certificate files or passwords to your repository
- GitHub Secrets are encrypted and only accessible during workflow runs
- Keep your .p12 password secure and don't share it
- Regularly rotate your app-specific password

## 🆘 Troubleshooting

### Common Issues:
- **"Certificate not found"** - Check that IOS_CERT_P12_BASE64 is correctly encoded
- **"Invalid provisioning profile"** - Verify IOS_PROFILE_BASE64 matches your bundle ID
- **"Team ID mismatch"** - Ensure IOS_TEAM_ID matches your Apple Developer account
- **"Authentication failed"** - Check APPLE_ID and APPLE_PASSWORD are correct

### Re-encoding Files:
If you need to re-encode files:
```powershell
# Re-encode .p12 file
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificates/distribution.p12")) | Set-Clipboard

# Re-encode .mobileprovision file
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificates/Punchio_App_Store.mobileprovision")) | Set-Clipboard
```
