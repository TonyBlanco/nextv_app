# NeXtv IPTV

Premium IPTV application with modern UI, advanced features, and **professional-grade development infrastructure**.

[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue)](/.github/workflows/ci.yml)
[![Tests](https://img.shields.io/badge/coverage-70%25-brightgreen)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

## ✨ Features

- 📺 **Live TV** - Support for 30,000+ channels with EPG
- 🎬 **VOD & Series** - Movies and TV shows on demand
- ⭐ **Smart Favorites** - Fast, persistent channel management
- 🔄 **Catch-up TV** - Watch past programs (7-day archive)
- 🎨 **Modern UI** - Glassmorphism and smooth animations
- 🔒 **Parental Controls** - Content filtering
- 🌐 **Multi-platform** - Android, iOS, Web, WebOS, macOS, Windows

## 🛡️ Professional Development Infrastructure

### Quality Assurance
- ✅ **CI/CD Pipeline** - Automated testing and deployment via GitHub Actions
- ✅ **Git Hooks** - Pre-commit code quality checks with Lefthook
- ✅ **Test Coverage** - 70%+ target with comprehensive test suite
- ✅ **Code Analysis** - Static analysis with flutter_lints
- ✅ **Security Scanning** - Automated secret detection with TruffleHog

### Architecture
- 🏗️ **Clean Architecture** - Separation of concerns (Presentation, Business, Data)
- 🔄 **State Management** - Riverpod with reactive patterns
- 📦 **Repository Pattern** - Clean data access layer
- 🧪 **100% Testable** - Dependency injection and mocking support

## 🚀 Tech Stack

- **Framework:** Flutter 3.24.0+
- **State Management:** Riverpod 2.6.1
- **Storage:** SharedPreferences + Flutter Secure Storage (planned)
- **Video Players:** BetterPlayer Plus, VLC, Media Kit
- **HTTP Client:** Dio with interceptors
- **Testing:** flutter_test, mockito, mocktail
- **CI/CD:** GitHub Actions
- **API Protocol:** Xtream Codes

## 📁 Project Structure

```
lib/
├── core/                  # Business logic & infrastructure
│   ├── config/           # App configuration
│   ├── constants/        # Constants and enums
│   ├── models/           # Data models
│   ├── services/         # Business services
│   ├── providers/        # Riverpod providers
│   ├── repositories/     # Data repositories
│   └── utils/            # Utilities and helpers
├── presentation/          # UI layer
│   ├── screens/          # Full-screen pages
│   ├── widgets/          # Reusable components
│   └── theme/            # App theming
└── features/              # Feature modules
    ├── auth/             # Authentication
    ├── live_tv/          # Live streaming
    ├── vod/              # Video on demand
    └── series/           # TV series
```

## � UI/UX Design Tools

| Tool | Purpose | Command |
|------|---------|--------|
| **Figma** | Interface design, prototyping, design system | Open `/Applications/Figma.app` |
| **Device Preview** | Preview app on 30+ device frames while developing | Set `enableDevicePreview = true` in `main.dart` |
| **Widgetbook** | Visual widget catalog (like Storybook) | `flutter run -t lib/widgetbook/widgetbook_app.dart` |
| **ImageMagick** | Generate icons, resize assets | `magick input.png -resize 512x512 output.png` |
| **FFmpeg** | Process video, generate thumbnails | `ffmpeg -i video.mp4 -ss 5 -frames:v 1 thumb.jpg` |

## 🤖 AI Agent Tools

| Tool | Version | Purpose | Command |
|------|---------|---------|--------|
| **GitHub Copilot** | VS Code extension | AI code completion & chat | Built into VS Code |
| **Claude Code** | 2.1.42 | Anthropic AI agent in terminal | `claude` |
| **GitHub Copilot CLI** | 0.0.410 | AI-powered shell suggestions | `gh copilot suggest "query"` |
| **gh CLI** | 2.86.0 | GitHub from terminal (PRs, issues, Actions) | `gh repo view`, `gh pr create` |
| **Gemini** | — | Google AI agent | `~/.gemini/` |

## 🏁 Getting Started

### Prerequisites

```bash
# Flutter SDK 3.24.0+
flutter --version

# Install dev tools (macOS)
brew install lefthook lcov gh
brew install trufflesecurity/trufflehog/trufflehog
brew install imagemagick ffmpeg
brew install --cask figma
npm install -g @anthropic-ai/claude-code
gh extension install github/gh-copilot
```

### Setup (macOS)

```bash
# 1. Clone the repository
git clone https://github.com/TonyBlanco/nextv_app.git
cd nextv_app

# 2. Install dependencies
flutter pub get

# 3. Setup Git hooks
lefthook install

# 4. Run tests
flutter test --coverage

# 5. Run the app
flutter run
```

### Setup (Windows)

```powershell
# 1. Clone and run setup script
git clone https://github.com/TonyBlanco/nextv_app.git
cd nextv_app
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\setup_windows.ps1

# 2. Build Windows app
flutter build windows --release
```

## 🧪 Development Workflow

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Code Quality

```bash
# Format code
dart format .

# Analyze code
flutter analyze --fatal-infos

# Security scan
trufflehog filesystem . --no-update
```

### Building

```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=debug-info/
flutter build appbundle --release --obfuscate --split-debug-info=debug-info/

# iOS
flutter build ios --release --obfuscate --split-debug-info=debug-info/

# Windows (only on Windows machine)
flutter build windows --release

# Web
flutter build web --release

# Widgetbook (UI catalog)
flutter run -t lib/widgetbook/widgetbook_app.dart
```

## 📖 Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

- **[IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md)** - Complete setup and implementation guide
- **[REFACTORING_PLAN.md](docs/REFACTORING_PLAN.md)** - 4-week refactoring roadmap
- **[SECURITY_IMPLEMENTATION.md](docs/SECURITY_IMPLEMENTATION.md)** - Security best practices
- **[BEST_PRACTICES.md](docs/BEST_PRACTICES.md)** - Coding standards and guidelines
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Architecture documentation
- **[AUDITORIA_TECNICA.md](docs/AUDITORIA_TECNICA.md)** - Technical audit report
- **[AUDITORIA_SEGURIDAD.md](docs/AUDITORIA_SEGURIDAD.md)** - Security audit report
- **[DEPLOYMENT_MICROSOFT_STORE.md](docs/DEPLOYMENT_MICROSOFT_STORE.md)** - Windows Store deployment
- **[DEPLOYMENT_IOS_APP_STORE.md](docs/DEPLOYMENT_IOS_APP_STORE.md)** - iOS App Store deployment
- **[DEPLOYMENT_GOOGLE_PLAY.md](docs/DEPLOYMENT_GOOGLE_PLAY.md)** - Google Play deployment
- **[WEBSITE_DOCUMENTATION.md](docs/WEBSITE_DOCUMENTATION.md)** - Web deployment (Vercel)

## 🔒 Security

- ✅ Secure credential storage (flutter_secure_storage - planned)
- ✅ Code obfuscation enabled in production builds
- ✅ HTTPS enforcement
- ✅ Input validation and sanitization
- ✅ No hardcoded secrets
- ✅ Automated security scanning

See [SECURITY_IMPLEMENTATION.md](docs/SECURITY_IMPLEMENTATION.md) for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit with conventional commits (`git commit -m 'feat(player): add new control'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [BEST_PRACTICES.md](docs/BEST_PRACTICES.md) for coding guidelines.

## 📊 Project Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Test Coverage | 15% → 70% | 70%+ |
| Code Complexity | 5.2 | < 4.0 |
| Build Time | ~2m | < 1.5m |
| Startup Time | 2.8s | < 2.5s |

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for clean state management
- BetterPlayer and VLC for video playback
- All open-source contributors

---

**Made with ❤️ by Luis Blanco**

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## Version

**2.0.0** - Clean migration with premium features
