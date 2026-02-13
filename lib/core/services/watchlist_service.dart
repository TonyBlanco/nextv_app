import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_item.dart';

/// Service for managing Watch Later bookmarks
class WatchlistService {
  static const String _storageKey = 'watchlist_v1';

  final SharedPreferences _prefs;
  List<WatchlistItem> _items = [];
  final Set<String> _itemIds = {};

  WatchlistService(this._prefs) {
    _load();
  }

  void _load() {
    try {
      final json = _prefs.getString(_storageKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _items = decoded
            .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _itemIds.clear();
        _itemIds.addAll(_items.map((i) => i.id));
      }
    } catch (e) {
      debugPrint('Error loading watchlist: $e');
      _items = [];
      _itemIds.clear();
    }
  }

  Future<void> _save() async {
    try {
      final encoded = _items.map((e) => e.toJson()).toList();
      await _prefs.setString(_storageKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving watchlist: $e');
    }
  }

  /// Add to watchlist
  Future<void> add(WatchlistItem item) async {
    if (_itemIds.contains(item.id)) return;
    _items.insert(0, item);
    _itemIds.add(item.id);
    await _save();
  }

  /// Remove from watchlist
  Future<void> remove(String id) async {
    _items.removeWhere((i) => i.id == id);
    _itemIds.remove(id);
    await _save();
  }

  /// Toggle watchlist status
  Future<void> toggle(WatchlistItem item) async {
    if (isInWatchlist(item.id)) {
      await remove(item.id);
    } else {
      await add(item);
    }
  }

  /// Check if item is in watchlist
  bool isInWatchlist(String id) => _itemIds.contains(id);

  /// Get all watchlist items sorted by most recent
  List<WatchlistItem> getWatchlist() => List.unmodifiable(_items);

  /// Clear all
  Future<void> clearAll() async {
    _items.clear();
    _itemIds.clear();
    await _save();
  }

  int get count => _items.length;
}
