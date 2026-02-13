import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/xtream_models.dart';
import '../../core/services/epg_service.dart';

class EPGModal extends ConsumerStatefulWidget {
  final LiveStream stream;
  final String serverUrl;
  final String username;
  final String password;
  final String? xmltvUrl; // Fallback XMLTV URL for M3U providers

  const EPGModal({
    super.key,
    required this.stream,
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.xmltvUrl,
  });

  @override
  ConsumerState<EPGModal> createState() => _EPGModalState();
}

class _EPGModalState extends ConsumerState<EPGModal> {
  final EPGService _epgService = EPGService();
  List<EPGProgram> _programs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEPG();
  }

  Future<void> _loadEPG() async {
    setState(() => _isLoading = true);
    try {
      if (widget.serverUrl.isNotEmpty && widget.username.isNotEmpty) {
        // Xtream EPG
        await _epgService.fetchXtreamEPG(
          widget.serverUrl,
          widget.username,
          widget.password,
          widget.stream.streamId,
        );
      } else if (widget.xmltvUrl != null && widget.xmltvUrl!.isNotEmpty) {
        // XMLTV fallback
        await _epgService.fetchXMLTVEPG(widget.xmltvUrl!);
      }
      final programs = _epgService.getProgramsForChannel(widget.stream.epgChannelId.toString());
      setState(() {
        _programs = programs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading EPG: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NextvColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.stream.streamIcon.isNotEmpty
                      ? NetworkImage(widget.stream.streamIcon)
                      : null,
                  child: widget.stream.streamIcon.isEmpty
                      ? Text(widget.stream.name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.stream.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Program
            if (_epgService.getCurrentProgram(widget.stream.epgChannelId.toString()) != null)
              _buildCurrentProgram(),

            const SizedBox(height: 16),

            // Programs List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _programs.isEmpty
                      ? const Center(
                          child: Text(
                            'No EPG data available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _programs.length,
                          itemBuilder: (context, index) {
                            final program = _programs[index];
                            final isPast = program.stop.isBefore(DateTime.now());
                            final isCurrent = DateTime.now().isAfter(program.start) &&
                                             DateTime.now().isBefore(program.stop);

                            return Card(
                              color: isCurrent
                                  ? NextvColors.accent.withOpacity(0.2)
                                  : NextvColors.background,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  program.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${DateFormat('HH:mm').format(program.start)} - ${DateFormat('HH:mm').format(program.stop)}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    if (program.description.isNotEmpty)
                                      Text(
                                        program.description,
                                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: isPast && widget.stream.tvArchive == 1
                                    ? IconButton(
                                        icon: const Icon(Icons.replay, color: NextvColors.accent),
                                        onPressed: () => _playCatchup(program),
                                        tooltip: 'Watch Catch-up',
                                      )
                                    : null,
                                onTap: isPast && widget.stream.tvArchive == 1
                                    ? () => _playCatchup(program)
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentProgram() {
    final current = _epgService.getCurrentProgram(widget.stream.epgChannelId.toString());
    if (current == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NextvColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NextvColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOW PLAYING',
            style: TextStyle(
              color: NextvColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            current.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('HH:mm').format(current.start)} - ${DateFormat('HH:mm').format(current.stop)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (current.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              current.description,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _playCatchup(EPGProgram program) {
    final catchupUrl = _epgService.getCatchupUrl(
      widget.serverUrl,
      widget.username,
      widget.password,
      widget.stream.streamId,
      program.start,
      program.stop.difference(program.start).inHours + 1,
    );

    // Return the URL to play
    Navigator.of(context).pop(catchupUrl);
  }
}