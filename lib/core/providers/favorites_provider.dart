import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_channel.dart';
import '../services/favorites_service.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for FavoritesService
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return FavoritesService(prefs);
});

/// Provider for favorites list stream
final favoritesProvider = StreamProvider<List<FavoriteChannel>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return service.watchFavorites();
});

/// Provider to check if a specific stream is a favorite
final isFavoriteProvider = Provider.family<bool, int>((ref, streamId) {
  final service = ref.watch(favoritesServiceProvider);
  return service.isFavorite(streamId);
});

/// Provider for favorites count
final favoritesCountProvider = Provider<int>((ref) {
  final favorites = ref.watch(favoritesProvider).value ?? [];
  return favorites.length;
});
