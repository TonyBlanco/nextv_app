import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/nextv_colors.dart';
import '../../../core/models/xtream_models.dart';

/// Shared mobile channel card widget
/// Used by both iOS and Android implementations
class MobileChannelCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback onTap;

  const MobileChannelCard({
    super.key,
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NextvColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel logo - reduced height
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: stream.streamIcon.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: stream.streamIcon,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: NextvColors.background,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: NextvColors.accent,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                        memCacheWidth: 200,
                        maxWidthDiskCache: 200,
                      )
                    : _buildPlaceholder(),
              ),
            ),
            
            // Channel info - much more compact
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stream.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: NextvColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: NextvColors.background,
      child: const Center(
        child: Icon(
          Icons.tv,
          color: NextvColors.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}
