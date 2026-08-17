# Personal Guide — iOS App

> **Personal Guide turns the confusing administrative work of everyday life into clear, actionable cases and guides you from "I need to deal with this" to "it's done."**

A native SwiftUI iOS app (iOS 17+) built with SwiftData, zero external dependencies.

---

## 🚀 Build & Deploy — No Mac Required

This project uses **GitHub Actions** to build, test, and deploy to TestFlight. You write code on Windows, push to GitHub, and the app lands on your iPhone automatically.

### Your Workflow

```
1. Edit Swift code on Windows (Antigravity/VS Code)
         ↓
2. git push to GitHub
         ↓
3. GitHub Actions (macOS runner) builds the app
         ↓
4. Automatically uploads to TestFlight
         ↓
5. Open TestFlight on your iPhone → Install
```

**Cost: ~$0–4/month** (vs $50/month for a cloud Mac)

---

## One-Time Setup (30 minutes)

### Step 1: Apple Developer Account

1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. **Enroll in the Apple Developer Program — $99/year**
4. Wait for enrollment to be approved (~48 hours)

### Step 2: Create GitHub Repository

```bash
cd "c:\Users\nandh\personal admin\PersonalGuide"
git init
git add .
git commit -m "Initial commit: Personal Guide iOS app"
git remote add origin https://github.com/YOUR_USERNAME/PersonalGuide.git
git push -u origin main
```

### Step 3: Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps → + → New App**
3. Fill in:
   - Name: **Personal Guide**
   - Bundle ID: Create new → `com.personalguide.app`
   - SKU: `personalguide`
4. Click **Create**

### Step 4: Generate Code Signing Credentials

You'll need to do this once from any Mac (borrow one, use a friend's, or use a 1-hour MacinCloud session for ~$1):

#### 4a. Distribution Certificate
1. Open **Keychain Access** on the Mac
2. **Keychain Access → Certificate Assistant → Request a Certificate from a CA**
3. Enter your email, select "Saved to disk", click Continue
4. Go to [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates/add)
5. Select **Apple Distribution**, upload the CSR file
6. Download the certificate, double-click to install
7. In Keychain Access, right-click the certificate → **Export** as .p12
8. Set a password — remember it!

#### 4b. Provisioning Profile
1. Go to [developer.apple.com/account/resources/profiles](https://developer.apple.com/account/resources/profiles/add)
2. Select **App Store Connect**
3. Select your App ID (`com.personalguide.app`)
4. Select your Distribution certificate
5. Download the .mobileprovision file

#### 4c. App Store Connect API Key
1. Go to [appstoreconnect.apple.com/access/integrations/api](https://appstoreconnect.apple.com/access/integrations/api)
2. Click **+** to generate a new key
3. Name: "GitHub Actions", Access: **App Manager**
4. Download the .p8 file (you can only download it once!)
5. Note the **Key ID** and **Issuer ID**

### Step 5: Add Secrets to GitHub

Go to your GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Value |
|---|---|
| `DEVELOPMENT_TEAM` | Your 10-character Team ID (from developer.apple.com → Membership) |
| `BUILD_CERTIFICATE_BASE64` | Your .p12 cert encoded: `base64 -i certificate.p12` |
| `P12_PASSWORD` | The password you set for the .p12 |
| `KEYCHAIN_PASSWORD` | Any random password (e.g., `gh-actions-keychain-2026`) |
| `PROVISIONING_PROFILE_BASE64` | Your .mobileprovision encoded: `base64 -i profile.mobileprovision` |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from Step 4c |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from Step 4c |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Your .p8 key encoded: `base64 -i AuthKey_XXXX.p8` |

### Step 6: Push & Deploy

```bash
git push origin main
```

GitHub Actions will:
1. ✅ Build on a macOS runner
2. ✅ Run unit tests
3. ✅ Archive the app
4. ✅ Upload to TestFlight

### Step 7: Install on Your iPhone 14 Pro

1. Install **TestFlight** from the App Store on your iPhone
2. Go to App Store Connect → TestFlight → Add yourself as internal tester
3. Open the TestFlight invite email on your iPhone
4. Tap **Install** 🎉

---

## Project Structure

```
PersonalGuide/
├── .github/workflows/
│   ├── build-and-deploy.yml    ← Push to main → TestFlight
│   └── ci.yml                  ← PR checks (build + test)
├── PersonalGuide/
│   ├── App/                    ← Entry point, ModelContainer
│   ├── Models/                 ← SwiftData models + enums
│   ├── Services/               ← Business logic
│   ├── Views/                  ← SwiftUI screens
│   └── Extensions/             ← Helpers
├── PersonalGuideTests/         ← Unit tests
├── project.yml                 ← XcodeGen (generates .xcodeproj)
├── .gitignore
└── README.md
```

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Data | SwiftData |
| AI (Phase 2) | Apple Vision + Gemini/OpenAI |
| Notifications | UserNotifications |
| Sync (Phase 4) | CloudKit |
| Security (Phase 4) | LocalAuthentication (Face ID) |
| CI/CD | GitHub Actions (macOS runner) |
| Distribution | TestFlight → App Store |

**Zero external dependencies.** 100% Apple frameworks.

---

## GitHub Actions Minutes

| Plan | macOS Minutes/Month | Builds (~8 min each) |
|---|---|---|
| Free (public repo) | Unlimited | Unlimited |
| Free (private repo) | 200 min (2000 ÷ 10x multiplier) | ~25 builds |
| Team ($4/user/month) | 300 min | ~37 builds |
| Pro ($4/month) | 300 min | ~37 builds |

> **Tip**: Keep the repo public during development to get unlimited free builds. Switch to private before App Store launch.
