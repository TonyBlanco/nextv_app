import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform-specific configuration for catch-up TV feature
/// 
/// Provides optimized settings for different platforms to ensure
/// performance and memory constraints are respected.
class CatchupConfig {
  CatchupConfig._();

  // ─── CACHE LIMITS ───
  
  /// Maximum number of programs to cache in memory
  static int getMaxCacheSize() {
    if (kIsWeb) return 50; // Web: limited by browser memory
    if (Platform.isAndroid || Platform.isIOS) return 50; // Mobile: conservative
    if (_isWebOS() || _isAndroidTV()) return 75; // TV: medium cache
    return 100; // Desktop: full cache
  }

  // ─── PAGINATION ───
  
  /// Number of programs to load per page
  static int getPageSize() {
    if (_isWebOS()) return 15; // WebOS: smaller pages for memory
    if (Platform.isAndroid || Platform.isIOS) return 20; // Mobile: standard
    return 30; // Desktop/Web: larger pages
  }

  // ─── IMAGE LOADING ───
  
  /// Whether to preload thumbnails
  static bool shouldPreloadThumbnails() {
    return !_isWebOS(); // WebOS: no preload due to limited RAM
  }

  /// Memory cache width for thumbnails (pixels)
  static int getThumbnailCacheWidth() {
    if (_isWebOS()) return 150; // WebOS: smaller cache
    if (Platform.isAndroid || Platform.isIOS) return 200; // Mobile: medium
    return 300; // Desktop: full quality
  }

  // ─── STORAGE LIMITS ───
  
  /// Maximum favorites to store
  static const int maxFavorites = 50;

  /// Maximum watch later items
  static const int maxWatchLater = 30;

  /// Maximum history items (FIFO)
  static const int maxHistory = 50;

  // ─── CLEANUP ───
  
  /// Interval for automatic cleanup of expired programs
  static Duration getCleanupInterval() {
    return const Duration(hours: 24);
  }

  /// Minimum retention days (guaranteed)
  static const int minRetentionDays = 3;

  // ─── UI SETTINGS ───
  
  /// Grid columns for program cards
  static int getGridColumns() {
    if (_isWebOS() || _isAndroidTV()) return 3; // TV: 3 columns
    if (Platform.isAndroid || Platform.isIOS) return 2; // Mobile: 2 columns
    return 4; // Desktop: 4 columns
  }

  /// Touch target size for TV mode
  static double getTouchTargetSize() {
    if (_isWebOS() || _isAndroidTV()) return 60.0; // TV: large targets
    return 48.0; // Mobile/Desktop: standard
  }

  // ─── PLATFORM DETECTION ───
  
  /// Check if running on WebOS
  static bool _isWebOS() {
    if (kIsWeb) return false;
    try {
      // WebOS detection via environment or platform
      return Platform.environment.containsKey('WEBOS_SYSTEM') ||
          Platform.operatingSystem.toLowerCase().contains('webos');
    } catch (_) {
      return false;
    }
  }

  /// Check if running on Android TV
  static bool _isAndroidTV() {
    if (!Platform.isAndroid) return false;
    // Note: This is a simplified check. In production, you'd check
    // for TV features via platform channels
    return false; // TODO: Implement proper Android TV detection
  }

  // ─── PERFORMANCE ───
  
  /// Debounce duration for search input
  static const Duration searchDebounce = Duration(milliseconds: 500);

  /// Progress save interval during playback
  static const Duration progressSaveInterval = Duration(seconds: 10);

  /// Completion threshold (percentage)
  static const double completionThreshold = 0.9; // 90%
}
