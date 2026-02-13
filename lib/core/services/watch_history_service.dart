import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_history_item.dart';

/// Service for managing watch history (Continue Watching)
class WatchHistoryService {
  static const String _storageKey = 'watch_history_v1';
  static const int _maxItems = 20;

  final SharedPreferences _prefs;
  List<WatchHistoryItem> _history = [];

  WatchHistoryService(this._prefs) {
    _load();
  }

  void _load() {
    try {
      final json = _prefs.getString(_storageKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _history = decoded
            .map((e) => WatchHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      _history = [];
    }
  }

  Future<void> _save() async {
    try {
      final encoded = _history.map((e) => e.toJson()).toList();
      await _prefs.setString(_storageKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving watch history: $e');
    }
  }

  /// Add or update a watch history entry (upsert)
  Future<void> addOrUpdate(WatchHistoryItem item) async {
    _history.removeWhere((h) => h.id == item.id);
    _history.insert(0, item);
    if (_history.length > _maxItems) {
      _history = _history.sublist(0, _maxItems);
    }
    await _save();
  }

  /// Get all history items sorted by most recent
  List<WatchHistoryItem> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Get a specific history item by id
  WatchHistoryItem? getById(String id) {
    try {
      return _history.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Remove a history item
  Future<void> remove(String id) async {
    _history.removeWhere((h) => h.id == id);
    await _save();
  }

  /// Clear all history
  Future<void> clearAll() async {
    _history.clear();
    await _save();
  }

  int get count => _history.length;
}
