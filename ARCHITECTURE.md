# NeXtv Architecture

## Overview

NeXtv follows a **clean architecture** pattern with clear separation of concerns.

## Directory Structure

### `/lib/core`
Business logic and infrastructure.

- **constants/** - App-wide constants (colors, strings, etc.)
- **models/** - Data models and entities
- **services/** - Business logic services
- **providers/** - Riverpod state providers
- **adapters/** - Platform-specific adapters

### `/lib/presentation`
User interface layer.

- **screens/** - Full-page screens
- **widgets/** - Reusable UI components

### `/lib/features`
Feature-specific modules (future expansion).

---

## Coding Conventions

### File Naming
```
✓ feature_name_screen.dart
✓ feature_name_widget.dart
✓ feature_name_service.dart
✗ featureScreen.dart
✗ feature-screen.dart
```

### Import Paths
```dart
✓ import '../../core/constants/nextv_colors.dart';
✓ import '../widgets/custom_button.dart';
✗ import 'package:xupertb_app/core/constants/nextv_colors.dart';
```

### Class Naming
```dart
✓ class PremiumTopBar extends StatelessWidget
✓ class FavoritesService
✗ class premiumTopBar
✗ class Favorites_Service
```

---

## State Management

**Riverpod** is used for all state management.

### Provider Types

- **Provider** - Immutable data
- **StateProvider** - Simple mutable state
- **StreamProvider** - Async streams
- **FutureProvider** - Async futures

### Example
```dart
final favoritesProvider = StreamProvider<List<FavoriteChannel>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return service.watchFavorites();
});
```

---

## Services

All business logic resides in services.

### Service Pattern
```dart
class FavoritesService {
  final SharedPreferences _prefs;
  
  FavoritesService(this._prefs);
  
  Future<void> addFavorite(LiveStream stream) async {
    // Implementation
  }
}
```

---

## No Duplicates Policy

**CRITICAL:** This project has ZERO tolerance for duplicate files.

### Rules
1. ❌ No duplicate screens (e.g., `home_screen` vs `landing_screen`)
2. ❌ No duplicate services (e.g., `iptv_service` vs `xtream_service`)
3. ❌ No platform variants (e.g., `player_mobile` vs `player_web`)
4. ✅ Use conditional imports for platform-specific code

### Platform-Specific Code
```dart
import 'adapter_mobile.dart' if (dart.library.html) 'adapter_web.dart';
```

---

## File Size Limits

- **Screens:** Max 500 lines
- **Widgets:** Max 300 lines
- **Services:** Max 400 lines

If a file exceeds these limits, refactor into smaller components.

---

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widgets/
```

---

## Build & Deploy

### Android
```bash
flutter build apk --release
```

### WebOS
```bash
flutter build web --release
# Then copy to webos/ folder
```

---

## Migration Notes

This is a **clean migration** from the legacy XuperTB project.

**What was removed:**
- Duplicate files (8 files)
- Legacy code
- Unused features
- Inconsistent paths

**What was kept:**
- All working features
- Premium UI components
- Favorites system
- Core services

---

## Contributing

1. Follow coding conventions
2. No duplicate files
3. Keep files under size limits
4. Update this document when adding new patterns
