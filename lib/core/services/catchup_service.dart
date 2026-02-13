import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/catchup_program.dart';
import '../models/catchup_filter.dart';
import '../constants/catchup_config.dart';
import 'xtream_api_service.dart';

/// Service for managing catch-up/replay TV functionality
/// 
/// Provides API integration with Xtream Codes timeshift endpoints,
/// caching, filtering, and platform-specific optimizations.
class CatchupService {
  final XtreamAPIService _apiService;
  
  // Cache: channelId -> List<CatchupProgram>
  final Map<int, List<CatchupProgram>> _cache = {};
  final Map<int, DateTime> _cacheTimestamps = {};
  
  // Cache duration before refresh
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  // Cleanup timer
  Timer? _cleanupTimer;

  CatchupService(this._apiService) {
    _startCleanupTimer();
  }

  // ─── AVAILABILITY ───

  /// Get available retention days from provider (minimum 3 days)
  Future<int> getAvailableDays() async {
    // TODO: Query provider's actual retention period
    // For now, return minimum guaranteed
    return CatchupConfig.minRetentionDays;
  }

  // ─── FETCH PROGRAMS ───

  /// Get catch-up programs for a specific channel
  Future<List<CatchupProgram>> getCatchupForChannel(
    int channelId, {
    int? days,
  }) async {
    // Check cache first
    if (_isCacheValid(channelId)) {
      debugPrint('📦 Returning cached catch-up for channel $channelId');
      return _cache[channelId]!;
    }

    try {
      debugPrint('🔄 Fetching catch-up for channel $channelId');
      
      // Get EPG data from Xtream API
      final epgData = await _apiService.getEPG(channelId);
      
      if (epgData.isEmpty) {
        debugPrint('⚠️ No EPG data for channel $channelId');
        return [];
      }

      // Filter and convert to CatchupProgram
      final programs = <CatchupProgram>[];
      final now = DateTime.now();
      final retentionDays = days ?? await getAvailableDays();
      final cutoffTime = now.subtract(Duration(days: retentionDays));

      for (final epgItem in epgData) {
        try {
          // Parse EPG item
          final startTime = _parseEpgTime(epgItem['start']);
          final endTime = _parseEpgTime(epgItem['end']);
          
          if (startTime == null || endTime == null) continue;
          
          // Only include past programs within retention period
          if (startTime.isAfter(now)) continue; // Future program
          if (startTime.isBefore(cutoffTime)) continue; // Too old
          
          // Check if catch-up is available
          final hasArchive = epgItem['has_archive'] == 1 || 
                            epgItem['has_archive'] == '1' ||
                            epgItem['has_archive'] == true;
          
          if (!hasArchive) continue;

          // Build catch-up stream URL
          final streamUrl = _buildCatchupStreamUrl(
            channelId: channelId,
            startTime: startTime,
            duration: endTime.difference(startTime),
          );

          final program = CatchupProgram.fromEpgProgram(
            id: '${channelId}_${startTime.millisecondsSinceEpoch}',
            channelId: channelId,
            channelName: epgItem['channel_name'] ?? 'Unknown',
            channelLogo: epgItem['channel_logo'] ?? '',
            title: epgItem['title'] ?? 'Unknown Program',
            description: epgItem['description'] ?? '',
            startTime: startTime,
            endTime: endTime,
            streamUrl: streamUrl,
            thumbnailUrl: epgItem['cover'] ?? epgItem['icon'],
            category: epgItem['category'],
            retentionDays: retentionDays,
          );

          programs.add(program);
        } catch (e) {
          debugPrint('⚠️ Error parsing EPG item: $e');
          continue;
        }
      }

      // Sort by newest first
      programs.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Update cache
      _updateCache(channelId, programs);

      debugPrint('✅ Found ${programs.length} catch-up programs for channel $channelId');
      return programs;
      
    } catch (e) {
      debugPrint('❌ Error fetching catch-up for channel $channelId: $e');
      return [];
    }
  }

  /// Get all catch-up programs with optional filters
  Future<List<CatchupProgram>> getCatchupPrograms({
    CatchupFilter? filter,
    int page = 0,
    int pageSize = 20,
  }) async {
    // If filtering by specific channel, use getCatchupForChannel
    if (filter?.channelId != null) {
      final programs = await getCatchupForChannel(filter!.channelId!);
      return _applyFiltersAndPagination(programs, filter, page, pageSize);
    }

    // TODO: Implement fetching from multiple channels
    // For now, return empty list if no channel specified
    debugPrint('⚠️ getCatchupPrograms requires channelId filter');
    return [];
  }

  /// Search catch-up content
  Future<List<CatchupProgram>> searchCatchup(String query) async {
    if (query.trim().isEmpty) return [];

    final allPrograms = <CatchupProgram>[];
    
    // Search in cached channels
    for (final programs in _cache.values) {
      allPrograms.addAll(programs);
    }

    // Filter by query
    final lowerQuery = query.toLowerCase();
    final results = allPrograms.where((program) {
      return program.title.toLowerCase().contains(lowerQuery) ||
             program.description.toLowerCase().contains(lowerQuery) ||
             program.channelName.toLowerCase().contains(lowerQuery);
    }).toList();

    // Sort by relevance (title match first, then description)
    results.sort((a, b) {
      final aTitle = a.title.toLowerCase().contains(lowerQuery);
      final bTitle = b.title.toLowerCase().contains(lowerQuery);
      if (aTitle && !bTitle) return -1;
      if (!aTitle && bTitle) return 1;
      return b.startTime.compareTo(a.startTime); // Newest first
    });

    return results;
  }

