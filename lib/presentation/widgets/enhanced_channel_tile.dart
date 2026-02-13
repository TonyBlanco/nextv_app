import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/xtream_models.dart';
import 'live_indicator_badge.dart';
import 'epg_quick_preview.dart';
import 'favorite_button.dart';
import 'epg_modal.dart';

/// Enhanced channel tile with live indicators and EPG preview
class EnhancedChannelTile extends ConsumerWidget {
  final LiveStream channel;
  final String serverUrl;
  final String username;
  final String password;
  final VoidCallback onTap;
  final bool showEPG;
  final bool showLiveIndicator;
  final bool compact;

  const EnhancedChannelTile({
    super.key,
    required this.channel,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.onTap,
    this.showEPG = true,
    this.showLiveIndicator = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      onLongPress: showEPG ? () => _showEPGModal(context) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: NextvColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Channel Icon with Live Indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: channel.streamIcon.isNotEmpty
                      ? Image.network(
                          channel.streamIcon,
                          width: compact ? 40 : 50,
                          height: compact ? 40 : 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderIcon();
                          },
                        )
                      : _buildPlaceholderIcon(),
                ),
                if (showLiveIndicator)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: LiveIndicatorBadge(
                      streamId: channel.streamId,
                      size: compact ? 6 : 8,
                    ),
                  ),
              ],
            ),
            SizedBox(width: compact ? 10 : 12),

            // Channel Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Channel Name
                  Text(
                    channel.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // EPG Preview
                  if (showEPG && channel.epgChannelId > 0) ...[
                    const SizedBox(height: 4),
                    EPGQuickPreview(
                      channelId: channel.epgChannelId.toString(),
                      compact: true,
                      showProgress: !compact,
                    ),
                  ],
                ],
              ),
            ),

            // Favorite Button
            FavoriteButton(stream: channel),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: compact ? 40 : 50,
      height: compact ? 40 : 50,
      decoration: BoxDecoration(
        color: NextvColors.accent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showEPGModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EPGModal(
        stream: channel,
        serverUrl: serverUrl,
        username: username,
        password: password,
      ),
    );
  }
}
