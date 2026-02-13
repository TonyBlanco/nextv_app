import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watch_history_item.dart';
import '../models/watchlist_item.dart';
import '../services/watch_history_service.dart';
import '../services/watchlist_service.dart';
import 'favorites_provider.dart'; // for sharedPreferencesProvider

// ==================== WATCH HISTORY (Continue Watching) ====================

final watchHistoryServiceProvider = Provider<WatchHistoryService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WatchHistoryService(prefs);
});

final watchHistoryProvider = Provider<List<WatchHistoryItem>>((ref) {
  final service = ref.watch(watchHistoryServiceProvider);
  return service.getHistory();
});

// ==================== WATCHLIST (Watch Later) ====================

final watchlistServiceProvider = Provider<WatchlistService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WatchlistService(prefs);
});

final watchlistProvider = Provider<List<WatchlistItem>>((ref) {
  final service = ref.watch(watchlistServiceProvider);
  return service.getWatchlist();
});

final isInWatchlistProvider = Provider.family<bool, String>((ref, id) {
  final service = ref.watch(watchlistServiceProvider);
  return service.isInWatchlist(id);
});
