import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catchup_item.dart';
import '../constants/catchup_config.dart';

/// Service for managing catch-up favorites, watch later, and history
/// 
/// Provides persistent storage using SharedPreferences with platform-specific
/// limits to ensure efficient memory usage.
class CatchupStorageService {
  static const String _favoritesKey = 'catchup_favorites_v1';
  static const String _watchLaterKey = 'catchup_watch_later_v1';
  static const String _historyKey = 'catchup_history_v1';
  static const String _progressKey = 'catchup_progress_v1';

  final SharedPreferences _prefs;
  
  // Stream controllers for reactive updates
  final _favoritesController = StreamController<List<CatchupItem>>.broadcast();
  final _watchLaterController = StreamController<List<CatchupItem>>.broadcast();
  final _historyController = StreamController<List<CatchupItem>>.broadcast();
  
  // In-memory caches for fast lookups
  final Set<String> _favoriteIds = {};
  final Set<String> _watchLaterIds = {};
  List<CatchupItem> _favorites = [];
  List<CatchupItem> _watchLater = [];
  List<CatchupItem> _history = [];
  Map<String, CatchupItem> _progress = {};

  CatchupStorageService(this._prefs) {
    _loadAll();
  }

  // ─── INITIALIZATION ───

  /// Load all data from storage
  Future<void> _loadAll() async {
    await Future.wait([
      _loadFavorites(),
      _loadWatchLater(),
      _loadHistory(),
      _loadProgress(),
    ]);
  }

