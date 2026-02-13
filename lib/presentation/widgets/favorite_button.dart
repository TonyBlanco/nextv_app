import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/xtream_models.dart';
import '../../core/providers/favorites_provider.dart';

/// Animated favorite button with star icon
class FavoriteButton extends ConsumerStatefulWidget {
  final LiveStream stream;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    required this.stream,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_isAnimating) return;
    
    setState(() => _isAnimating = true);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Animate
    await _controller.forward();
    
    // Toggle favorite
    final service = ref.read(favoritesServiceProvider);
    await service.toggleFavorite(widget.stream);
    
    // Animate back
    await _controller.reverse();
    
    setState(() => _isAnimating = false);
    
    // Show snackbar
    if (mounted) {
      final isFavorite = service.isFavorite(widget.stream.streamId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? '⭐ Added to Favorites'
                : 'Removed from Favorites',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(isFavoriteProvider(widget.stream.streamId));

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          size: widget.size,
          color: isFavorite
              ? (widget.activeColor ?? Colors.amber)
              : (widget.inactiveColor ?? Colors.grey),
        ),
        onPressed: _toggleFavorite,
        tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: widget.size + 8,
          minHeight: widget.size + 8,
        ),
      ),
    );
  }
}

/// Compact favorite icon (no button, just indicator)
class FavoriteIcon extends ConsumerWidget {
  final int streamId;
  final double size;

  const FavoriteIcon({
    super.key,
    required this.streamId,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(streamId));

    if (!isFavorite) return const SizedBox.shrink();

    return Icon(
      Icons.star,
      size: size,
      color: Colors.amber,
    );
  }
}
