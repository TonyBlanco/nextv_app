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
    if (_favoriteIds.contains(stream.streamId)) return;

    final favorite = FavoriteChannel(
      streamId: stream.streamId,
      name: stream.name,
      icon: stream.streamIcon,
      categoryId: stream.categoryId,
      addedAt: DateTime.now(),
      type: 'channel',
    );

    _favorites.add(favorite);
    _favoriteIds.add(stream.streamId);
    await _saveFavorites();
  }

  /// Add a series to favorites
  Future<void> addFavoriteSeries(SeriesItem series) async {
    // For series, we use -1 as streamId if not available, OR hash code
    // Ideally seriesId should be unique identifier. 
    // We will use hash of seriesId for streamId Set, OR store separate set.
    // To minimize breakage, we can use a generated ID or negative ID.
    final id = series.seriesId.hashCode;
    if (_favoriteIds.contains(id)) return;

    final favorite = FavoriteChannel(
      streamId: id,
      name: series.name,
      icon: series.cover,
      categoryId: series.categoryId,
      addedAt: DateTime.now(),
      type: 'series',
      seriesId: series.seriesId,
      cover: series.cover,
    );

    _favorites.add(favorite);
    _favoriteIds.add(id);
    await _saveFavorites();
  }

  /// Remove a favorite (Channel or Series)
  Future<void> removeFavorite(int streamId) async {
    _favorites.removeWhere((f) => f.streamId == streamId);
    _favoriteIds.remove(streamId);
    await _saveFavorites();
  }

  Future<void> removeFavoriteSeries(String seriesId) async {
    final id = seriesId.hashCode;
    await removeFavorite(id);
  }


  /// Toggle favorite status for Channel
  Future<void> toggleFavorite(LiveStream stream) async {
    if (isFavorite(stream.streamId)) {
      await removeFavorite(stream.streamId);
    } else {
      await addFavorite(stream);
    }
  }

  /// Toggle favorite status for Series
  Future<void> toggleFavoriteSeries(SeriesItem series) async {
    final id = series.seriesId.hashCode;
    if (isFavorite(id)) {
      await removeFavorite(id);
    } else {
      await addFavoriteSeries(series);
    }
  }

  /// Check if a channel/series is a favorite (fast lookup by streamId/hashCode)
  bool isFavorite(int streamId) {
    return _favoriteIds.contains(streamId);
  }

  bool isFavoriteSeries(String seriesId) {
    return _favoriteIds.contains(seriesId.hashCode);
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
