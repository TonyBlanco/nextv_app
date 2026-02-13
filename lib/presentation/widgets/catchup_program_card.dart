import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/catchup_program.dart';
import '../../core/models/catchup_item.dart';

/// Program card for catch-up TV with progress overlay and action buttons
class CatchupProgramCard extends StatelessWidget {
  final CatchupProgram program;
  final CatchupItem? watchProgress;
  final bool isFavorite;
  final bool isInWatchLater;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onWatchLaterToggle;

  const CatchupProgramCard({
    super.key,
    required this.program,
    this.watchProgress,
    this.isFavorite = false,
    this.isInWatchLater = false,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onWatchLaterToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: NextvColors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail with progress overlay
              Expanded(
                flex: 3,
                child: _buildThumbnail(),
              ),
              // Program info
              Expanded(
                flex: 2,
                child: _buildInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          if (program.thumbnailUrl != null && program.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: program.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.white10,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NextvColors.accent,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // Progress bar overlay (if has progress)
          if (watchProgress != null && watchProgress!.hasStarted)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildProgressBar(),
            ),

          // Expiry badge (if expiring soon)
          if (program.isExpiringSoon && !program.isExpired)
            Positioned(
              top: 8,
              right: 8,
              child: _buildExpiryBadge(),
            ),

          // Play/Continue button
          Positioned(
            bottom: 8,
            right: 8,
            child: _buildPlayButton(),
          ),

          // Action buttons (favorite, watch later)
          Positioned(
            top: 8,
            left: 8,
            child: Row(
              children: [
                _buildActionButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                  onTap: onFavoriteToggle,
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: isInWatchLater ? Icons.watch_later : Icons.watch_later_outlined,
                  color: isInWatchLater ? NextvColors.accent : Colors.white,
                  onTap: onWatchLaterToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white10,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv,
            size: 48,
            color: Colors.white24,
          ),
          SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = watchProgress!.progressPercentage;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white24,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: const BoxDecoration(
                color: NextvColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryBadge() {
    final hours = program.timeRemaining.inHours;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            '${hours}h',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    final hasProgress = watchProgress != null && watchProgress!.hasStarted;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasProgress ? Icons.play_circle_filled : Icons.play_arrow,
            size: 16,
            color: Colors.black,
          ),
          const SizedBox(width: 4),
          Text(
            hasProgress ? 'Continuar' : 'Ver',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            program.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Channel + Time
          Row(
            children: [
              Expanded(
                child: Text(
                  program.channelName,
                  style: const TextStyle(
                    color: NextvColors.accent,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Time info
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 12,
                color: Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(program.startTime),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${program.duration.inMinutes} min',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
