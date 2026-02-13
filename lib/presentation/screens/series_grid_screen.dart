import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/xtream_models.dart';
import '../../core/services/xtream_api_service.dart';
import '../../core/models/watchlist_item.dart';
import '../../core/providers/watch_providers.dart';
import 'player_screen.dart';

class SeriesGridScreen extends ConsumerStatefulWidget {
  final List<SeriesCategory> categories;
  final XtreamAPIService api;

  const SeriesGridScreen({
    super.key,
    required this.categories,
    required this.api,
  });

  @override
  ConsumerState<SeriesGridScreen> createState() => _SeriesGridScreenState();
}

class _SeriesGridScreenState extends ConsumerState<SeriesGridScreen> {
  String? _selectedCategoryId;
  List<SeriesItem> _seriesItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.categoryId;
      _loadSeries(_selectedCategoryId!);
    }
  }

  Future<void> _loadSeries(String categoryId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final series = await widget.api.getSeries(categoryId: categoryId);
      if (!mounted) return;
      setState(() {
        _seriesItems = series;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading series: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv_outlined,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'No hay categorías de series disponibles',
              style: TextStyle(color: Colors.white60),
            ),
            SizedBox(height: 8),
            Text(
              'Verifica tu proveedor',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Left sidebar with categories
        Container(
          width: 250,
          color: NextvColors.background,
          child: Column(
            children: [
              // Category header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: NextvColors.surface, width: 1),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tv, color: NextvColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Series',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Categories list
              Expanded(
                child: ListView.builder(
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    final isSelected = category.categoryId == _selectedCategoryId;
                    
                    return Material(
                      color: isSelected ? NextvColors.accent.withOpacity(0.2) : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = category.categoryId;
                          });
                          _loadSeries(category.categoryId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? NextvColors.accent : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            category.categoryName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Right content with series grid
        Expanded(
          child: Container(
            color: const Color(0xFF0F1419),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: NextvColors.accent,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando series...',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  )
                : _seriesItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tv_off_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay series en esta categoría',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 5 columns for desktop
                          childAspectRatio: 0.65, // Series poster ratio
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _seriesItems.length,
                        itemBuilder: (context, index) {
                          final series = _seriesItems[index];
                          return _SeriesCard(
                            series: series,
                            onTap: () => _showSeriesDetail(series),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  void _showSeriesDetail(SeriesItem series) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
    );

    try {
      // Load series info with seasons/episodes
      final seriesInfo = await widget.api.getSeriesInfo(series.seriesId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (seriesInfo == null) {
        _showErrorDialog('No se pudo cargar la información de la serie');
        return;
      }

      // Show series detail dialog
      showDialog(
        context: context,
        builder: (context) => _SeriesDetailDialog(
          series: series,
          seriesInfo: seriesInfo,
          api: widget.api,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NextvColors.surface,
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: NextvColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final SeriesItem series;
  final VoidCallback onTap;

  const _SeriesCard({
    required this.series,
    required this.onTap,
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
              // Series poster
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: series.cover.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: series.cover,
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
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white10,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tv_outlined,
                                  size: 48,
                                  color: Colors.white24,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Sin portada',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white10,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tv_outlined,
                                size: 48,
                                color: Colors.white24,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sin portada',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              // Series info
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (series.rating.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            series.rating,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesDetailDialog extends StatefulWidget {
  final SeriesItem series;
  final SeriesInfo seriesInfo;
  final XtreamAPIService api;

  const _SeriesDetailDialog({
    required this.series,
    required this.seriesInfo,
    required this.api,
  });

  @override
  State<_SeriesDetailDialog> createState() => _SeriesDetailDialogState();
}

class _SeriesDetailDialogState extends State<_SeriesDetailDialog> {
  String? _selectedSeasonNumber;

  @override
  void initState() {
    super.initState();
    // Select first season by default
    if (widget.seriesInfo.seasons.isNotEmpty) {
      _selectedSeasonNumber = widget.seriesInfo.seasons.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasons = widget.seriesInfo.seasons.entries.toList()
      ..sort((a, b) => int.tryParse(a.key)?.compareTo(int.tryParse(b.key) ?? 0) ?? 0);

    return Dialog(
      backgroundColor: NextvColors.surface,
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with series info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Series cover
                if (widget.series.cover.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.series.cover,
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 180,
                        color: Colors.white10,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: NextvColors.accent,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 180,
                        color: Colors.white10,
                        child: const Icon(Icons.tv, color: Colors.white24),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                // Series details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.series.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.series.rating.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.series.rating,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (widget.series.genre.isNotEmpty)
                        Text(
                          widget.series.genre,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (widget.series.plot.isNotEmpty)
                        Text(
                          widget.series.plot,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF2D3E50)),
            const SizedBox(height: 16),
            // Season selector
            Row(
              children: [
                const Text(
                  'Temporadas:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: seasons.map((entry) {
                        final seasonNum = entry.key;
                        final isSelected = seasonNum == _selectedSeasonNumber;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('Temporada $seasonNum'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSeasonNumber = seasonNum;
                                });
                              }
                            },
                            backgroundColor: const Color(0xFF2D3E50),
                            selectedColor: NextvColors.accent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Episodes list
            Expanded(
              child: _selectedSeasonNumber == null
                  ? const Center(
                      child: Text(
                        'Selecciona una temporada',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.seriesInfo.seasons[_selectedSeasonNumber]!.episodes.length,
                      itemBuilder: (context, index) {
                        final episode = widget.seriesInfo.seasons[_selectedSeasonNumber]!.episodes[index];
                        return _EpisodeItem(
                          episode: episode,
                          episodeNumber: index + 1,
                          onTap: () {
                            // Construct the episode stream URL
                            final episodeId = int.tryParse(episode.id) ?? 0;
                            final url = widget.api.getSeriesStreamUrl(
                              episodeId,
                              extension: episode.containerExtension,
                            );
                            
                            debugPrint('Playing episode: ${episode.title} -> $url');
                            Navigator.pop(context);
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(
                                  meta: PlayerMeta(
                                    id: 'series_${widget.series.seriesId}_ep_${episode.id}',
                                    type: 'episode',
                                    title: 'S${_selectedSeasonNumber}E${index + 1}: ${episode.title}',
                                    seriesName: widget.seriesInfo.info.name,
                                    imageUrl: widget.seriesInfo.info.cover,
                                    streamId: int.tryParse(episode.id) ?? 0,
                                  ),
                                ),
                                settings: RouteSettings(arguments: url),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeItem extends StatelessWidget {
  final Episode episode;
  final int episodeNumber;
  final VoidCallback onTap;

  const _EpisodeItem({
    required this.episode,
    required this.episodeNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF2D3E50), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Episode number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NextvColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$episodeNumber',
                    style: const TextStyle(
                      color: NextvColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Episode thumbnail (if available)
              if (episode.movieImage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: episode.movieImage,
                    width: 100,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 100,
                      height: 60,
                      color: Colors.white10,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      height: 60,
                      color: Colors.white10,
                      child: const Icon(Icons.tv, color: Colors.white24, size: 24),
                    ),
                  ),
                ),
              if (episode.movieImage.isNotEmpty) const SizedBox(width: 16),
              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title.isNotEmpty ? episode.title : 'Episodio $episodeNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (episode.plot.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.plot,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (episode.duration > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${episode.duration} min',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play icon
              const Icon(
                Icons.play_circle_outline,
                color: NextvColors.accent,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
