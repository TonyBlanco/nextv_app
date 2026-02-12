# NeXtv IPTV

Premium IPTV application with modern UI and advanced features.

## Features

- ✨ **Premium Top Bar** - NeXtv branding with animated logo
- ⭐ **Favorites System** - Fast, persistent channel favorites
- 📺 **Live TV** - Support for 30,000+ channels
- 🎬 **VOD & Series** - Movies and TV shows on demand
- 📡 **EPG** - Electronic Program Guide
- 🔒 **Parental Controls** - Content filtering
- 🎨 **Modern UI** - Glassmorphism and smooth animations

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Storage:** SharedPreferences
- **Video Players:** BetterPlayer, VLC
- **API:** Xtream Codes

## Project Structure

```
lib/
├── core/              # Business logic
│   ├── constants/     # App constants
│   ├── models/        # Data models
│   ├── services/      # Business services
│   ├── providers/     # State providers
│   └── adapters/      # Platform adapters
├── presentation/      # UI layer
│   ├── screens/       # App screens
│   └── widgets/       # Reusable widgets
└── features/          # Feature modules
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run

# Build release APK
flutter build apk --release
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## Version

**2.0.0** - Clean migration with premium features
