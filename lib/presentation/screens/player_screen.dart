import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/xtream_models.dart';
import '../../core/models/watch_history_item.dart';
import '../../core/providers/watch_providers.dart';
import '../../core/providers/channel_providers.dart';

/// Metadata passed to PlayerScreen for watch history tracking
class PlayerMeta {
  final String id;         // "vod_123" or "series_456_ep_789"
  final String type;       // 'movie' | 'episode' | 'catchup'
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
  VideoPlayerController? _controller;
  Timer? _positionSaveTimer;
  String? _currentUrl;
  Duration _lastPosition = Duration.zero;
  Duration? _totalDuration;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
    debugPrint('🎬 Initializing VideoPlayer with URL: $url');

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {
          'User-Agent': 'smartersplayer',
          'Connection': 'keep-alive',
        },
      );
      
      // Reduced timeout to 8 seconds for faster skip of broken streams
      await _controller!.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Stream took too long to respond');
        },
      );
      
      if (!mounted) return;

      // Check if video actually has valid dimensions (not just audio)
      final videoValue = _controller!.value;
      if (videoValue.size.width == 0 || videoValue.size.height == 0) {
        debugPrint('⚠️ Warning: Video has no dimensions (audio only?)');
        // Don't throw error - some streams start with audio first
      }

      // Seek to start position if provided
      if (widget.startPosition != null) {
        await _controller!.seekTo(widget.startPosition!);
      }

      // Start playback
      await _controller!.play();
      
      setState(() {
        _isPlaying = true;
        _totalDuration = _controller!.value.duration;
      });

      // Listen for position changes
      _controller!.addListener(_onPlayerUpdate);

      // Start periodic position saving every 30 seconds
      _positionSaveTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _saveCurrentPosition(),
      );

      // Auto-hide controls after 3 seconds
      _resetHideControlsTimer();
      
      debugPrint('✅ Player initialized successfully');
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout error: $e');
      setState(() => _errorMessage = 'El canal tardó demasiado en responder (8s).\n\nPrueba otro canal o intenta más tarde.');
    } catch (e) {
      debugPrint('❌ Error initializing player: $e');
      
      // Provide more helpful error messages
      String friendlyError = 'Error al reproducir';
      if (e.toString().contains('HTTP 500')) {
        friendlyError = 'El servidor del stream está teniendo problemas (Error 500)';
      } else if (e.toString().contains('HTTP 404')) {
        friendlyError = 'El contenido no está disponible (Error 404)';
      } else if (e.toString().contains('resource unavailable')) {
        friendlyError = 'El stream no está disponible en este momento';
      } else if (e.toString().contains('media format')) {
        friendlyError = 'Formato de video no compatible con iOS';
      }
      
      setState(() => _errorMessage = '$friendlyError\n\nPrueba otro canal.');
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

      // Check if video ended
      if (_controller!.value.position >= _controller!.value.duration) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _saveCurrentPosition() async {
    if (widget.meta == null || _currentUrl == null) return;
    if (_lastPosition.inSeconds < 10) return; // Don't save if <10s watched

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

  void _togglePlayPause() {
    if (_controller == null) return;
    
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
        _resetHideControlsTimer();
      }
    });
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
    _controller?.seekTo(position);
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
    _hideControlsTimer?.cancel();
    _positionSaveTimer?.cancel();
    _saveCurrentPosition();
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
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

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
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
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
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
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: widget.meta != null
                                ? Text(
                                    widget.meta!.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const SizedBox(),
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
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
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
                          // Progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(_lastPosition),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _lastPosition.inSeconds.toDouble(),
                                    max: (_totalDuration?.inSeconds ?? 1).toDouble(),
                                    onChanged: (value) {
                                      _seekTo(Duration(seconds: value.toInt()));
                                    },
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white30,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_totalDuration ?? Duration.zero),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
