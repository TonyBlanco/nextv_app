import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/xtream_models.dart';
import '../../core/services/xtream_api_service.dart';
import '../../core/providers/active_playlist_provider.dart';
import 'player_screen.dart';

/// Full-screen detail page for a series.
/// Shows cover, plot, season selector and episode list.
class MobileSeriesDetailScreen extends ConsumerStatefulWidget {
  final SeriesItem series;

  const MobileSeriesDetailScreen({super.key, required this.series});

  @override
  ConsumerState<MobileSeriesDetailScreen> createState() =>
      _MobileSeriesDetailScreenState();
}

class _MobileSeriesDetailScreenState
    extends ConsumerState<MobileSeriesDetailScreen> {
  SeriesInfo? _seriesInfo;
  bool _loading = true;
  String? _error;
  String? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _loadSeriesInfo();
  }

  Future<void> _loadSeriesInfo() async {
    try {
      final api = ref.read(xtreamAPIProvider);
      final info = await api.getSeriesInfo(widget.series.seriesId);
      if (!mounted) return;
      setState(() {
        _seriesInfo = info;
        _loading = false;
        if (info != null && info.seasons.isNotEmpty) {
          _selectedSeason = info.seasons.keys.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: NextvColors.accent))
          : _error != null
              ? _buildError()
              : _seriesInfo == null
                  ? _buildError()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: Text(
                _error ?? 'No se pudo cargar la serie',
                style: const TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.series.name,
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
    );
  }

  Widget _buildContent() {
    final info = _seriesInfo!;
    final seasons = info.seasons;

    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Cover + info header
                SliverToBoxAdapter(child: _buildHeader(info)),
                // Season chips
                if (seasons.length > 1)
                  SliverToBoxAdapter(child: _buildSeasonChips(seasons)),
                // Episodes list
                if (_selectedSeason != null &&
                    seasons.containsKey(_selectedSeason))
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final episode =
                            seasons[_selectedSeason]!.episodes[index];
                        return _buildEpisodeCard(episode, index);
                      },
                      childCount:
                          seasons[_selectedSeason]!.episodes.length,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SeriesInfo info) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.series.cover.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.series.cover,
                    width: 120,
                    height: 170,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
          const SizedBox(width: 16),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.series.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (widget.series.genre.isNotEmpty)
                  Text(
                    widget.series.genre,
                    style: const TextStyle(
                        color: NextvColors.accent, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.series.rating.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.series.rating,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                if (widget.series.releaseDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.series.releaseDate,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${_seriesInfo!.seasons.length} temporada${_seriesInfo!.seasons.length == 1 ? '' : 's'}',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 120,
      height: 170,
      color: NextvColors.surface,
      child: const Icon(Icons.tv, color: Colors.white24, size: 48),
    );
  }

  Widget _buildSeasonChips(Map<String, SeasonEpisodes> seasons) {
    final keys = seasons.keys.toList();
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final isSelected = _selectedSeason == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Temporada $key'),
              selected: isSelected,
              onSelected: (sel) {
                if (sel) setState(() => _selectedSeason = key);
              },
              selectedColor: NextvColors.accent,
              backgroundColor: NextvColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodeCard(Episode episode, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: NextvColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _playEpisode(episode, index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Episode number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NextvColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${episode.episodeNum > 0 ? episode.episodeNum : index + 1}',
                    style: const TextStyle(
                      color: NextvColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title.isNotEmpty
                          ? episode.title
                          : 'Episodio ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episode.plot.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.plot,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (episode.duration > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(episode.duration),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              // Play icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NextvColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: NextvColors.accent,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m} min';
  }

  void _playEpisode(Episode episode, int index) {
    final playlist = ref.read(activePlaylistProvider);
    if (playlist == null) return;

    final creds = playlist.toXtreamCredentials;
    if (creds == null) return;

    final episodeId = int.tryParse(episode.id) ?? 0;
    // Use the episode's container extension (MediaKit handles MKV, AVI, etc.)
    final ext = episode.containerExtension.isNotEmpty
        ? episode.containerExtension
        : 'mp4';
    final url =
        '${creds.serverUrl}/series/${creds.username}/${creds.password}/$episodeId.$ext';

    debugPrint('Playing episode: ${episode.title} -> $url');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          meta: PlayerMeta(
            id: 'series_${widget.series.seriesId}_ep_${episode.id}',
            type: 'episode',
            title:
                'S${_selectedSeason}E${index + 1}: ${episode.title.isNotEmpty ? episode.title : "Episodio ${index + 1}"}',
            seriesName: widget.series.name,
            imageUrl: widget.series.cover,
            streamId: episodeId,
          ),
        ),
        settings: RouteSettings(arguments: url),
      ),
    );
  }
}
