import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/providers/active_playlist_provider.dart';

/// iOS-optimized video player with native gestures and controls
class IOSPlayerScreen extends ConsumerStatefulWidget {
  final LiveStream stream;

  const IOSPlayerScreen({super.key, required this.stream});

  @override
  ConsumerState<IOSPlayerScreen> createState() => _IOSPlayerScreenState();
}

class _IOSPlayerScreenState extends ConsumerState<IOSPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final playlist = ref.read(activePlaylistProvider);
    if (playlist == null) {
      setState(() => _errorMessage = 'No active playlist');
      return;
    }

    // Detect stream type and build appropriate URLs
    final streamType = widget.stream.streamType;
    List<String> urlsToTry = [];
    
    if (streamType == 'movie') {
      // VOD/Movie - use containerExtension if available, otherwise try common formats
      final streamId = widget.stream.streamId;
      final ext = widget.stream.containerExtension;
      
      if (ext != null && ext.isNotEmpty) {
        // Try the exact extension first, then fallbacks
        urlsToTry = [
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.$ext',
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.mp4',
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.mkv',
        ];
      } else {
        // No extension provided, try common formats
        urlsToTry = [
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.mp4',
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.mkv',
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.m3u8',
          '${playlist.serverUrl}/movie/${playlist.username}/${playlist.password}/$streamId.ts',
        ];
      }
    } else {
      // Live TV
      urlsToTry = [
        '${playlist.serverUrl}/live/${playlist.username}/${playlist.password}/${widget.stream.streamId}.m3u8',
        '${playlist.serverUrl}/live/${playlist.username}/${playlist.password}/${widget.stream.streamId}.ts',
      ];
    }
    
    debugPrint('🎬 iOS Player: Stream type: $streamType');
    debugPrint('🎬 iOS Player: Container extension: ${widget.stream.containerExtension}');
    debugPrint('🎬 iOS Player: Trying ${urlsToTry.length} URL formats...');

    // Try each URL until one works
    for (int i = 0; i < urlsToTry.length; i++) {
      final url = urlsToTry[i];
      debugPrint('🔄 Attempt ${i + 1}/${urlsToTry.length}: $url');
      
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
          const Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Stream timeout'),
        );

        if (!mounted) return;

        // Check if video has valid dimensions (not audio-only)
        if (_controller!.value.size.width > 0 && _controller!.value.size.height > 0) {
          await _controller!.play();
          setState(() => _isPlaying = true);
          _resetHideControlsTimer();
          
          debugPrint('✅ iOS Player: Success with URL format ${i + 1}');
          return; // Success!
        } else {
          debugPrint('⚠️ Audio-only stream detected, trying next format...');
          throw Exception('Audio-only stream');
        }
      } on TimeoutException {
        debugPrint('⏱️ Timeout on attempt ${i + 1}');
        if (i == urlsToTry.length - 1) {
          setState(() => _errorMessage = 'El canal no responde');
        }
      } catch (e) {
        debugPrint('❌ Error on attempt ${i + 1}: $e');
        if (i == urlsToTry.length - 1) {
          // Last attempt failed
          if (e.toString().contains('404') || e.toString().contains('File Not Found')) {
            setState(() => _errorMessage = 'Contenido no disponible (404)');
          } else if (e.toString().contains('500')) {
            setState(() => _errorMessage = 'Error del servidor (500)');
          } else {
            setState(() => _errorMessage = 'No se pudo reproducir');
          }
        }
      }
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _resetHideControlsTimer();
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

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildLoadingScreen();
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
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
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          const Center(
            child: CupertinoActivityIndicator(
              radius: 20,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error al reproducir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 30),
            CupertinoButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.stream.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Center play/pause button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _togglePlayPause,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Bottom info
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.dot_radiowaves_left_right,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
