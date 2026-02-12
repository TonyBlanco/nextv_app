---
description: Flutter IPTV Development Best Practices
---

# NeXtv Flutter IPTV Development Skill

## Overview

This skill provides best practices, patterns, and guidelines for developing the NeXtv IPTV application using Flutter.

---

## Core Principles

### 1. No Duplicates Policy
**CRITICAL:** Zero tolerance for duplicate files.

```dart
// ❌ WRONG: Creating platform variants
embedded_player_mobile.dart
embedded_player_web.dart
embedded_player.dart

// ✅ CORRECT: Single adaptive widget
adaptive_player.dart (with conditional imports)
```

### 2. Forward Progress Only
- Improve existing code
- Add features incrementally
- Never delete working functionality
- Refactor for clarity, not rewrite

### 3. Clean Architecture
```
lib/
├── core/           # Business logic
├── presentation/   # UI layer
└── features/       # Feature modules
```

---

## Patterns & Best Practices

### State Management (Riverpod)

```dart
// Service Provider
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesService(prefs);
});

// Stream Provider
final favoritesProvider = StreamProvider<List<FavoriteChannel>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return service.watchFavorites();
});

// Family Provider for lookups
final isFavoriteProvider = Provider.family<bool, int>((ref, streamId) {
  final favorites = ref.watch(favoritesProvider).value ?? [];
  return favorites.any((f) => f.streamId == streamId);
});
```

### Platform-Specific Code

```dart
// Use conditional imports
import 'player_mobile.dart' 
  if (dart.library.html) 'player_web.dart';

class PlatformPlayer {
  static Widget create() {
    if (kIsWeb) {
      return WebPlayer();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return MobilePlayer();
    } else {
      return DesktopPlayer();
    }
  }
}
```

### Service Pattern

```dart
class FavoritesService {
  final SharedPreferences _prefs;
  final _controller = StreamController<List<FavoriteChannel>>.broadcast();
  final Set<int> _favoriteIds = {};

  FavoritesService(this._prefs) {
    _loadFavorites();
  }

  // O(1) lookup
  bool isFavorite(int streamId) => _favoriteIds.contains(streamId);

  // Stream for reactive UI
  Stream<List<FavoriteChannel>> watchFavorites() => _controller.stream;

  Future<void> addFavorite(LiveStream stream) async {
    final favorite = FavoriteChannel.fromStream(stream);
    _favoriteIds.add(stream.streamId);
    await _saveFavorites();
    _controller.add(await getFavorites());
  }

  void dispose() {
    _controller.close();
  }
}
```

### Widget Patterns

```dart
// Stateless with Riverpod
class FavoriteButton extends ConsumerWidget {
  final int streamId;
  
  const FavoriteButton({required this.streamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(streamId));
    
    return IconButton(
      icon: Icon(isFavorite ? Icons.star : Icons.star_border),
      onPressed: () => _toggleFavorite(ref),
    );
  }
}
```

---

## File Organization

### Naming Conventions
```
✓ feature_name_screen.dart
✓ feature_name_widget.dart
✓ feature_name_service.dart
✗ featureScreen.dart
✗ feature-screen.dart
```

### Import Order
```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 4. Relative imports
import '../../core/constants/nextv_colors.dart';
import '../widgets/custom_button.dart';
```

### File Size Limits
- Screens: Max 500 lines
- Widgets: Max 300 lines
- Services: Max 400 lines

If exceeded, refactor into smaller components.

---

## Performance Optimization

### Large Lists (30K+ channels)

```dart
// Use ListView.builder, not ListView
ListView.builder(
  itemCount: channels.length,
  itemBuilder: (context, index) {
    return ChannelTile(channel: channels[index]);
  },
);

// Use const constructors
const NextvLogo(size: 30);

// Cache expensive computations
final filteredChannels = useMemoized(
  () => channels.where((c) => c.category == selectedCategory).toList(),
  [channels, selectedCategory],
);
```

### Image Optimization

```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: channel.icon,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 100, // Limit memory usage
);
```

### Memory Management

```dart
// Dispose controllers
@override
void dispose() {
  _controller.dispose();
  _player.dispose();
  super.dispose();
}

// Limit cache size
static const int MAX_EPG_CACHE = 1000;
static const int MAX_PLAYLIST_SIZE = 50000;
```

---

## UI/UX Guidelines

### NextvColors Palette

```dart
// Use predefined colors
NextvColors.primary      // #8b5cf6 (purple)
NextvColors.secondary    // #3b82f6 (blue)
NextvColors.surface      // #0a0e27 (dark)
NextvColors.accent       // #f59e0b (amber)
```

### Animations

```dart
// Smooth transitions
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  // ...
);

// Scale animation
TweenAnimationBuilder<double>(
  tween: Tween(begin: 1.0, end: isPressed ? 1.3 : 1.0),
  duration: Duration(milliseconds: 150),
  builder: (context, scale, child) {
    return Transform.scale(scale: scale, child: child);
  },
);
```

### Responsive Design

```dart
// TV Mode detection
final settings = ref.watch(settingsProvider);
if (settings.tvMode) {
  return TvModeLayout();
} else {
  return MobileLayout();
}

// Adaptive spacing
final spacing = settings.tvMode ? 24.0 : 16.0;
```

---

## Testing Patterns

### Unit Tests

```dart
void main() {
  group('FavoritesService', () {
    late FavoritesService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = FavoritesService(prefs);
    });

    test('should add favorite', () async {
      final stream = LiveStream(streamId: 1, name: 'Test');
      await service.addFavorite(stream);
      expect(service.isFavorite(1), true);
    });
  });
}
```

### Widget Tests

```dart
testWidgets('FavoriteButton toggles state', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: FavoriteButton(streamId: 1),
      ),
    ),
  );

  expect(find.byIcon(Icons.star_border), findsOneWidget);
  
  await tester.tap(find.byType(IconButton));
  await tester.pump();
  
  expect(find.byIcon(Icons.star), findsOneWidget);
});
```

---

## Common Pitfalls

### ❌ Avoid

```dart
// Creating duplicates
home_screen.dart + landing_screen.dart (same purpose)

// God objects
nova_main_screen.dart (2,563 lines)

// Inconsistent paths
import '../../core/theme/colors.dart';  // Wrong
import '../../core/constants/nextv_colors.dart';  // Correct

// Hardcoded values
Color(0xFF8b5cf6)  // Wrong
NextvColors.primary  // Correct
```

### ✅ Best Practices

```dart
// Single responsibility
Each file has one clear purpose

// Consistent naming
All files follow snake_case

// Proper imports
Use relative paths within lib/

// Constants
Define once, use everywhere
```

---

## Deployment

### Android Build

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### WebOS Build

```bash
flutter build web --release
cp -r build/web/* webos/
cd webos
ares-package .
ares-install com.xupertb.iptv_2.0.0_all.ipk
```

---

## Checklist Before Committing

- [ ] No duplicate files created
- [ ] Follows naming conventions
- [ ] Uses NextvColors palette
- [ ] Imports properly ordered
- [ ] File size under limits
- [ ] No hardcoded values
- [ ] Disposed resources
- [ ] Tests pass
- [ ] Documentation updated

---

## Resources

- **Architecture:** See ARCHITECTURE.md
- **Workflow:** See .agent/WORKFLOW.md
- **Environment:** See .agent/ENVIRONMENT.md
- **Flutter Docs:** https://flutter.dev
- **Riverpod Docs:** https://riverpod.dev