  // ─── STREAM URL ───

  /// Build catch-up stream URL for Xtream Codes timeshift
  String _buildCatchupStreamUrl({
    required int channelId,
    required DateTime startTime,
    required Duration duration,
  }) {
    if (!_apiService.isInitialized) {
      throw Exception('API service not initialized');
    }

    final credentials = _apiService.credentials!;
    final timestamp = (startTime.millisecondsSinceEpoch / 1000).floor();
    final durationSeconds = duration.inSeconds;

    // Xtream Codes timeshift URL format
    return '${credentials.serverUrl}/streaming/timeshift.php?'
        'username=${credentials.username}&'
        'password=${credentials.password}&'
        'stream=$channelId&'
        'start=$timestamp&'
        'duration=$durationSeconds';
  }

  /// Get catch-up stream URL for a program
  Future<String> getCatchupStreamUrl(CatchupProgram program) async {
    // URL is already built in the program model
    return program.streamUrl;
  }

  // ─── FILTERING & SORTING ───

  List<CatchupProgram> _applyFiltersAndPagination(
    List<CatchupProgram> programs,
    CatchupFilter? filter,
    int page,
    int pageSize,
  ) {
    var filtered = programs;

    if (filter != null) {
      // Apply category filter
      if (filter.category != null) {
        filtered = filtered.where((p) => p.category == filter.category).toList();
      }

      // Apply date range filter
      if (filter.dateRange != null) {
        filtered = filtered.where((p) {
          return p.startTime.isAfter(filter.dateRange!.start) &&
                 p.startTime.isBefore(filter.dateRange!.end);
        }).toList();
      }

      // Apply search query
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        filtered = filtered.where((p) {
          return p.title.toLowerCase().contains(query) ||
                 p.description.toLowerCase().contains(query);
        }).toList();
      }

      // Apply sort order
      switch (filter.sortOrder) {
        case CatchupSortOrder.newestFirst:
          filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
          break;
        case CatchupSortOrder.oldestFirst:
          filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
          break;
        case CatchupSortOrder.channelName:
          filtered.sort((a, b) => a.channelName.compareTo(b.channelName));
          break;
        case CatchupSortOrder.programName:
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
      }
    }

    // Apply pagination
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    
    if (start >= filtered.length) return [];
    
    return filtered.sublist(start, end);
  }

  // ─── CACHE MANAGEMENT ───

  bool _isCacheValid(int channelId) {
    if (!_cache.containsKey(channelId)) return false;
    
    final timestamp = _cacheTimestamps[channelId];
    if (timestamp == null) return false;
    
    final age = DateTime.now().difference(timestamp);
    return age < _cacheDuration;
  }

  void _updateCache(int channelId, List<CatchupProgram> programs) {
    _cache[channelId] = programs;
    _cacheTimestamps[channelId] = DateTime.now();
    _limitCache();
  }

  void _limitCache() {
    final maxSize = CatchupConfig.getMaxCacheSize();
    
    if (_cache.length <= maxSize) return;

    // Remove oldest entries
    final entries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final toRemove = entries.take(_cache.length - maxSize);
    for (final entry in toRemove) {
      _cache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }

    debugPrint('🧹 Cache limited to $maxSize entries');
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('🧹 Cache cleared');
  }

  // ─── CLEANUP ───

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      CatchupConfig.getCleanupInterval(),
      (_) => _cleanupExpired(),
    );
  }

  void _cleanupExpired() {
    debugPrint('🧹 Running expired programs cleanup');
    
    int removedCount = 0;
    
    for (final channelId in _cache.keys.toList()) {
      final programs = _cache[channelId]!;
      final validPrograms = programs.where((p) => !p.isExpired).toList();
      
      if (validPrograms.length != programs.length) {
        _cache[channelId] = validPrograms;
        removedCount += programs.length - validPrograms.length;
      }
    }

    if (removedCount > 0) {
      debugPrint('🧹 Removed $removedCount expired programs');
    }
  }

  /// Manually trigger cleanup of expired programs
  Future<Set<String>> cleanupExpired() async {
    final expiredIds = <String>{};
    
    for (final programs in _cache.values) {
      for (final program in programs) {
        if (program.isExpired) {
          expiredIds.add(program.id);
        }
      }
    }

    _cleanupExpired();
    return expiredIds;
  }

  // ─── UTILITIES ───

  DateTime? _parseEpgTime(dynamic timeValue) {
    if (timeValue == null) return null;
    
    try {
      if (timeValue is String) {
        // Try parsing ISO 8601 format
        return DateTime.parse(timeValue);
      } else if (timeValue is int) {
        // Unix timestamp
        return DateTime.fromMillisecondsSinceEpoch(timeValue * 1000);
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing time: $timeValue - $e');
    }
    
    return null;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'channels': _cache.length,
      'totalPrograms': _cache.values.fold(0, (sum, list) => sum + list.length),
      'maxSize': CatchupConfig.getMaxCacheSize(),
    };
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
