# NeXtv Development Environment (macOS)

## SDK & Tools Configuration

### Flutter SDK
```bash
FLUTTER_ROOT=/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk
PATH=$PATH:$FLUTTER_ROOT/bin
```

**Version:** Flutter 3.41.0 (stable)  
**Dart:** 3.11.0

### CocoaPods (iOS/macOS development)
```bash
GEM_HOME=$HOME/.gem/ruby/2.6.0
PATH=$PATH:$GEM_HOME/bin
```

**Note:** CocoaPods requires Xcode to be fully installed.

---

## Project Paths

```bash
PROJECT_ROOT=/Volumes/Untitled/NEXTV APP
```

---

## Quick Setup

Run this in your terminal to configure the environment:

```bash
source scripts/setup_mac.sh
```

---

## Build Commands

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (requires Xcode)
```bash
flutter build ios --release
```

### macOS (requires Xcode)
```bash
flutter build macos --release
```

### Web
```bash
flutter build web --release
# Output: build/web
```

---

## Development Tools

### Check Flutter Setup
```bash
flutter doctor -v
```

### Get Dependencies
```bash
flutter pub get
```

### Analyze Code
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

---

## Platform Requirements

### ✅ Already Configured
- Flutter SDK (3.41.0)
- Dart SDK (3.11.0)
- Command Line Tools for Xcode
- Android SDK (partial)

### ⚠️ Manual Setup Required
1. **Xcode** (for iOS/macOS builds)
   - Install from App Store
   - Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   - Run: `sudo xcodebuild -runFirstLaunch`

2. **Android Licenses**
   - Run: `flutter doctor --android-licenses`

3. **CocoaPods** (after Xcode installation)
   - Run: `brew install cocoapods`
   - Or: `sudo gem install cocoapods`

---

## Notes

- Flutter SDK is shared across all projects
- Always run `source scripts/setup_mac.sh` in new terminal sessions
- For persistent PATH, add Flutter to your `~/.zshrc`
