import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import '../../core/models/xtream_models.dart';
import '../../core/models/watch_history_item.dart';
import '../../core/providers/watch_providers.dart';
import '../../core/providers/channel_providers.dart';

/// Metadata passed to PlayerScreen for watch history tracking
class PlayerMeta {
  final String id; // "vod_123" or "series_456_ep_789"
  final String type; // 'movie' | 'episode' | 'catchup'
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
  // video_player (AVPlayer) - used on non-iOS platforms
  VideoPlayerController? _controller;
  // MediaKit player (mpv/ffmpeg) - used on iOS for ALL content (live + VOD)
  mk.Player? _mkPlayer;
  mkv.VideoController? _mkController;
  bool _useMediaKit = false;
  bool _isLive = false;

  Timer? _positionSaveTimer;
  String? _currentUrl;
  Duration _lastPosition = Duration.zero;
  Duration? _totalDuration;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  String? _errorMessage;
  bool _playerReady = false;
  StreamSubscription? _mkPositionSub;
  StreamSubscription? _mkDurationSub;
  StreamSubscription? _mkPlayingSub;
  StreamSubscription? _mkCompletedSub;
  StreamSubscription? _mkErrorSub;

  // TiviMate-style reconnection for live streams
  DateTime? _lastProgressTime;
  int _reconnectAttempts = 0;
  Timer? _stallDetectorTimer;
  static const int _maxReconnectAttempts = 5;

  @override
  void initState() {
    super.initState();
    // Force landscape for fullscreen playback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  void _initializePlayer() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? url;

    if (args is String) {
      url = args;
    } else if (widget.stream != null) {
      // Logic for LiveStream if passed directly
    }

    if (url == null) {
      debugPrint('Error: No URL provided for playback');
      setState(() => _errorMessage = 'No URL provided');
      return;
    }

    _currentUrl = url;

    // Determine if this is a live stream (no meta = live, or meta.type == 'live')
    _isLive = widget.meta == null || widget.meta!.type == 'live';
    // Also detect live from URL pattern
    if (url.contains('/live/')) _isLive = true;

    // On iOS, use MediaKit (mpv/ffmpeg) for ALL content — live AND VOD
    // mpv handles live HLS/MPEG-TS, reconnection, MKV, AVI, etc. far better than AVPlayer
    final isIOS = !kIsWeb && Platform.isIOS;

    if (isIOS) {
      await _initializeMediaKitPlayer(url);
    } else {
      await _initializeVideoPlayer(url);
    }
  }

