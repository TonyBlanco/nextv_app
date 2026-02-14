import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/xtream_models.dart';
import '../../core/models/catchup_program.dart';
import '../../core/providers/channel_providers.dart';
import '../../core/providers/catchup_providers.dart';
import '../../core/providers/active_playlist_provider.dart';
import 'player_screen.dart';

/// Mobile Catch-Up screen: shows channels with catch-up support,
/// then lets user browse past programs and play them.
class MobileCatchUpScreen extends ConsumerStatefulWidget {
  const MobileCatchUpScreen({super.key});

  @override
  ConsumerState<MobileCatchUpScreen> createState() =>
      _MobileCatchUpScreenState();
}

class _MobileCatchUpScreenState extends ConsumerState<MobileCatchUpScreen> {
  LiveStream? _selectedChannel;
  List<CatchupProgram>? _programs;
  bool _loadingPrograms = false;

  @override
  Widget build(BuildContext context) {
    if (_selectedChannel != null) {
      return _buildProgramsView();
    }
    return _buildChannelList();
  }

  // ========== CHANNEL LIST (channels with catch-up) ==========
  Widget _buildChannelList() {
    final streamsAsync = ref.watch(liveStreamsProvider);

    return streamsAsync.when(
      data: (streams) {
        final archiveChannels =
            streams.where((s) => s.tvArchive == 1).toList();
        if (archiveChannels.isEmpty) {
          return _buildEmpty('No hay canales con Catch Up disponible');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: archiveChannels.length,
          itemBuilder: (context, index) {
            final ch = archiveChannels[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: NextvColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _selectChannel(ch),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ch.streamIcon.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ch.streamIcon,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _iconPlaceholder(),
                                memCacheWidth: 100,
                              )
                            : _iconPlaceholder(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ch.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ch.tvArchiveDuration} días de archivo',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.white38, size: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
      error: (_, __) => _buildEmpty('Error cargando canales'),
    );
  }

  // ========== PROGRAMS VIEW (past programs for a channel) ==========
  Widget _buildProgramsView() {
    return Column(
      children: [
        // Back bar with channel name
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: NextvColors.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () => setState(() {
                  _selectedChannel = null;
                  _programs = null;
                }),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _selectedChannel!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        // Content
        Expanded(
          child: _loadingPrograms
              ? const Center(
                  child:
                      CircularProgressIndicator(color: NextvColors.accent))
              : _programs == null || _programs!.isEmpty
                  ? _buildEmpty('No hay programas disponibles para este canal')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _programs!.length,
                      itemBuilder: (context, index) {
                        return _buildProgramCard(_programs![index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProgramCard(CatchupProgram program) {
    final timeStr =
        '${_formatTime(program.startTime)} - ${_formatTime(program.endTime)}';
    final dateStr = _formatDate(program.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: NextvColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _playProgram(program),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Time badge
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: NextvColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(program.startTime),
                      style: const TextStyle(
                        color: NextvColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Program info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    if (program.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        program.description,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Play button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NextvColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: NextvColors.accent,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== ACTIONS ==========
  Future<void> _selectChannel(LiveStream channel) async {
    setState(() {
      _selectedChannel = channel;
      _loadingPrograms = true;
      _programs = null;
    });

    try {
      final catchupService = ref.read(catchupServiceProvider);
      final programs =
          await catchupService.getCatchupForChannel(channel.streamId);
      if (!mounted) return;
      setState(() {
        _programs = programs;
        _loadingPrograms = false;
      });
    } catch (e) {
      debugPrint('Error loading catch-up: $e');
      if (!mounted) return;
      setState(() {
        _programs = [];
        _loadingPrograms = false;
      });
    }
  }

  void _playProgram(CatchupProgram program) {
    final url = program.streamUrl;
    debugPrint('Playing catch-up: ${program.title} -> $url');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          meta: PlayerMeta(
            id: 'catchup_${program.id}',
            type: 'catchup',
            title: program.title,
            seriesName: program.channelName,
            imageUrl: program.thumbnailUrl ?? program.channelLogo,
            streamId: program.channelId,
          ),
        ),
        settings: RouteSettings(arguments: url),
      ),
    );
  }

  // ========== HELPERS ==========
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${dt.day}/${dt.month}';
  }

  Widget _iconPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: NextvColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.tv, color: Colors.white24, size: 28),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            msg,
            style: const TextStyle(color: Colors.white60, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