  Future<void> _loadFavorites() async {
    try {
      final String? json = _prefs.getString(_favoritesKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _favorites = decoded
            .map((item) => CatchupItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _favoriteIds.clear();
        _favoriteIds.addAll(_favorites.map((f) => f.programId));
        _favoritesController.add(_favorites);
      }
    } catch (e) {
      print('Error loading catch-up favorites: $e');
      _favorites = [];
      _favoriteIds.clear();
    }
  }

  Future<void> _loadWatchLater() async {
    try {
      final String? json = _prefs.getString(_watchLaterKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _watchLater = decoded
            .map((item) => CatchupItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _watchLaterIds.clear();
        _watchLaterIds.addAll(_watchLater.map((w) => w.programId));
        _watchLaterController.add(_watchLater);
      }
    } catch (e) {
      print('Error loading watch later: $e');
      _watchLater = [];
      _watchLaterIds.clear();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final String? json = _prefs.getString(_historyKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _history = decoded
            .map((item) => CatchupItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _historyController.add(_history);
      }
    } catch (e) {
      print('Error loading history: $e');
      _history = [];
    }
  }

  Future<void> _loadProgress() async {
    try {
      final String? json = _prefs.getString(_progressKey);
      if (json != null) {
        final Map<String, dynamic> decoded = jsonDecode(json);
        _progress = decoded.map(
          (key, value) => MapEntry(
            key,
            CatchupItem.fromJson(value as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      print('Error loading progress: $e');
      _progress = {};
    }
  }

  // ─── FAVORITES ───

  /// Add program to favorites
  Future<void> addToFavorites(String programId) async {
    if (_favoriteIds.contains(programId)) return;
    
    // Enforce limit
    if (_favorites.length >= CatchupConfig.maxFavorites) {
      throw Exception('Maximum favorites limit reached (${CatchupConfig.maxFavorites})');
    }

    final item = CatchupItem(
      programId: programId,
      addedAt: DateTime.now(),
    );

    _favorites.add(item);
    _favoriteIds.add(programId);
    await _saveFavorites();
  }

  /// Remove program from favorites
  Future<void> removeFromFavorites(String programId) async {
    _favorites.removeWhere((f) => f.programId == programId);
    _favoriteIds.remove(programId);
    await _saveFavorites();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String programId) async {
    if (isFavorite(programId)) {
      await removeFromFavorites(programId);
    } else {
      await addToFavorites(programId);
    }
  }

  /// Check if program is a favorite (O(1) lookup)
  bool isFavorite(String programId) {
    return _favoriteIds.contains(programId);
  }

  /// Get all favorites
  List<CatchupItem> getFavorites() {
    return List.unmodifiable(_favorites);
  }

  /// Watch favorites stream
  Stream<List<CatchupItem>> watchFavorites() {
    return _favoritesController.stream;
  }

  Future<void> _saveFavorites() async {
    try {
      final encoded = _favorites.map((f) => f.toJson()).toList();
      await _prefs.setString(_favoritesKey, jsonEncode(encoded));
      _favoritesController.add(_favorites);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // ─── WATCH LATER ───

  /// Add program to watch later queue
  Future<void> addToWatchLater(String programId) async {
    if (_watchLaterIds.contains(programId)) return;
    
    // Enforce limit
    if (_watchLater.length >= CatchupConfig.maxWatchLater) {
      throw Exception('Maximum watch later limit reached (${CatchupConfig.maxWatchLater})');
    }

    final item = CatchupItem(
      programId: programId,
      addedAt: DateTime.now(),
    );

    _watchLater.add(item);
    _watchLaterIds.add(programId);
    await _saveWatchLater();
  }

  /// Remove program from watch later
  Future<void> removeFromWatchLater(String programId) async {
    _watchLater.removeWhere((w) => w.programId == programId);
    _watchLaterIds.remove(programId);
    await _saveWatchLater();
  }

  /// Check if program is in watch later
  bool isInWatchLater(String programId) {
    return _watchLaterIds.contains(programId);
  }

  /// Get all watch later items
  List<CatchupItem> getWatchLater() {
    return List.unmodifiable(_watchLater);
  }

  /// Watch watch later stream
  Stream<List<CatchupItem>> watchWatchLater() {
    return _watchLaterController.stream;
  }

  Future<void> _saveWatchLater() async {
    try {
      final encoded = _watchLater.map((w) => w.toJson()).toList();
      await _prefs.setString(_watchLaterKey, jsonEncode(encoded));
      _watchLaterController.add(_watchLater);
    } catch (e) {
      print('Error saving watch later: $e');
    }
  }

  // ─── HISTORY ───

  /// Add program to history (FIFO with max limit)
  Future<void> addToHistory(String programId) async {
    // Remove if already exists (to update timestamp)
    _history.removeWhere((h) => h.programId == programId);

    final item = CatchupItem(
      programId: programId,
      addedAt: DateTime.now(),
    );

    // Add to beginning (most recent first)
    _history.insert(0, item);

    // Enforce FIFO limit
    if (_history.length > CatchupConfig.maxHistory) {
      _history = _history.take(CatchupConfig.maxHistory).toList();
    }

    await _saveHistory();
  }

  /// Get all history items
  List<CatchupItem> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Watch history stream
  Stream<List<CatchupItem>> watchHistory() {
    return _historyController.stream;
  }

  /// Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    try {
      final encoded = _history.map((h) => h.toJson()).toList();
      await _prefs.setString(_historyKey, jsonEncode(encoded));
      _historyController.add(_history);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  // ─── PLAYBACK PROGRESS ───

  /// Save watch progress for a program
  Future<void> saveWatchProgress({
    required String programId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final existingItem = _progress[programId];
    
    final item = existingItem?.updateProgress(
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
    ) ?? CatchupItem(
      programId: programId,
      addedAt: DateTime.now(),
      watchProgressSeconds: positionSeconds,
      totalDurationSeconds: durationSeconds,
    );

    _progress[programId] = item;
    await _saveProgress();

    // If completed, add to history
    if (item.completed) {
      await addToHistory(programId);
      // Optionally remove from watch later
      if (isInWatchLater(programId)) {
        await removeFromWatchLater(programId);
      }
    }
  }

  /// Get watch progress for a program
  CatchupItem? getWatchProgress(String programId) {
    return _progress[programId];
  }

  /// Check if program has been started
  bool hasWatchProgress(String programId) {
    return _progress.containsKey(programId);
  }

  Future<void> _saveProgress() async {
    try {
      final encoded = _progress.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await _prefs.setString(_progressKey, jsonEncode(encoded));
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  // ─── CLEANUP ───

  /// Remove expired programs from all lists
  Future<void> cleanupExpired(Set<String> expiredProgramIds) async {
    bool changed = false;

    // Remove from favorites
    final favoritesCount = _favorites.length;
    _favorites.removeWhere((f) => expiredProgramIds.contains(f.programId));
    if (_favorites.length != favoritesCount) {
      _favoriteIds.clear();
      _favoriteIds.addAll(_favorites.map((f) => f.programId));
      await _saveFavorites();
      changed = true;
    }

    // Remove from watch later
    final watchLaterCount = _watchLater.length;
    _watchLater.removeWhere((w) => expiredProgramIds.contains(w.programId));
    if (_watchLater.length != watchLaterCount) {
      _watchLaterIds.clear();
      _watchLaterIds.addAll(_watchLater.map((w) => w.programId));
      await _saveWatchLater();
      changed = true;
    }

    // Remove from progress
    final progressCount = _progress.length;
    _progress.removeWhere((key, _) => expiredProgramIds.contains(key));
    if (_progress.length != progressCount) {
      await _saveProgress();
      changed = true;
    }

    if (changed) {
      print('Cleaned up ${expiredProgramIds.length} expired programs');
    }
  }

  // ─── STATS ───

  /// Get storage statistics
  Map<String, int> getStats() {
    return {
      'favorites': _favorites.length,
      'watchLater': _watchLater.length,
      'history': _history.length,
      'progress': _progress.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _favoritesController.close();
    _watchLaterController.close();
    _historyController.close();
  }
}
