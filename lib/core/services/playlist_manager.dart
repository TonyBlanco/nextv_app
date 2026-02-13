import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/playlist_model.dart';

/// Playlist manager state notifier provider
final playlistManagerProvider = StateNotifierProvider<PlaylistManagerNotifier, List<Playlist>>((ref) {
  return PlaylistManagerNotifier();
});

/// Playlist manager state notifier
class PlaylistManagerNotifier extends StateNotifier<List<Playlist>> {
  PlaylistManagerNotifier() : super([]);

  Future<void> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    
    // On web, getStringList may return a String instead of List
    // Handle both cases for cross-platform compatibility
    List<String> playlistsJson = [];
    
    try {
      final rawData = prefs.get('playlists');
      
      if (rawData is List) {
        // Normal case: List<String>
        playlistsJson = (rawData as List).cast<String>();
      } else if (rawData is String) {
        // Web case: might be a JSON string representing the list
        try {
          final decoded = jsonDecode(rawData);
          if (decoded is List) {
            playlistsJson = (decoded as List).cast<String>();
          }
        } catch (_) {
          // If it's a single JSON object, wrap it in a list
          playlistsJson = [rawData];
        }
      }
    } catch (e) {
      // Fallback to empty list on any error
      playlistsJson = [];
    }
    
    final playlists = <Playlist>[];
    for (final json in playlistsJson) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        playlists.add(Playlist.fromJson(map));
      } catch (_) {
        // Skip invalid entries
      }
    }
    
    state = playlists;
  }

  Future<void> addPlaylist(Playlist playlist) async {
    state = [...state, playlist];
    await _savePlaylists();
  }

  Future<void> removePlaylist(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _savePlaylists();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    state = state.map((p) => p.id == playlist.id ? playlist : p).toList();
    await _savePlaylists();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = state.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('playlists', playlistsJson);
  }

  Playlist? getPlaylistById(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find duplicate playlist by matching server/username or M3U URL
  Playlist? findDuplicate(Playlist playlist) {
    try {
      return state.firstWhere((p) {
        if (p.id == playlist.id) return false;
        if (playlist.m3uUrl != null && p.m3uUrl == playlist.m3uUrl) return true;
        if (playlist.serverUrl != null && p.serverUrl == playlist.serverUrl &&
            playlist.username != null && p.username == playlist.username) return true;
        return false;
      });
    } catch (_) {
      return null;
    }
  }
}
