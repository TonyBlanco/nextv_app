import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_channel.dart';
import '../models/xtream_models.dart';

/// Service for managing favorite channels with persistent storage
class FavoritesService {
  static const String _storageKey = 'favorites_v1';
  
  final SharedPreferences _prefs;
  final _favoritesController = StreamController<List<FavoriteChannel>>.broadcast();
  final Set<int> _favoriteIds = {};
  List<FavoriteChannel> _favorites = [];

  FavoritesService(this._prefs) {
    _loadFavorites();
  }

  /// Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      final String? favoritesJson = _prefs.getString(_storageKey);
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites = decoded
            .map((item) => FavoriteChannel.fromJson(item as Map<String, dynamic>))
            .toList();
        _favoriteIds.clear();
        _favoriteIds.addAll(_favorites.map((f) => f.streamId));
        _favoritesController.add(_favorites);
      }
    } catch (e) {
      print('Error loading favorites: $e');
      _favorites = [];
      _favoriteIds.clear();
    }
  }

  /// Save favorites to storage
  Future<void> _saveFavorites() async {
    try {
      final List<Map<String, dynamic>> encoded =
          _favorites.map((f) => f.toJson()).toList();
      await _prefs.setString(_storageKey, json.encode(encoded));
      _favoritesController.add(_favorites);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  /// Add a channel to favorites
  Future<void> addFavorite(LiveStream stream) async {
    if (_favoriteIds.contains(stream.streamId)) {
      return; // Already a favorite
    }

    final favorite = FavoriteChannel(
      streamId: stream.streamId,
      name: stream.name,
      icon: stream.streamIcon,
      categoryId: stream.categoryId,
      addedAt: DateTime.now(),
    );

    _favorites.add(favorite);
    _favoriteIds.add(stream.streamId);
    await _saveFavorites();
  }

  /// Remove a channel from favorites
  Future<void> removeFavorite(int streamId) async {
    _favorites.removeWhere((f) => f.streamId == streamId);
    _favoriteIds.remove(streamId);
    await _saveFavorites();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(LiveStream stream) async {
    if (isFavorite(stream.streamId)) {
      await removeFavorite(stream.streamId);
    } else {
      await addFavorite(stream);
    }
  }

  /// Check if a channel is a favorite (fast lookup)
  bool isFavorite(int streamId) {
    return _favoriteIds.contains(streamId);
  }

  /// Get all favorites
  List<FavoriteChannel> getFavorites() {
    return List.unmodifiable(_favorites);
  }

  /// Watch favorites stream
  Stream<List<FavoriteChannel>> watchFavorites() {
    return _favoritesController.stream;
  }

  /// Get favorites count
  int get count => _favorites.length;

  /// Clear all favorites
  Future<void> clearAll() async {
    _favorites.clear();
    _favoriteIds.clear();
    await _saveFavorites();
  }

  /// Dispose resources
  void dispose() {
    _favoritesController.close();
  }
}
