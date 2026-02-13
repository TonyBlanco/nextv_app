import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/xtream_models.dart';

/// Service for checking live channel status
class ChannelStatusService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  final Map<int, ChannelStatus> _statusCache = {};
  final StreamController<Map<int, ChannelStatus>> _controller =
      StreamController<Map<int, ChannelStatus>>.broadcast();

  static const int _batchSize = 10;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Watch all channel statuses
  Stream<Map<int, ChannelStatus>> watchStatuses() => _controller.stream;

  /// Get cached status for a channel
  ChannelStatus? getCachedStatus(int streamId) {
    final status = _statusCache[streamId];
    if (status != null && !status.isStale) {
      return status;
    }
    return null;
  }

  /// Check if a single channel is live
  Future<ChannelStatus> checkChannelStatus(
    String streamUrl,
    int streamId,
  ) async {
    // On web, skip health checks (CORS issues) and assume channels are live
    if (kIsWeb) {
      final status = ChannelStatus(
        streamId: streamId,
        isLive: true, // Assume live on web
        lastChecked: DateTime.now(),
      );
      _updateCache(status);
      return status;
    }

    try {
      // Use HEAD request for lightweight check
      final response = await _dio.head(streamUrl);
      
      final isLive = response.statusCode == 200;
      final bitrate = _extractBitrate(response.headers);

      final status = ChannelStatus(
        streamId: streamId,
        isLive: isLive,
        lastChecked: DateTime.now(),
        bitrate: bitrate,
      );

      _updateCache(status);
      return status;
    } catch (e) {
      // On native platforms: if request fails, assume offline
      // On web: this shouldn't happen since we skip checks
      final status = ChannelStatus(
        streamId: streamId,
        isLive: kIsWeb, // true on web, false on native
        lastChecked: DateTime.now(),
      );
      _updateCache(status);
      return status;
    }
  }

  /// Batch check multiple channels (processes in batches to avoid overwhelming server)
  Future<void> batchCheckChannels(
    List<LiveStream> channels,
    String serverUrl,
    String username,
    String password,
  ) async {
    for (int i = 0; i < channels.length; i += _batchSize) {
      final batch = channels.skip(i).take(_batchSize).toList();
      
      // Process batch in parallel
      await Future.wait(
        batch.map((channel) {
          final streamUrl = channel.getStreamUrl(serverUrl, username, password);
          return checkChannelStatus(streamUrl, channel.streamId);
        }),
      );

      // Small delay between batches to avoid rate limiting
      if (i + _batchSize < channels.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Check only visible channels (for lazy loading)
  Future<void> checkVisibleChannels(
    List<LiveStream> visibleChannels,
    String serverUrl,
    String username,
    String password,
  ) async {
    final channelsToCheck = visibleChannels.where((channel) {
      final cached = getCachedStatus(channel.streamId);
      return cached == null; // Only check if not cached or stale
    }).toList();

    if (channelsToCheck.isEmpty) return;

    await batchCheckChannels(channelsToCheck, serverUrl, username, password);
  }

  /// Clear stale cache entries
  void clearStaleCache() {
    _statusCache.removeWhere((_, status) => status.isStale);
    _notifyListeners();
  }

  /// Clear all cache
  void clearCache() {
    _statusCache.clear();
    _notifyListeners();
  }

  /// Extract bitrate from response headers if available
  int? _extractBitrate(Headers headers) {
    try {
      final contentLength = headers.value('content-length');
      if (contentLength != null) {
        return int.tryParse(contentLength);
      }
    } catch (_) {}
    return null;
  }

  /// Update cache and notify listeners
  void _updateCache(ChannelStatus status) {
    _statusCache[status.streamId] = status;
    _notifyListeners();
  }

  /// Notify all listeners of cache update
  void _notifyListeners() {
    if (!_controller.isClosed) {
      _controller.add(Map.from(_statusCache));
    }
  }

  /// Dispose resources
  void dispose() {
    _controller.close();
    _dio.close();
  }
}