  /// Initialize MediaKit player (iOS — all content: live + VOD)
  /// Uses mpv/ffmpeg backend — handles HLS, MPEG-TS, MKV, AVI, etc.
  /// TiviMate-style: auto-reconnect, stall detection, keep-open for live
  Future<void> _initializeMediaKitPlayer(String url) async {
    _useMediaKit = true;
    debugPrint('🎬 MediaKit Player (${_isLive ? "LIVE" : "VOD"}): $url');

    try {
      _mkPlayer = mk.Player(
        configuration: mk.PlayerConfiguration(
          // 64MB for live (need headroom for reconnect), 32MB for VOD
          bufferSize: _isLive ? 64 * 1024 * 1024 : 32 * 1024 * 1024,
        ),
      );

      // Configure mpv properties for live IPTV (TiviMate-style)
      if (_isLive) {
        await _configureMpvForLive(_mkPlayer!);
      }

      _mkController = mkv.VideoController(_mkPlayer!);

      // --- Stream listeners ---
      _mkPositionSub = _mkPlayer!.stream.position.listen((pos) {
        if (mounted && pos != _lastPosition) {
          _lastProgressTime = DateTime.now(); // stall detection
          _reconnectAttempts = 0; // reset on progress
          setState(() => _lastPosition = pos);
        }
      });

      _mkDurationSub = _mkPlayer!.stream.duration.listen((dur) {
        // Ignore duration for live — it's meaningless (HLS window)
        if (mounted && !_isLive && dur.inSeconds > 0) {
          setState(() => _totalDuration = dur);
        }
      });

      _mkPlayingSub = _mkPlayer!.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
        }
      });

      // CRITICAL FIX: Don't stop playback on "completed" for live streams.
      // Live HLS "completes" at edge of sliding window → reconnect instead.
      _mkCompletedSub = _mkPlayer!.stream.completed.listen((completed) {
        if (mounted && completed) {
          if (_isLive) {
            debugPrint('🔄 Live stream "completed" event → reconnecting...');
            _reconnectLiveStream();
          } else {
            setState(() => _isPlaying = false);
          }
        }
      });

      _mkErrorSub = _mkPlayer!.stream.error.listen((error) {
        if (mounted && error.isNotEmpty) {
          debugPrint('❌ MediaKit error: $error');
          if (_isLive) {
            _reconnectLiveStream();
          }
        }
      });

      // Open the media
      await _mkPlayer!.open(mk.Media(
        url,
        httpHeaders: {
          'User-Agent': 'smartersplayer',
        },
      ));

      // Seek to start position if provided (VOD only)
      if (!_isLive &&
          widget.startPosition != null &&
          widget.startPosition!.inSeconds > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _mkPlayer!.seek(widget.startPosition!);
      }

      setState(() {
        _playerReady = true;
        _isPlaying = true;
      });

      // Start stall detection for live (TiviMate-style)
      if (_isLive) {
        _startStallDetection();
      }

      // Save position periodically (VOD only)
      if (!_isLive) {
        _positionSaveTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _saveCurrentPosition(),
        );
      }

      _resetHideControlsTimer();
      debugPrint(
          '✅ MediaKit Player initialized (${_isLive ? "LIVE+reconnect" : "VOD+32MB buffer"})');
    } catch (e) {
      debugPrint('❌ MediaKit Error: $e');
      if (mounted) {
        setState(() =>
            _errorMessage = 'Error al reproducir.\n\nPrueba otro contenido.');
      }
    }
  }

  /// Configure mpv for robust live IPTV streaming (TiviMate-style)
  /// Sets reconnection, buffering, keep-open to prevent stream termination
  Future<void> _configureMpvForLive(mk.Player player) async {
    try {
      // Access the NativePlayer to set mpv properties directly
      final nativePlayer = player.platform as dynamic;

      // Auto-reconnect on network errors (libavformat level)
      await nativePlayer.setProperty(
          'stream-lavf-o',
          'reconnect=1,'
              'reconnect_streamed=1,'
              'reconnect_delay_max=5,'
              'reconnect_on_network_error=1,'
              'reconnect_on_http_error=4xx,5xx');

      // Buffer settings for live — enough headroom for brief stalls
      await nativePlayer.setProperty('cache', 'yes');
      await nativePlayer.setProperty('cache-secs', '30');
      await nativePlayer.setProperty('demuxer-max-bytes', '64MiB');
      await nativePlayer.setProperty('demuxer-readahead-secs', '30');

      // HLS: use max bitrate for best quality
      await nativePlayer.setProperty('hls-bitrate', 'max');

      // CRITICAL: Don't close the player when live stream "ends"
      await nativePlayer.setProperty('keep-open', 'yes');
      await nativePlayer.setProperty('keep-open-pause', 'no');

      // Network timeout
      await nativePlayer.setProperty('network-timeout', '30');

      // User-agent (matches IPTV Smarters)
      await nativePlayer.setProperty('user-agent', 'smartersplayer');

      debugPrint(
          '✅ mpv configured for live IPTV (reconnect + keep-open + 30s cache)');
    } catch (e) {
      // setProperty may fail on some mpv builds — non-fatal
      debugPrint('⚠️ mpv property config partial: $e');
    }
  }

  /// TiviMate-style stall detection: monitors position progress,
  /// triggers reconnect if no progress for 15 seconds
  void _startStallDetection() {
    _lastProgressTime = DateTime.now();
    _stallDetectorTimer?.cancel();

    _stallDetectorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastProgressTime == null || !_isLive || !mounted) return;

      final stalledFor = DateTime.now().difference(_lastProgressTime!);

      if (stalledFor > const Duration(seconds: 15)) {
        debugPrint(
            '🔄 Stall detected (${stalledFor.inSeconds}s without progress)');
        _reconnectLiveStream();
      }
    });
  }

  /// Reconnect live stream with exponential backoff (1s, 2s, 4s, 8s, 16s)
  Future<void> _reconnectLiveStream() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnect attempts ($_maxReconnectAttempts) reached');
      if (mounted) {
        setState(() => _errorMessage =
            'Canal sin señal.\n\nIntenta otro canal o vuelve más tarde.');
      }
      return;
    }

    _reconnectAttempts++;
    final delay =
        Duration(seconds: 1 << (_reconnectAttempts - 1)); // 1, 2, 4, 8, 16s
    debugPrint(
        '🔄 Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts (delay: ${delay.inSeconds}s)');

    await Future.delayed(delay);

    if (!mounted || _currentUrl == null) return;

    try {
      if (_useMediaKit && _mkPlayer != null) {
        // Re-open the stream (mpv handles cleanup)
        await _mkPlayer!.open(mk.Media(_currentUrl!, httpHeaders: {
          'User-Agent': 'smartersplayer',
        }));
        _lastProgressTime = DateTime.now();
        debugPrint('✅ Reconnected to live stream');
      } else if (_controller != null) {
        await _controller!.seekTo(Duration.zero);
        await _controller!.play();
        _lastProgressTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('❌ Reconnect failed: $e');
    }
  }

  /// Initialize video_player (AVPlayer) for live streams and non-iOS
  Future<void> _initializeVideoPlayer(String url) async {
    _useMediaKit = false;
    debugPrint('🎬 VideoPlayer: $url');

    try {
      _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {
          'User-Agent': 'smartersplayer',
          'Connection': 'keep-alive',
        },
      );

      await _controller!.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Stream timeout'),
          );

      if (!mounted) return;

      if (widget.startPosition != null) {
        await _controller!.seekTo(widget.startPosition!);
      }

      await _controller!.play();

      _currentUrl = url;
      setState(() {
        _isPlaying = true;
        _playerReady = true;
        _totalDuration = _controller!.value.duration;
      });

      _controller!.addListener(_onPlayerUpdate);

      _positionSaveTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _saveCurrentPosition(),
      );

      _resetHideControlsTimer();
      debugPrint('✅ VideoPlayer initialized');
    } on TimeoutException {
      debugPrint('⏱️ VideoPlayer timeout');
      if (mounted) {
        setState(() => _errorMessage =
            'El contenido tardó demasiado.\n\nPrueba más tarde.');
      }
    } catch (e) {
      debugPrint('❌ VideoPlayer error: $e');
      String friendlyError = 'Error al reproducir';
      if (e.toString().contains('HTTP 500')) {
        friendlyError = 'Error del servidor (500)';
      } else if (e.toString().contains('HTTP 404')) {
        friendlyError = 'Contenido no disponible (404)';
      } else if (e.toString().contains('resource unavailable')) {
        friendlyError = 'Stream no disponible';
      } else if (e.toString().contains('media format')) {
        friendlyError = 'Formato no compatible';
      }
      if (mounted) {
        setState(
            () => _errorMessage = '$friendlyError\n\nPrueba otro contenido.');
      }
    }
  }

  void _onPlayerUpdate() {
    if (_controller != null && _controller!.value.isInitialized) {
      final pos = _controller!.value.position;
      final dur = _controller!.value.duration;

      if (pos != _lastPosition) {
        setState(() {
          _lastPosition = pos;
          if (dur.inSeconds > 0) _totalDuration = dur;
        });
      }

      // For live streams: never mark as "completed" — the stream is ongoing.
      // Also auto-restart if the player reports not playing (network hiccup).
      if (_isLive) {
        if (!_controller!.value.isPlaying &&
            !_controller!.value.isBuffering &&
            _isPlaying) {
          // Live stream stalled — try to resume
          debugPrint('🔄 Live stream stalled, restarting playback...');
          _controller!.play();
        }
        return;
      }

      // VOD only: mark as complete when position reaches duration
      if (_controller!.value.position >= _controller!.value.duration &&
          _controller!.value.duration.inSeconds > 0) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _saveCurrentPosition() async {
    if (widget.meta == null || _currentUrl == null) return;
    if (_lastPosition.inSeconds < 10) return;

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
      debugPrint(
          'Saved position: ${_lastPosition.inSeconds}s / ${_totalDuration?.inSeconds ?? "?"}s');
    } catch (e) {
      debugPrint('Error saving position: $e');
    }
  }

  void _togglePlayPause() {
    if (_useMediaKit) {
      if (_mkPlayer == null) return;
      _mkPlayer!.playOrPause();
      _resetHideControlsTimer();
    } else {
      if (_controller == null) return;
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        _resetHideControlsTimer();
      }
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _resetHideControlsTimer();
      }
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _seekTo(Duration position) {
    if (_useMediaKit) {
      _mkPlayer?.seek(position);
    } else {
      _controller?.seekTo(position);
    }
    _resetHideControlsTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _hideControlsTimer?.cancel();
    _positionSaveTimer?.cancel();
    _stallDetectorTimer?.cancel();
    _saveCurrentPosition();

    if (_useMediaKit) {
      _mkPositionSub?.cancel();
      _mkDurationSub?.cancel();
      _mkPlayingSub?.cancel();
      _mkCompletedSub?.cancel();
      _mkErrorSub?.cancel();
      _mkPlayer?.dispose();
    } else {
      _controller?.removeListener(_onPlayerUpdate);
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al reproducir',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading while player initializes
    if (!_playerReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text('Cargando...', style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video player - MediaKit or VideoPlayer
            Center(
              child: _useMediaKit
                  ? (_mkController != null
                      ? mkv.Video(
                          controller: _mkController!,
                          fill: Colors.black,
                        )
                      : const SizedBox())
                  : (_controller != null && _controller!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : const SizedBox(),
            ),

            // Controls overlay
            if (_showControls)
              Container(
                color: Colors.black45,
                child: Column(
                  children: [
                    // Top bar
                    SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              widget.meta?.title ?? widget.stream?.name ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Center play/pause button
                    Center(
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),

                    const Spacer(),

                    // Bottom controls
                    SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          if (_isLive)
                            // LIVE indicator — no seek bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle,
                                            color: Colors.white, size: 8),
                                        SizedBox(width: 6),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // VOD progress bar with seek
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    _formatDuration(_lastPosition),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _lastPosition.inSeconds
                                          .toDouble()
                                          .clamp(
                                              0,
                                              (_totalDuration?.inSeconds ?? 1)
                                                  .toDouble()),
                                      max: (_totalDuration?.inSeconds ?? 1)
                                          .toDouble(),
                                      onChanged: (value) {
                                        _seekTo(
                                            Duration(seconds: value.toInt()));
                                      },
                                      activeColor: Colors.red,
                                      inactiveColor: Colors.white30,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(
                                        _totalDuration ?? Duration.zero),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
