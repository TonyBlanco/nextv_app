import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/xtream_models.dart';
import '../../core/services/xtream_api_service.dart';
import '../../core/models/watchlist_item.dart';
import '../../core/providers/watch_providers.dart';
import '../../core/providers/favorites_provider.dart';
import 'player_screen.dart';

class VODGridScreen extends ConsumerStatefulWidget {
  final List<VODCategory> categories;
  final XtreamAPIService api;
  final bool showFavoritesOnly;

  const VODGridScreen({
    super.key,
    required this.categories,
    required this.api,
    this.showFavoritesOnly = false,
  });

  @override
  ConsumerState<VODGridScreen> createState() => _VODGridScreenState();
}

class _VODGridScreenState extends ConsumerState<VODGridScreen> {
  String? _selectedCategoryId;
  List<VODStream> _vodStreams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.categoryId;
      _loadVODStreams(_selectedCategoryId!);
    }
  }

  Future<void> _loadVODStreams(String categoryId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final streams = await widget.api.getVODStreams(categoryId: categoryId);
      if (!mounted) return;
      setState(() {
        _vodStreams = streams;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading VOD streams: $e');
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
              Icons.movie_outlined,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'No hay categorías VOD disponibles',
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
                    Icon(Icons.movie_outlined, color: NextvColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Películas',
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
                          _loadVODStreams(category.categoryId);
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
        // Right content with movie grid
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
                          'Cargando películas...',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  )
                : _vodStreams.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_filter_outlined,
                              size: 64,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay películas en esta categoría',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 5 columns for desktop
                          childAspectRatio: 0.65, // Movie poster ratio (width/height)
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: widget.showFavoritesOnly
                            ? _vodStreams.where((s) => ref.read(favoritesServiceProvider).isFavorite(s.streamId)).length
                            : _vodStreams.length,
                        itemBuilder: (context, index) {
                          final favService = ref.read(favoritesServiceProvider);
                          final items = widget.showFavoritesOnly
                              ? _vodStreams.where((s) => favService.isFavorite(s.streamId)).toList()
                              : _vodStreams;

                          if (index >= items.length) return null;
                          final movie = items[index];

                          return _MovieCard(
                            movie: movie,
                            onTap: () => _showMovieDetail(movie),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  void _showMovieDetail(VODStream movie) {
    debugPrint('Selected movie: ${movie.name}');
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _VODDetailDialog(
        movie: movie,
        api: widget.api,
      ),
    );
  }
}

/// Netflix-style movie detail dialog
class _VODDetailDialog extends ConsumerStatefulWidget {
  final VODStream movie;
  final XtreamAPIService api;

  const _VODDetailDialog({required this.movie, required this.api});

  @override
  ConsumerState<_VODDetailDialog> createState() => _VODDetailDialogState();
}

class _VODDetailDialogState extends ConsumerState<_VODDetailDialog> {
  VODInfo? _vodInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovieInfo();
  }

  Future<void> _loadMovieInfo() async {
    try {
      final info = await widget.api.getVODInfo(widget.movie.streamId);
      if (mounted) {
        setState(() {
          _vodInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading VOD info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _playMovie() {
    Navigator.pop(context);

    // Check if we have a direct source (M3U or already resolved URL)
    String url;
    if (widget.movie.directSource.isNotEmpty) {
      url = widget.movie.directSource;
    } else {
      // Fallback to constructing URL via API (Xtream)
      url = widget.api.getVODStreamUrl(
        widget.movie.streamId,
        extension: widget.movie.containerExtension,
      );
    }

    debugPrint('Playing movie: ${widget.movie.name} -> $url');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          meta: PlayerMeta(
            id: 'vod_${widget.movie.streamId}',
            type: 'movie',
            title: widget.movie.name,
            imageUrl: widget.movie.streamIcon,
            streamId: widget.movie.streamId,
          ),
        ),
        settings: RouteSettings(arguments: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.85).clamp(360.0, 600.0);
    final dialogHeight = (screenSize.height * 0.85).clamp(400.0, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // ── Hero image with overlay ──
              _buildHeroSection(dialogWidth),
              // ── Content area ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: NextvColors.accent),
                      )
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(double width) {
    final info = _vodInfo?.info;
    // Use backdrop or cover or stream icon
    final heroUrl = (info?.coverBig.isNotEmpty == true ? info!.coverBig : null) ??
        (info?.backdropPath.isNotEmpty == true ? info!.backdropPath.first : null) ??
        widget.movie.streamIcon;

    return SizedBox(
      height: 220,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image
          if (heroUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: heroUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.white10),
              errorWidget: (_, __, ___) => Container(
                color: Colors.white10,
                child: const Icon(Icons.movie, color: Colors.white24, size: 64),
              ),
            )
          else
            Container(
              color: Colors.white10,
              child: const Icon(Icons.movie, color: Colors.white24, size: 64),
            ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xCC141414),
                  Color(0xFF141414),
                ],
                stops: [0.3, 0.8, 1.0],
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          // Title + Play button at bottom
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Play button
                    ElevatedButton.icon(
                      onPressed: _playMovie,
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text(
                        'Reproducir',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Watch Later button
                    _WatchLaterButton(
                      itemId: 'vod_${widget.movie.streamId}',
                      item: WatchlistItem(
                        id: 'vod_${widget.movie.streamId}',
                        type: 'movie',
                        title: widget.movie.name,
                        imageUrl: widget.movie.streamIcon,
                        playbackUrl: '',
                        addedAt: DateTime.now(),
                        streamId: widget.movie.streamId,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Favorite (Star/Heart) Button
                    Consumer(
                      builder: (context, ref, child) {
                        final isFav = ref.watch(isFavoriteProvider(widget.movie.streamId));
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white70,
                          ),
                          onPressed: () {
                            final favService = ref.read(favoritesServiceProvider);
                            final stream = LiveStream(
                              num: 0,
                              name: widget.movie.name,
                              streamType: 'movie',
                              streamId: widget.movie.streamId,
                              streamIcon: widget.movie.streamIcon,
                              epgChannelId: 0,
                              added: widget.movie.added,
                              categoryId: widget.movie.categoryId,
                              customSid: '',
                              tvArchive: 0,
                              directSource: widget.movie.directSource,
                              tvArchiveDuration: 0,
                            );
                            favService.toggleFavorite(stream);
                            ref.invalidate(favoritesProvider);
                          },
                          tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final info = _vodInfo?.info;

    if (_error != null && info == null) {
      // Show basic info from VODStream if API call failed
      return _buildBasicInfo();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metadata chips row ──
          _buildMetadataRow(info),
          const SizedBox(height: 12),
          // ── Synopsis ──
          if (info != null && (info.plot.isNotEmpty || info.description.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                info.plot.isNotEmpty ? info.plot : info.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),
          // ── Genre tags ──
          if (info != null && info.genre.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: info.genre.split(',').map((g) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      g.trim(),
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
          // ── Director ──
          if (info != null && info.director.isNotEmpty)
            _buildInfoRow('Director', info.director),
          // ── Cast / Actors ──
          if (info != null && (info.cast.isNotEmpty || info.actors.isNotEmpty))
            _buildInfoRow('Reparto', info.cast.isNotEmpty ? info.cast : info.actors),
          // ── Country ──
          if (info != null && info.country.isNotEmpty)
            _buildInfoRow('País', info.country),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(MovieInfo? info) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        // Rating
        if (widget.movie.rating > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 3),
              Text(
                '${(widget.movie.rating / 10).toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        // Year
        if (info != null && info.releasedate.isNotEmpty)
          Text(
            info.releasedate.length >= 4 ? info.releasedate.substring(0, 4) : info.releasedate,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        // Duration
        if (info != null && info.duration.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, color: Colors.white38, size: 14),
              const SizedBox(width: 3),
              Text(
                info.duration,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        // MPAA Rating badge
        if (info != null && info.mpaaRating.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              info.mpaaRating,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.movie.rating > 0)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.movie.rating / 10}/10',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'Información detallada no disponible',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final VODStream movie;
  final VoidCallback onTap;

  const _MovieCard({
    required this.movie,
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
              // Movie poster
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: movie.streamIcon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.streamIcon,
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
                                  Icons.movie_outlined,
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
                                Icons.movie_outlined,
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
              // Movie info
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movie.rating > 0) ...[
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
                            '${movie.rating / 10}',
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

/// Watch Later toggle button
class _WatchLaterButton extends ConsumerWidget {
  final String itemId;
  final WatchlistItem item;

  const _WatchLaterButton({required this.itemId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInList = ref.watch(isInWatchlistProvider(itemId));

    return OutlinedButton.icon(
      onPressed: () async {
        final service = ref.read(watchlistServiceProvider);
        await service.toggle(item);
        // Force provider refresh
        ref.invalidate(isInWatchlistProvider(itemId));
        ref.invalidate(watchlistProvider);
      },
      icon: Icon(
        isInList ? Icons.bookmark : Icons.bookmark_add_outlined,
        color: isInList ? Colors.amber : Colors.white70,
        size: 18,
      ),
      label: Text(
        isInList ? 'Saved' : 'Watch Later',
        style: TextStyle(
          color: isInList ? Colors.amber : Colors.white70,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isInList ? Colors.amber : Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
