# SIT App — iOS Development Setup Guide

This guide explains how to build and run the SIT App on the iOS Simulator on macOS. Follow every step in order — this project was originally developed on Windows, so several configuration files must be recreated manually.

---

## Prerequisites

Before starting, ensure you have all of the following installed:

| Tool | Version | Install |
|------|---------|---------|
| macOS | Ventura 13+ or later | — |
| Xcode | 15+ | Mac App Store |
| Xcode Command Line Tools | Latest | `xcode-select --install` |
| CocoaPods | 1.13+ | `brew install cocoapods` |
| Flutter SDK | 3.x (stable) | [flutter.dev/docs/get-started/install/macos](https://flutter.dev/docs/get-started/install/macos) |
| Python | 3.10+ | `brew install python@3.10` |

You also need access to the **`sit-app-project`** Firebase project in the Google Firebase Console.

---

## Step 1 — Verify Your Flutter Installation

```bash
flutter doctor
```

Resolve any issues shown before continuing. You need all of these to be ✅:

- Flutter (channel stable, 3.x)
- Xcode — full installation (not just CLI tools)
- CocoaPods installed and accessible
- iOS Simulator available

---

## Step 2 — Install Flutter Dependencies

From the project root:

```bash
flutter pub get
```

---

## Step 3 — Restore Firebase Configuration Files

These files are excluded by `.gitignore` and **must be added manually**.

### 3a. `ios/Runner/GoogleService-Info.plist`

1. Open [Firebase Console](https://console.firebase.google.com/) → select `sit-app-project`
2. Go to **Project Settings** (gear icon) → **Your apps** → select the iOS app
3. Click **Download GoogleService-Info.plist**
4. Move the downloaded file to:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

> ⚠️ The bundle ID in Firebase must match the one in Xcode. The current registered bundle ID is `com.example.flutterApp`. If you change it, update it in both Firebase Console and Xcode Runner target settings.

### 3b. `android/app/google-services.json` *(Android only — skip if iOS-only)*

1. Firebase Console → **Your apps** → select the Android app
2. Download `google-services.json`
3. Place it at `android/app/google-services.json`

---

## Step 4 — Set the iOS Deployment Target

Firebase requires a minimum iOS deployment target of **iOS 13.0**.

Open `ios/Podfile` and set/uncomment line 2:

```ruby
platform :ios, '13.0'
```

---

## Step 5 — Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

> Always run `pod install` **after** `flutter pub get`, never before.

**If `pod install` fails:**

```bash
# Update the CocoaPods spec repo first
cd ios
pod repo update
pod install
cd ..
```

**If you get a RubyGems error on Apple Silicon (M1/M2/M3):**

```bash
# Option A — use Homebrew
brew install cocoapods

# Option B — install via Rosetta
sudo arch -x86_64 gem install cocoapods
```

---

## Step 6 — Open in Xcode and Configure Signing

```bash
open ios/Runner.xcworkspace
```

> ⚠️ Always open the **`.xcworkspace`** file, **not** `.xcodeproj`. Opening `.xcodeproj` will cause missing Pods build errors.

In Xcode:

1. Select the **Runner** target in the left panel
2. Go to the **Signing & Capabilities** tab
3. Select your **Team** (use "Personal Team" / your Apple ID for Simulator-only work)
4. Verify **Bundle Identifier** is `com.example.flutterApp`
5. Verify **Deployment Target** is `13.0`

---

## Step 7 — Set Up the Flask Backend for Local Development

> Skip this section if you want to use the **production backend** on Render (`sit-app-backend.onrender.com`). The Flutter services are already pointed at that URL by default.

### 7a. Download the Firebase Admin SDK Service Account Key

1. Firebase Console → **Project Settings** → **Service Accounts** tab
2. Click **Generate New Private Key** → confirm → download the JSON file
3. Rename it to `serviceAccountKey.json`
4. Place it at:
   ```
   flask_api/serviceAccountKey.json
   ```
   *(This filename is already listed in `.gitignore` — it will not be committed.)*

### 7b. Create `flask_api/.env`

Create the file `flask_api/.env` with the following contents:

```env
FLASK_DEBUG=1
GEMINI_API_KEY=your_gemini_api_key_here
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
```

- **`GEMINI_API_KEY`**: Get one free at [Google AI Studio](https://aistudio.google.com/app/apikey)
- **`FIREBASE_SERVICE_ACCOUNT_PATH`**: Path to the JSON file from Step 7a (relative to `flask_api/`)

### 7c. Create a Fresh Python Virtual Environment

> ⚠️ The `flask_api/venv/` folder in the repo is a **Windows virtual environment** — it will not work on macOS. You must create a new one.

```bash
cd flask_api

# Create fresh venv
python3 -m venv venv

# Activate it (macOS/Linux syntax)
source venv/bin/activate

# Install all dependencies
pip install -r requirements.txt
```

### 7d. Run the Flask Backend

```bash
# Make sure venv is active
source venv/bin/activate

python run.py
```

The backend will start at `http://localhost:5000`.

To test local backend from the Flutter app, update the `baseUrl` constant in each service file under `lib/src/data/services/` from:
```dart
static const String baseUrl = 'https://sit-app-backend.onrender.com';
```
to:
```dart
static const String baseUrl = 'http://localhost:5000';
```

> Remember to revert this before committing.

---

## Step 8 — Run the App on iOS Simulator

```bash
# List available simulators and connected devices
flutter devices

# Run on a specific simulator
flutter run -d "iPhone 16"

# Or let Flutter pick the first available iOS simulator
flutter run
```

To run in release mode (faster, no debug overlay):

```bash
flutter run --release
```

---

## Step 9 — Verification Checklist

After the app launches on the Simulator, test the following flows to confirm the setup is correct:

- [ ] App launches without crashing (no Firebase init errors in console)
- [ ] Login screen appears correctly
- [ ] Sign up with a new email/password successfully creates a profile
- [ ] Home screen loads with dashboard data (or empty state if no data)
- [ ] Create a new transaction — it appears in the Transactions list
- [ ] Accounts screen shows correct balance after the transaction
- [ ] Budget screen loads without error
- [ ] Savings screen loads without error

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `pod install` fails — "Unable to find a specification for..." | Stale spec repo | `cd ios && pod repo update && pod install` |
| Flutter build error: "Minimum deployment target is X, but GoogleService-Info.plist requires 13.0" | Podfile not updated | Set `platform :ios, '13.0'` in `ios/Podfile`, then re-run `pod install` |
| Firebase crash on launch: "GoogleService-Info.plist not found" | File missing or in wrong directory | Ensure file is at `ios/Runner/GoogleService-Info.plist` (not `ios/`) |
| Flask crashes at startup with `FileNotFoundError` | `serviceAccountKey.json` missing or wrong path | Check `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env`; confirm file exists |
| Flask crashes with `ValueError: GEMINI_API_KEY ortam değişkeni bulunamadı` | Missing env var | Add `GEMINI_API_KEY=...` to `flask_api/.env` |
| `source venv/bin/activate` fails ("No such file or directory") | Windows venv folder present, no macOS venv | Delete `flask_api/venv/` and recreate: `python3 -m venv venv` |
| `venv\Scripts\activate` not found | You used the Windows activation path | Use `source venv/bin/activate` on macOS |
| Xcode error: "No signing certificate found" / "No team selected" | Missing Apple Developer account | Xcode → Runner → Signing & Capabilities → select your Team |
| Always open `.xcworkspace`, not `.xcodeproj` | | `open ios/Runner.xcworkspace` |
| Flutter app gets network errors calling localhost | Simulator cannot reach `localhost:5000` | Use your Mac's local IP (e.g., `http://192.168.x.x:5000`) instead of `localhost` when testing on a physical device |

---

## Quick-Reference Checklist (New Machine Setup)

```
[ ] flutter doctor — all green
[ ] flutter pub get
[ ] Place ios/Runner/GoogleService-Info.plist (from Firebase Console)
[ ] Set platform :ios, '13.0' in ios/Podfile
[ ] cd ios && pod install && cd ..
[ ] Place flask_api/serviceAccountKey.json (from Firebase Console)
[ ] Create flask_api/.env with GEMINI_API_KEY and FIREBASE_SERVICE_ACCOUNT_PATH
[ ] cd flask_api && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
[ ] flutter run
```
