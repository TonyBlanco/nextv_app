import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/channel_status_service.dart';
import '../services/epg_service.dart';
import '../services/xtream_api_service.dart';
import '../services/stream_validator_service.dart';
import '../models/xtream_models.dart';

// ==================== LIVE STREAMS PROVIDER ====================

/// Provider for live streams with archive support (used by catchup_screen)
final liveStreamsProvider = FutureProvider<List<LiveStream>>((ref) async {
  final api = ref.watch(xtreamAPIProvider);
  try {
    final streams = await api.getLiveStreams();
    // Filter to only channels with TV archive (catchup) support
    return streams.where((s) => s.tvArchive > 0).toList();
  } catch (e) {
    return [];
  }
});

/// Provider for live streams by category
final liveCategoryStreamsProvider = FutureProvider.family<List<LiveStream>, String>((ref, categoryId) async {
  final api = ref.watch(xtreamAPIProvider);
  return api.getLiveStreams(categoryId: categoryId);
});

// ==================== SERVICE PROVIDERS ====================

/// Provider for ChannelStatusService
final channelStatusServiceProvider = Provider<ChannelStatusService>((ref) {
  final service = ChannelStatusService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for EPGService
final epgServiceProvider = Provider<EPGService>((ref) {
  return EPGService();
});

/// Provider for StreamValidatorService
final streamValidatorServiceProvider = Provider<StreamValidatorService>((ref) {
  final service = StreamValidatorService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ==================== STREAM PROVIDERS ====================

/// Stream provider for all channel statuses
final channelStatusesProvider = StreamProvider<Map<int, ChannelStatus>>((ref) {
  final service = ref.watch(channelStatusServiceProvider);
  return service.watchStatuses();
});

// ==================== FAMILY PROVIDERS ====================

/// Provider for individual channel status
final channelStatusProvider = Provider.family<ChannelStatus?, int>((ref, streamId) {
  final statusesAsync = ref.watch(channelStatusesProvider);
  return statusesAsync.when(
    data: (statuses) => statuses[streamId],
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Future provider for EPG quick info
final epgQuickInfoProvider = Provider.family<EPGQuickInfo?, String>((ref, channelId) {
  final epgService = ref.watch(epgServiceProvider);
  return epgService.getQuickInfo(channelId);
});

/// Provider to check if a channel is live
final isChannelLiveProvider = Provider.family<bool, int>((ref, streamId) {
  final status = ref.watch(channelStatusProvider(streamId));
  return status?.isLive ?? false;
});
