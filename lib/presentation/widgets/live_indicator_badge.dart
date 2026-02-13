import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/providers/channel_providers.dart';

/// Animated badge showing live channel status
class LiveIndicatorBadge extends ConsumerWidget {
  final int streamId;
  final bool showLabel;
  final double size;

  const LiveIndicatorBadge({
    super.key,
    required this.streamId,
    this.showLabel = false,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = ref.watch(isChannelLiveProvider(streamId));

    if (!isLive) return const SizedBox.shrink();

    return _AnimatedLiveBadge(
      showLabel: showLabel,
      size: size,
    );
  }
}

class _AnimatedLiveBadge extends StatefulWidget {
  final bool showLabel;
  final double size;

  const _AnimatedLiveBadge({
    required this.showLabel,
    required this.size,
  });

  @override
  State<_AnimatedLiveBadge> createState() => _AnimatedLiveBadgeState();
}

class _AnimatedLiveBadgeState extends State<_AnimatedLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.showLabel
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: BoxDecoration(
                color: widget.showLabel ? Colors.red : null,
                borderRadius: widget.showLabel
                    ? BorderRadius.circular(12)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
