import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/providers/channel_providers.dart';
import '../../core/models/xtream_models.dart';

/// Quick EPG preview widget showing current and next programs
class EPGQuickPreview extends ConsumerWidget {
  final String channelId;
  final bool compact;
  final bool showProgress;

  const EPGQuickPreview({
    super.key,
    required this.channelId,
    this.compact = true,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epgInfo = ref.watch(epgQuickInfoProvider(channelId));

    if (epgInfo == null || !epgInfo.hasData) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactView(epgInfo);
    } else {
      return _buildExpandedView(epgInfo);
    }
  }

  Widget _buildCompactView(EPGQuickInfo epgInfo) {
    final parts = <String>[];

    if (epgInfo.current != null) {
      parts.add('Now: ${epgInfo.current!.title}');
    }

    if (epgInfo.next != null) {
      parts.add('Next: ${epgInfo.next!.title}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          parts.join(' • '),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showProgress && epgInfo.progress != null) ...[
          const SizedBox(height: 4),
          _buildProgressBar(epgInfo.progress!),
        ],
      ],
    );
  }

  Widget _buildExpandedView(EPGQuickInfo epgInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (epgInfo.current != null) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: NextvColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  epgInfo.current!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(epgInfo.current!.start, epgInfo.current!.stop),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (showProgress && epgInfo.progress != null) ...[
            const SizedBox(height: 4),
            _buildProgressBar(epgInfo.progress!),
          ],
        ],
        if (epgInfo.next != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  epgInfo.next!.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(epgInfo.next!.start, epgInfo.next!.stop),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white12,
        valueColor: const AlwaysStoppedAnimation<Color>(NextvColors.accent),
        minHeight: 3,
      ),
    );
  }

  String _formatTime(DateTime start, DateTime stop) {
    final format = DateFormat('HH:mm');
    return '${format.format(start)} - ${format.format(stop)}';
  }
}
