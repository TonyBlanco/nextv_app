import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/catchup_program.dart';
import '../models/catchup_item.dart';
import '../models/catchup_filter.dart';
import '../services/catchup_service.dart';
import '../services/catchup_storage_service.dart';
import '../services/catchup_playback_service.dart';
import '../services/xtream_api_service.dart';

// ─── SHARED PREFERENCES ───

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ─── SERVICE PROVIDERS ───

/// Catch-up service provider
final catchupServiceProvider = Provider<CatchupService>((ref) {
  final apiService = ref.watch(xtreamAPIProvider);
  return CatchupService(apiService);
});

/// Catch-up storage service provider
final catchupStorageServiceProvider = Provider<CatchupStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  final service = CatchupStorageService(prefs);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Catch-up playback service provider
final catchupPlaybackServiceProvider = Provider<CatchupPlaybackService>((ref) {
  final storageService = ref.watch(catchupStorageServiceProvider);
  return CatchupPlaybackService(storageService);
});

// ─── DATA PROVIDERS ───

/// Get catch-up programs for a specific channel
final catchupForChannelProvider = FutureProvider.family<List<CatchupProgram>, int>(
  (ref, channelId) async {
    final service = ref.watch(catchupServiceProvider);
    return service.getCatchupForChannel(channelId);
  },
);

/// Get catch-up programs with filters
final catchupProgramsProvider = FutureProvider.family<List<CatchupProgram>, CatchupFilter?>(
  (ref, filter) async {
    final service = ref.watch(catchupServiceProvider);
    return service.getCatchupPrograms(filter: filter);
  },
);

/// Search catch-up programs
final catchupSearchProvider = FutureProvider.family<List<CatchupProgram>, String>(
  (ref, query) async {
    final service = ref.watch(catchupServiceProvider);
    return service.searchCatchup(query);
  },
);

// ─── STORAGE STREAM PROVIDERS ───

/// Watch favorites stream
final catchupFavoritesProvider = StreamProvider<List<CatchupItem>>((ref) {
  final storage = ref.watch(catchupStorageServiceProvider);
  return storage.watchFavorites();
});

/// Watch watch later stream
final watchLaterProvider = StreamProvider<List<CatchupItem>>((ref) {
  final storage = ref.watch(catchupStorageServiceProvider);
  return storage.watchWatchLater();
});

/// Watch history stream
final catchupHistoryProvider = StreamProvider<List<CatchupItem>>((ref) {
  final storage = ref.watch(catchupStorageServiceProvider);
  return storage.watchHistory();
});

// ─── STATE PROVIDERS ───

/// Current filter state
final catchupFiltersProvider = StateProvider<CatchupFilter>((ref) {
  return const CatchupFilter();
});

/// Current page for pagination
final catchupPageProvider = StateProvider<int>((ref) {
  return 0;
});

// ─── LOOKUP PROVIDERS ───

/// Check if program is a favorite (fast lookup)
final isCatchupFavoriteProvider = Provider.family<bool, String>((ref, programId) {
  final favorites = ref.watch(catchupFavoritesProvider).value ?? [];
  return favorites.any((item) => item.programId == programId);
});

/// Check if program is in watch later
final isInWatchLaterProvider = Provider.family<bool, String>((ref, programId) {
  final watchLater = ref.watch(watchLaterProvider).value ?? [];
  return watchLater.any((item) => item.programId == programId);
});

/// Get watch progress for a program
final watchProgressProvider = Provider.family<CatchupItem?, String>((ref, programId) {
  final storage = ref.watch(catchupStorageServiceProvider);
  return storage.getWatchProgress(programId);
});

// ─── STATS PROVIDERS ───

/// Get storage statistics
final catchupStatsProvider = Provider<Map<String, int>>((ref) {
  final storage = ref.watch(catchupStorageServiceProvider);
  return storage.getStats();
});

/// Get cache statistics
final catchupCacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(catchupServiceProvider);
  return service.getCacheStats();
});
