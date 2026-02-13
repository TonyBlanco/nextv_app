import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/xtream_models.dart';
import '../../core/models/watch_history_item.dart';
import '../../core/providers/watch_providers.dart';
import '../../presentation/widgets/html5_video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Metadata passed to PlayerScreen for watch history tracking
class PlayerMeta {
  final String id;         // "vod_123" or "series_456_ep_789"
  final String type;       // 'movie' | 'episode'
  final String title;
  final String? seriesName;
  final String imageUrl;
  final int streamId;

  const PlayerMeta({
    required this.id,
    required this.type,
    required this.title,
    this.seriesName,
    required this.imageUrl,
    required this.streamId,
  });
}

class PlayerScreen extends ConsumerStatefulWidget {
  final LiveStream? stream;
  final Duration? startPosition;
  final PlayerMeta? meta;

  const PlayerScreen({
    super.key,
    this.stream,
    this.startPosition,
    this.meta,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  BetterPlayerController? _betterPlayerController;
  Timer? _positionSaveTimer;
  String? _currentUrl;
  Duration _lastPosition = Duration.zero;
  Duration? _totalDuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  void _initializePlayer() {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? url;

    if (args is String) {
      url = args;
    } else if (widget.stream != null) {
      // Logic for LiveStream if passed directly
    }

    if (url == null) {
      debugPrint('Error: No URL provided for playback');
      return;
    }

    _currentUrl = url;
    debugPrint('Initializing BetterPlayer with URL: $url');

    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: false,
      allowedScreenSleep: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableSkips: true,
        enableFullscreen: true,
        enablePip: true,
        enablePlayPause: true,
        enableMute: true,
        enableProgressBar: true,
        enableProgressBarDrag: true,
        controlBarColor: Colors.black45,
        loadingColor: Colors.red,
        overflowModalColor: Colors.black87,
        overflowMenuIconsColor: Colors.white,
      ),
    );

    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: BetterPlayerVideoFormat.other,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 5000,
        maxBufferMs: 13107200,
        bufferForPlaybackMs: 2500,
        bufferForPlaybackAfterRebufferMs: 5000,
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController!.setupDataSource(dataSource);

    // Seek to start position if provided (Continue Watching resume)
    if (widget.startPosition != null) {
      _betterPlayerController!.seekTo(widget.startPosition!);
    }

    // Listen for events to track position and duration
    _betterPlayerController!.addEventsListener(_onPlayerEvent);

    // Start periodic position saving every 30 seconds
    _positionSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveCurrentPosition(),
    );

    setState(() {});
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      final pos = _betterPlayerController?.videoPlayerController?.value.position;
      final dur = _betterPlayerController?.videoPlayerController?.value.duration;
      if (pos != null) _lastPosition = pos;
      if (dur != null && dur.inSeconds > 0) _totalDuration = dur;
    }
  }

  Future<void> _saveCurrentPosition() async {
    if (widget.meta == null || _currentUrl == null) return;
    if (_lastPosition.inSeconds < 10) return; // Don't save if < 10s watched

    final meta = widget.meta!;
    final item = WatchHistoryItem(
      id: meta.id,
      type: meta.type,
      title: meta.title,
      seriesName: meta.seriesName,
      imageUrl: meta.imageUrl,
      playbackUrl: _currentUrl!,
      position: _lastPosition,
      duration: _totalDuration,
      lastWatched: DateTime.now(),
      streamId: meta.streamId,
    );

    try {
      final service = ref.read(watchHistoryServiceProvider);
      await service.addOrUpdate(item);
      debugPrint('Saved watch position: ${_lastPosition.inSeconds}s / ${_totalDuration?.inSeconds ?? "?"}s');
    } catch (e) {
      debugPrint('Error saving watch position: $e');
    }
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    // Save final position before closing
    _saveCurrentPosition();
    _betterPlayerController?.removeEventsListener(_onPlayerEvent);
    _betterPlayerController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (_currentUrl == null) {
         return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.red)),
         );
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Html5VideoPlayer(
             url: _currentUrl!,
             autoPlay: true,
             controls: true,
             isLive: false, // VOD content
          ),
        ),
      );
    }

    if (_betterPlayerController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BetterPlayer(
          controller: _betterPlayerController!,
        ),
      ),
    );
  }
}
