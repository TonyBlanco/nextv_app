# NeXtv Development Environment

## SDK & Tools Configuration

### Android SDK
```
ANDROID_HOME=C:\Users\luisb\AppData\Local\Android\Sdk
ANDROID_SDK_ROOT=C:\Users\luisb\AppData\Local\Android\Sdk
```

**Tools:**
- Platform Tools: `C:\platform-tools\`
- ADB: `C:\platform-tools\adb.exe`
- Emulator: BlueStacks (127.0.0.1:5555)

### Flutter SDK
```
FLUTTER_ROOT=C:\src\flutter
FLUTTER_BIN=C:\src\flutter\bin\flutter.bat
```

### WebOS Development
- **Emulator:** Available
- **Developer Mode:** Enabled
- **CLI:** `npm install -g @webosose/ares-cli`
- **Deploy:** `ares-install` or ADB

---

## Project Paths

```
PROJECT_ROOT=D:\NEXTV APP
LEGACY_BACKUP=d:\IPTV Xuper\XUPERTB_ANDROID
```

---

## Build Commands

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### WebOS
```bash
flutter build web --release
cp -r build/web/* webos/
ares-install webos/
```

### Windows
```bash
flutter build windows --release
```

---

## Emulators

### BlueStacks (Android)
```bash
adb connect 127.0.0.1:5555
adb devices
```

### WebOS Emulator
```bash
ares-setup-device
ares-install --device <name> app.apk
```

---

## Dependencies

**Total:** 155 packages  
**Status:** ✅ Installed  
**Update:** `flutter pub get`

---

## Git

**Repository:** D:\NEXTV APP\.git  
**Remote:** (to be configured)  
**Branch:** main

---

## Notes

- All paths use absolute references
- SDKs configured in system PATH
- WebOS developer access enabled
- Legacy project preserved as backup
