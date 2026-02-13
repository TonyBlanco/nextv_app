import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/models/xtream_models.dart';
import '../../core/services/epg_service.dart';

/// Widget para badges contextuales PRO (LIVE, CATCH-UP, REC, HD/4K)
class ProBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final double fontSize;

  const ProBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para indicadores de estado con animación
class StatusIndicator extends StatelessWidget {
  final String text;
  final Color color;
  final bool isActive;
  final IconData? icon;

  const StatusIndicator({
    super.key,
    required this.text,
    required this.color,
    this.isActive = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para feedback visual de cambios (calidad, player)
class ChangeFeedback extends StatefulWidget {
  final String message;
  final Color color;
  final Duration duration;

  const ChangeFeedback({
    super.key,
    required this.message,
    required this.color,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ChangeFeedback> createState() => _ChangeFeedbackState();
}

class _ChangeFeedbackState extends State<ChangeFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    // Auto-hide after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - _animation.value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium EPG Overlay - Muestra información del programa actual y siguiente
class EPGOverlay extends ConsumerStatefulWidget {
  final LiveStream stream;
  final String serverUrl;
  final String username;
  final String password;
  final bool isVisible;
  final VoidCallback onDismiss;

  const EPGOverlay({
    super.key,
    required this.stream,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.isVisible,
    required this.onDismiss,
  });

  @override
  ConsumerState<EPGOverlay> createState() => _EPGOverlayState();
}

class _EPGOverlayState extends ConsumerState<EPGOverlay>
    with SingleTickerProviderStateMixin {
  final EPGService _epgService = EPGService();
  List<EPGProgram> _programs = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadEPG();
  }

  @override
  void didUpdateWidget(EPGOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
        _startAutoHideTimer();
      } else {
        _animationController.reverse();
        _autoHideTimer?.cancel();
      }
    }
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  Future<void> _loadEPG() async {
    try {
      await _epgService.fetchXtreamEPG(
        widget.serverUrl,
        widget.username,
        widget.password,
        widget.stream.streamId,
      );
      final programs = _epgService.getProgramsForChannel(widget.stream.epgChannelId.toString());
      if (mounted) {
        setState(() {
          _programs = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Temporarily disabled - EPGProgram model not implemented
  // EPGProgram? get _currentProgram {
  //   final now = DateTime.now();
  //   return _programs.where((program) {
  //     final startTime = DateTime.fromMillisecondsSinceEpoch(program.startTimestamp * 1000);
  //     final endTime = DateTime.fromMillisecondsSinceEpoch(program.endTimestamp * 1000);
  //     return now.isAfter(startTime) && now.isBefore(endTime);
  //   }).firstOrNull;
  // }

  EPGProgram? get _currentProgram => null;

  // Temporarily disabled - EPGProgram model not implemented
  // EPGProgram? get _nextProgram {
  //   final now = DateTime.now();
  //   final upcomingPrograms = _programs.where((program) {
  //     final startTime = DateTime.fromMillisecondsSinceEpoch(program.startTimestamp * 1000);
  //     return startTime.isAfter(now);
  //   }).toList();
  //   upcomingPrograms.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));
  //   return upcomingPrograms.firstOrNull;
  // }

  EPGProgram? get _nextProgram => null;

  // Temporarily disabled - EPGProgram model not implemented
  // double get _currentProgramProgress {
  //   final current = _currentProgram;
  //   if (current == null) return 0.0;
  //   final now = DateTime.now().millisecondsSinceEpoch / 1000;
  //   final start = current.startTimestamp;
  //   final end = current.endTimestamp;
  //   final total = end - start;
  //   final elapsed = now - start;
  //   return (elapsed / total).clamp(0.0, 1.0);
  // }

  double get _currentProgramProgress => 0.0;

  @override
  void dispose() {
    _animationController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && !_animationController.isAnimating) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NextvColors.accent.withOpacity(0.3), width: 1),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(NextvColors.accent),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with channel info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: widget.stream.streamIcon.isNotEmpty
                                      ? NetworkImage(widget.stream.streamIcon)
                                      : null,
                                  child: widget.stream.streamIcon.isEmpty
                                      ? Text(
                                          widget.stream.name[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 18),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.stream.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'EPG Information',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onDismiss,
                                  icon: const Icon(Icons.close, color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Current Program
                            if (_currentProgram != null) ...[
                              const Text(
                                'NOW PLAYING',
                                style: TextStyle(
                                  color: NextvColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: NextvColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: NextvColors.accent.withOpacity(0.3), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentProgram!.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_currentProgram!.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentProgram!.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    // Temporarily disabled - EPGProgram model not implemented
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       '${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_currentProgram!.startTimestamp * 1000))} - ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_currentProgram!.endTimestamp * 1000))}',
                                    //       style: TextStyle(
                                    //         color: Colors.white.withOpacity(0.6),
                                    //         fontSize: 11,
                                    //       ),
                                    //     ),
                                    //     const Spacer(),
                                    //     Text(
                                    //       '${(_currentProgramProgress * 100).round()}%',
                                    //       style: const TextStyle(
                                    //         color: NextvColors.accent,
                                    //         fontSize: 11,
                                    //         fontWeight: FontWeight.bold,
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    // const SizedBox(height: 6),
                                    // LinearProgressIndicator(
                                    //   value: _currentProgramProgress,
                                    //   backgroundColor: Colors.white.withOpacity(0.2),
                                    //   valueColor: const AlwaysStoppedAnimation<Color>(NextvColors.accent),
                                    // ),
                                  ],
                                ),
                              ),
                            ],

                            // Next Program
                            if (_nextProgram != null) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'COMING UP NEXT',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nextProgram!.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_nextProgram!.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _nextProgram!.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    // Temporarily disabled - EPGProgram model not implemented
                                    // Text(
                                    //   'Starts at ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(_nextProgram!.startTimestamp * 1000))}',
                                    //   style: TextStyle(
                                    //     color: Colors.white.withOpacity(0.6),
                                    //     fontSize: 11,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],

                            // No EPG data message
                            if (_currentProgram == null && _nextProgram == null && !_isLoading) ...[
                              const SizedBox(height: 20),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No EPG data available',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Professional Player Controls - Controles avanzados del reproductor
class PlayerControls extends StatefulWidget {
  final bool isPlaying;
  final bool isFullscreen;
  final double volume;
  final String currentQuality;
  final Duration? position;
  final Duration? duration;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<String> onQualityChanged;
  final VoidCallback onFullscreenToggle;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onRewind;
  final VoidCallback? onFastForward;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isFullscreen,
    required this.volume,
    required this.currentQuality,
    this.position,
    this.duration,
    required this.onPlayPause,
    required this.onVolumeChanged,
    required this.onQualityChanged,
    required this.onFullscreenToggle,
    this.onSeek,
    this.onRewind,
    this.onFastForward,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  Timer? _hideTimer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isVisible = false);
        _animationController.reverse();
      }
    });
  }

  void _showControls() {
    setState(() => _isVisible = true);
    _animationController.forward();
    _startHideTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showControls,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Progress bar (top of controls)
                  if (widget.duration != null && widget.duration!.inSeconds > 0)
                    Builder(builder: (context) {
                      final maxVal = widget.duration!.inSeconds.toDouble().clamp(1.0, double.infinity);
                      final curVal = (widget.position?.inSeconds.toDouble() ?? 0.0).clamp(0.0, maxVal);
                      return Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(widget.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  activeTrackColor: NextvColors.accent,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  thumbColor: NextvColors.accent,
                                  overlayColor: NextvColors.accent.withOpacity(0.3),
                                ),
                                child: Slider(
                                  value: curVal,
                                  min: 0.0,
                                  max: maxVal,
                                  onChanged: (value) {
                                    widget.onSeek?.call(Duration(seconds: value.toInt()));
                                    _showControls();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(widget.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Main controls
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rewind 10s
                        IconButton(
                          onPressed: widget.onRewind,
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                          tooltip: 'Rewind 10 seconds',
                        ),
                        const SizedBox(width: 16),

                        // Play/Pause
                        Container(
                          decoration: BoxDecoration(
                            color: NextvColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: NextvColors.accent, width: 2),
                          ),
                          child: IconButton(
                            onPressed: widget.onPlayPause,
                            icon: Icon(
                              widget.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                            tooltip: widget.isPlaying ? 'Pause' : 'Play',
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Fast forward 10s
                        IconButton(
                          onPressed: widget.onFastForward,
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                          tooltip: 'Forward 10 seconds',
                        ),
                      ],
                    ),
                  ),

                  // Bottom controls bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        // LIVE badge (in fullscreen, shown here instead of overlay)
                        if (widget.isFullscreen)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.live_tv, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        // Volume control
                        Row(
                          children: [
                            Icon(
                              widget.volume == 0 ? Icons.volume_off :
                              widget.volume < 0.5 ? Icons.volume_down : Icons.volume_up,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.3),
                                ),
                                child: Slider(
                                  value: widget.volume,
                                  onChanged: (value) {
                                    widget.onVolumeChanged(value);
                                    _showControls();
                                  },
                                  min: 0.0,
                                  max: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(widget.volume * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Quality selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (quality) {
                              widget.onQualityChanged(quality);
                              _showControls();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'auto', child: Text('Auto')),
                              const PopupMenuItem(value: '4k', child: Text('4K')),
                              const PopupMenuItem(value: 'hd', child: Text('HD')),
                              const PopupMenuItem(value: 'sd', child: Text('SD')),
                            ],
                            child: Row(
                              children: [
                                Text(
                                  widget.currentQuality.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Fullscreen toggle
                        IconButton(
                          onPressed: widget.onFullscreenToggle,
                          icon: Icon(
                            widget.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: widget.isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Trust Signals - Señales de confianza y seguridad
/// Badge de confianza general con iconos y colores contextuales
class TrustBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final TrustLevel level;
  final String? tooltip;

  const TrustBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.level,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForLevel(level);
    final backgroundColor = _getBackgroundColorForLevel(level);

    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(TrustLevel level) {
    switch (level) {
      case TrustLevel.verified:
        return Colors.green;
      case TrustLevel.secure:
        return NextvColors.accent;
      case TrustLevel.warning:
        return Colors.orange;
      case TrustLevel.danger:
        return Colors.red;
      case TrustLevel.unknown:
        return Colors.grey;
    }
  }

  Color _getBackgroundColorForLevel(TrustLevel level) {
    return _getColorForLevel(level).withOpacity(0.1);
  }
}

enum TrustLevel {
  verified, // Verde - Verificado y confiable
  secure,   // Azul - Seguro pero no verificado
  warning,  // Naranja - Requiere atención
  danger,   // Rojo - Peligroso o no confiable
  unknown,  // Gris - Estado desconocido
}

/// Indicador de seguridad con animación y estado dinámico
class SecurityIndicator extends StatefulWidget {
  final bool isSecure;
  final String secureText;
  final String insecureText;
  final VoidCallback? onTap;

  const SecurityIndicator({
    super.key,
    required this.isSecure,
    required this.secureText,
    required this.insecureText,
    this.onTap,
  });

  @override
  State<SecurityIndicator> createState() => _SecurityIndicatorState();
}

class _SecurityIndicatorState extends State<SecurityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isSecure) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SecurityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSecure != oldWidget.isSecure) {
      if (widget.isSecure) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSecure ? Colors.green : Colors.red;
    final icon = widget.isSecure ? Icons.verified_user : Icons.warning;
    final text = widget.isSecure ? widget.secureText : widget.insecureText;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSecure ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Badge de estado de conexión con indicadores visuales
class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final String? customText;
  final bool showIcon;

  const ConnectionStatusBadge({
    super.key,
    required this.status,
    this.customText,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfigForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: config.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(config.icon, size: 14, color: config.iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            customText ?? config.text,
            style: TextStyle(
              color: config.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _ConnectionConfig _getConfigForStatus(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.secure:
        return _ConnectionConfig(
          text: 'SECURE',
          icon: Icons.lock,
          iconColor: Colors.green,
          textColor: Colors.green,
          backgroundColor: Colors.green.withOpacity(0.1),
          borderColor: Colors.green.withOpacity(0.4),
          shadowColor: Colors.green.withOpacity(0.2),
        );
      case ConnectionStatus.vpn:
        return _ConnectionConfig(
          text: 'VPN',
          icon: Icons.vpn_lock,
          iconColor: NextvColors.accent,
          textColor: NextvColors.accent,
          backgroundColor: NextvColors.accent.withOpacity(0.1),
          borderColor: NextvColors.accent.withOpacity(0.4),
          shadowColor: NextvColors.accent.withOpacity(0.2),
        );
      case ConnectionStatus.unsecured:
        return _ConnectionConfig(
          text: 'UNSECURE',
          icon: Icons.lock_open,
          iconColor: Colors.red,
          textColor: Colors.red,
          backgroundColor: Colors.red.withOpacity(0.1),
          borderColor: Colors.red.withOpacity(0.4),
          shadowColor: Colors.red.withOpacity(0.2),
        );
      case ConnectionStatus.checking:
        return _ConnectionConfig(
          text: 'CHECKING',
          icon: Icons.hourglass_empty,
          iconColor: Colors.orange,
          textColor: Colors.orange,
          backgroundColor: Colors.orange.withOpacity(0.1),
          borderColor: Colors.orange.withOpacity(0.4),
          shadowColor: Colors.orange.withOpacity(0.2),
        );
    }
  }
}

enum ConnectionStatus {
  secure,     // Conexión segura (HTTPS/SSL)
  vpn,        // Conexión VPN activa
  unsecured,  // Conexión no segura
  checking,   // Verificando estado
}

class _ConnectionConfig {
  final String text;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  _ConnectionConfig({
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
  });
}

/// Badge de verificación con checkmarks animados
class VerificationBadge extends StatefulWidget {
  final bool isVerified;
  final String verifiedText;
  final String unverifiedText;
  final Duration animationDuration;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    required this.verifiedText,
    required this.unverifiedText,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<VerificationBadge> createState() => _VerificationBadgeState();
}

class _VerificationBadgeState extends State<VerificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    if (widget.isVerified) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(VerificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVerified != oldWidget.isVerified) {
      if (widget.isVerified) {
        _animationController.forward(from: 0.0);
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isVerified
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isVerified
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _checkAnimation.value,
                child: Icon(
                  widget.isVerified ? Icons.verified : Icons.help_outline,
                  size: 14,
                  color: widget.isVerified ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            widget.isVerified ? widget.verifiedText : widget.unverifiedText,
            style: TextStyle(
              color: widget.isVerified ? Colors.green : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}