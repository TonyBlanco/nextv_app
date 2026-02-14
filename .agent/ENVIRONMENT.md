# NeXtv Development Environment

## Platforms

| Platform | Machine | Status |
|----------|---------|--------|
| macOS (primary) | Mac mini ARM | iOS, macOS, Web builds |
| Windows | Separate PC | Windows builds |
| CI/CD | GitHub Actions | All platforms |

## SDK & Tools Configuration

### Flutter SDK (macOS)
```bash
FLUTTER_ROOT=/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk
PATH=$PATH:$FLUTTER_ROOT/bin
```

**Version:** Flutter 3.24.0+ (stable)

### CocoaPods (iOS/macOS development)
```bash
GEM_HOME=$HOME/.gem/ruby/2.6.0
PATH=$PATH:$GEM_HOME/bin
```

---

## Project Paths

| Platform | Path |
|----------|------|
| macOS | `/Users/luisblancofontela/Development/nextv_app` |
| Windows | `%USERPROFILE%\Development\nextv_app` |
| GitHub | `https://github.com/TonyBlanco/nextv_app.git` |

---

## Installed Tools

### Development
| Tool | Version | Install |
|------|---------|---------|
| Flutter | 3.24.0+ | Pre-installed |
| Dart | 3.x | Bundled with Flutter |
| Xcode | Latest | App Store |
| CocoaPods | Latest | `brew install cocoapods` |
| Lefthook | Latest | `brew install lefthook` |

### AI Agents
| Tool | Version | Install |
|------|---------|---------|
| GitHub Copilot | VS Code ext | VS Code Extensions |
| Claude Code | 2.1.42 | `npm install -g @anthropic-ai/claude-code` |
| gh CLI | 2.86.0 | `brew install gh` |
| Copilot CLI | 0.0.410 | `gh copilot` (built-in) |
| Gemini | — | `~/.gemini/` |

### UI/UX Design
| Tool | Version | Install |
|------|---------|---------|
| Figma | Latest | `brew install --cask figma` |
| Device Preview | Latest | Flutter package (in pubspec) |
| Widgetbook | 3.21.0 | Flutter dev dependency |
| ImageMagick | 7.x | `brew install imagemagick` |
| FFmpeg | 8.0.1 | `brew install ffmpeg` |
| Canva | App | Pre-installed |

### CI/CD & Quality
| Tool | Purpose | Config |
|------|---------|--------|
| GitHub Actions | CI/CD pipeline | `.github/workflows/` |
| Lefthook | Git hooks | `.lefthook.yml` |
| lcov | Coverage reports | `brew install lcov` |
| TruffleHog | Secret scanning | `brew install trufflehog` |

---

## Quick Setup (macOS)

```bash
source scripts/setup_mac.sh
```

## Quick Setup (Windows)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\setup_windows.ps1
```
