import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/models/xtream_models.dart';
import '../../core/providers/channel_providers.dart';
import '../../core/providers/category_providers.dart';
import '../../core/providers/active_playlist_provider.dart';
import '../../core/services/xtream_api_service.dart';
import '../widgets/nextv_logo.dart';
import '../widgets/favorite_button.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/watch_providers.dart';
import '../../core/models/watchlist_item.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import 'mobile_series_detail_screen.dart';
import 'mobile_catchup_screen.dart';

/// Netflix-style mobile interface - MOBILE ONLY
/// Clean, modern, no overflow errors, touch-optimized
class MobileNetflixScreen extends ConsumerStatefulWidget {
  const MobileNetflixScreen({super.key});

  @override
  ConsumerState<MobileNetflixScreen> createState() =>
      _MobileNetflixScreenState();
}

class _MobileNetflixScreenState extends ConsumerState<MobileNetflixScreen> {
  int _currentTab = 0;
  String? _selectedLiveCategory;
  String? _selectedVODCategory;
  String? _selectedSeriesCategory;

  // Watchlist ("Mi Lista") — special pseudo-category for movies & series
  static const String _miListaId = '__mi_lista__';

  // Search for Live TV channels (TiviMate-style)
  final TextEditingController _liveSearchController = TextEditingController();
  String _liveSearchQuery = '';
  bool _showLiveSearch = false;

  @override
  void dispose() {
    _liveSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ========== TOP BAR ==========
  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Row(
        children: [
          const NextvLogo(size: 24, showText: true, withGlow: false),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white70, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== TAB CONTENT ==========
  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildLiveTVTab();
      case 1:
        return _buildMoviesTab();
      case 2:
        return _buildSeriesTab();
      case 3:
        return _buildCatchUpTab();
      default:
        return _buildLiveTVTab();
    }
  }

  // ========== LIVE TV TAB ==========
  Widget _buildLiveTVTab() {
    final categoriesAsync = ref.watch(liveCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState('No live categories available');
        }

        // Auto-select Favorites as default (if user has any), otherwise first category
        if (_selectedLiveCategory == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final favCount = ref.read(favoritesCountProvider);
            setState(() {
              _selectedLiveCategory =
                  favCount > 0 ? '__favorites__' : categories.first.categoryId;
            });
          });
        }

        return Column(
          children: [
            // Search bar (TiviMate-style)
            _buildLiveSearchBar(),
            // If searching, show search results across all channels
            if (_liveSearchQuery.length >= 2)
              Expanded(child: _buildLiveSearchResults())
            else ...[
              // Category selector with ⭐ Favoritos as first option
              _buildLiveCategoryChips(categories),
              // Channels list (favorites or regular category)
              Expanded(
                child: _selectedLiveCategory == '__favorites__'
                    ? _buildFavoritesChannelsList()
                    : _buildLiveChannelsList(_selectedLiveCategory),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
      error: (error, stack) => _buildEmptyState('Error loading categories'),
    );
  }

  /// Search bar for filtering live channels by name
  Widget _buildLiveSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _liveSearchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar canales...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
          suffixIcon: _liveSearchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.clear, color: Colors.white54, size: 20),
                  onPressed: () {
                    _liveSearchController.clear();
                    setState(() => _liveSearchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: NextvColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() => _liveSearchQuery = value.trim());
        },
      ),
    );
  }

  /// Search results across ALL categories (lazy — only loads current category channels)
  Widget _buildLiveSearchResults() {
    if (_selectedLiveCategory == null) return const SizedBox();

    // Search within currently loaded category streams
    final streamsAsync =
        ref.watch(liveCategoryStreamsProvider(_selectedLiveCategory!));

    return streamsAsync.when(
      data: (streams) {
        final query = _liveSearchQuery.toLowerCase();
        final filtered =
            streams.where((s) => s.name.toLowerCase().contains(query)).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState('No channels match "$_liveSearchQuery"');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${filtered.length} resultado${filtered.length == 1 ? "" : "s"}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildChannelCard(filtered[index]),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
      error: (_, __) => _buildEmptyState('Error searching channels'),
    );
  }

  /// Category chips with ⭐ Favoritos as the first chip
  Widget _buildLiveCategoryChips(List<dynamic> categories) {
    final favCount = ref.watch(favoritesCountProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for Favorites
        itemBuilder: (context, index) {
          // First chip = Favoritos
          if (index == 0) {
            final isSelected = _selectedLiveCategory == '__favorites__';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.star,
                  size: 16,
                  color: isSelected ? Colors.black : Colors.amber,
                ),
                label: Text('Favoritos${favCount > 0 ? " ($favCount)" : ""}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedLiveCategory = '__favorites__');
                  }
                },
                selectedColor: Colors.amber,
                backgroundColor: NextvColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }

          // Regular categories (offset by 1)
          final category = categories[index - 1];
          final id = category.categoryId;
          final name = category.categoryName;
          final isSelected = _selectedLiveCategory == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedLiveCategory = id);
                }
              },
              selectedColor: NextvColors.accent,
              backgroundColor: NextvColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  /// Shows the user's favorite channels
  Widget _buildFavoritesChannelsList() {
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_border, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  'No tienes favoritos',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca la ⭐ en cualquier canal para agregarlo',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Convert FavoriteChannel to LiveStream for the channel card
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final fav = favorites[index];
            final stream = LiveStream(
              streamId: fav.streamId,
              name: fav.name,
              streamIcon: fav.icon,
              categoryId: fav.categoryId,
              streamType: 'live',
              epgChannelId: 0,
              customSid: '',
              tvArchive: 0,
              directSource: '',
              tvArchiveDuration: 0,
              added: 0,
              num: 0,
            );
            return _buildChannelCard(stream);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
      error: (_, __) => _buildEmptyState('Error loading favorites'),
    );
  }

  Widget _buildLiveChannelsList(String? categoryId) {
    if (categoryId == null) {
      return const SizedBox();
    }

    final streamsAsync = ref.watch(liveCategoryStreamsProvider(categoryId));

    return streamsAsync.when(
      data: (streams) {
        if (streams.isEmpty) {
          return _buildEmptyState('No channels in this category');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: streams.length,
          itemBuilder: (context, index) {
            return _buildChannelCard(streams[index]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
      error: (error, stack) => _buildEmptyState('Error loading channels'),
    );
  }

  Widget _buildChannelCard(LiveStream stream) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: NextvColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _playLiveChannel(stream),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Channel logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: stream.streamIcon.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: stream.streamIcon,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[800],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: NextvColors.accent,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholderIcon(),
                        memCacheWidth:
                            120, // Cache at 2x resolution for retina displays
                        maxWidthDiskCache: 120,
                      )
                    : _buildPlaceholderIcon(),
              ),
              const SizedBox(width: 16),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live TV',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Favorite button (⭐)
              FavoriteButton(
                stream: stream,
                size: 22,
                activeColor: Colors.amber,
                inactiveColor: Colors.white30,
              ),
              const SizedBox(width: 4),
              // Play button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: NextvColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: NextvColors.accent,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MOVIES TAB ==========
  Widget _buildMoviesTab() {
    final categoriesAsync = ref.watch(vodCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState('No movie categories available');
        }

        // Auto-select Mi Lista if it has items, otherwise first category
        if (_selectedVODCategory == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final watchlist = ref.read(watchlistProvider);
            final hasMovies = watchlist.any((w) => w.type == 'movie');
            setState(() {
              _selectedVODCategory =
                  hasMovies ? _miListaId : categories.first.categoryId;
            });
          });
        }

        return Column(
          children: [
            _buildMovieCategoryChips(categories),
            Expanded(
              child: _selectedVODCategory == _miListaId
                  ? _buildWatchlistGrid('movie')
                  : _buildMoviesGrid(_selectedVODCategory),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
      error: (error, stack) => _buildEmptyState('Error loading categories'),
    );
  }

  /// Category chips for Movies with "Mi Lista" as first chip
  Widget _buildMovieCategoryChips(List<dynamic> categories) {
    final watchlist = ref.watch(watchlistProvider);
    final movieCount = watchlist.where((w) => w.type == 'movie').length;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for Mi Lista
        itemBuilder: (context, index) {
          // First chip = Mi Lista
          if (index == 0) {
            final isSelected = _selectedVODCategory == _miListaId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.bookmark,
                  size: 16,
                  color: isSelected ? Colors.black : NextvColors.accent,
                ),
                label:
                    Text('Mi Lista${movieCount > 0 ? " ($movieCount)" : ""}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedVODCategory = _miListaId);
                  }
                },
                selectedColor: NextvColors.accent,
                backgroundColor: NextvColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }

          // Regular categories (offset by 1)
          final category = categories[index - 1];
          final id = category.categoryId;
          final name = category.categoryName;
          final isSelected = _selectedVODCategory == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedVODCategory = id);
                }
              },
              selectedColor: NextvColors.accent,
              backgroundColor: NextvColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoviesGrid(String? categoryId) {
    if (categoryId == null) return const SizedBox();

    final api = ref.watch(xtreamAPIProvider);

    return FutureBuilder<List<VODStream>>(
      future: api.getVODStreams(categoryId: categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: NextvColors.accent),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildEmptyState('Error loading movies');
        }

        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return _buildEmptyState('No movies in this category');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return _buildMovieCard(movies[index]);
          },
        );
      },
    );
  }

  Widget _buildMovieCard(VODStream movie) {
    final itemId = 'vod_${movie.streamId}';
    final isInList = ref.watch(isInWatchlistProvider(itemId));

    return Card(
      color: NextvColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _playMovie(movie),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: movie.streamIcon.isNotEmpty
                        ? Image.network(
                            movie.streamIcon,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: NextvColors.background,
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: NextvColors.background,
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    movie.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Bookmark button (top-right)
            Positioned(
              top: 4,
              right: 4,
              child: _buildWatchlistButton(
                isInList: isInList,
                onToggle: () => _toggleMovieWatchlist(movie),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SERIES TAB ==========
  Widget _buildSeriesTab() {
    final categoriesAsync = ref.watch(seriesCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState('No series categories available');
        }

        // Auto-select Mi Lista if it has items, otherwise first category
        if (_selectedSeriesCategory == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final watchlist = ref.read(watchlistProvider);
            final hasSeries = watchlist.any((w) => w.type == 'series');
            setState(() {
              _selectedSeriesCategory =
                  hasSeries ? _miListaId : categories.first.categoryId;
            });
          });
        }

        return Column(
          children: [
            _buildSeriesCategoryChips(categories),
            Expanded(
              child: _selectedSeriesCategory == _miListaId
                  ? _buildWatchlistGrid('series')
                  : _buildSeriesGrid(_selectedSeriesCategory),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: NextvColors.accent),
      ),
      error: (error, stack) =>
          _buildEmptyState('Error loading series categories'),
    );
  }

  /// Category chips for Series with "Mi Lista" as first chip
  Widget _buildSeriesCategoryChips(List<dynamic> categories) {
    final watchlist = ref.watch(watchlistProvider);
    final seriesCount = watchlist.where((w) => w.type == 'series').length;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for Mi Lista
        itemBuilder: (context, index) {
          // First chip = Mi Lista
          if (index == 0) {
            final isSelected = _selectedSeriesCategory == _miListaId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.bookmark,
                  size: 16,
                  color: isSelected ? Colors.black : NextvColors.accent,
                ),
                label:
                    Text('Mi Lista${seriesCount > 0 ? " ($seriesCount)" : ""}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSeriesCategory = _miListaId);
                  }
                },
                selectedColor: NextvColors.accent,
                backgroundColor: NextvColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }

          // Regular categories (offset by 1)
          final category = categories[index - 1];
          final id = category.categoryId;
          final name = category.categoryName;
          final isSelected = _selectedSeriesCategory == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedSeriesCategory = id);
                }
              },
              selectedColor: NextvColors.accent,
              backgroundColor: NextvColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeriesGrid(String? categoryId) {
    if (categoryId == null) return const SizedBox();

    final api = ref.watch(xtreamAPIProvider);

    return FutureBuilder<List<SeriesItem>>(
      future: api.getSeries(categoryId: categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: NextvColors.accent),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildEmptyState('Error loading series');
        }

        final seriesList = snapshot.data!;
        if (seriesList.isEmpty) {
          return _buildEmptyState('No series in this category');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: seriesList.length,
          itemBuilder: (context, index) {
            return _buildSeriesCard(seriesList[index]);
          },
        );
      },
    );
  }

  Widget _buildSeriesCard(SeriesItem series) {
    final itemId = 'series_${series.seriesId}';
    final isInList = ref.watch(isInWatchlistProvider(itemId));

    return Card(
      color: NextvColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MobileSeriesDetailScreen(series: series),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Series poster
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: series.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: series.cover,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: NextvColors.background,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NextvColors.accent,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: NextvColors.background,
                              child: const Icon(
                                Icons.tv,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                            memCacheWidth: 200,
                            maxWidthDiskCache: 200,
                          )
                        : Container(
                            color: NextvColors.background,
                            child: const Icon(
                              Icons.tv,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                // Title + rating
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
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
                        textAlign: TextAlign.center,
                      ),
                      if (series.rating.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              series.rating,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
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
            // Bookmark button (top-right)
            Positioned(
              top: 4,
              right: 4,
              child: _buildWatchlistButton(
                isInList: isInList,
                onToggle: () => _toggleSeriesWatchlist(series),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WATCHLIST HELPERS ==========

  /// Reusable bookmark button for movie/series cards
  Widget _buildWatchlistButton({
    required bool isInList,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isInList ? Icons.bookmark : Icons.bookmark_border,
          color: isInList ? NextvColors.accent : Colors.white70,
          size: 18,
        ),
      ),
    );
  }

  /// Toggle a movie in/out of the watchlist
  void _toggleMovieWatchlist(VODStream movie) {
    final service = ref.read(watchlistServiceProvider);
    final itemId = 'vod_${movie.streamId}';
    final item = WatchlistItem(
      id: itemId,
      type: 'movie',
      title: movie.name,
      imageUrl: movie.streamIcon,
      playbackUrl: '',
      addedAt: DateTime.now(),
      streamId: movie.streamId,
    );
    service.toggle(item);
    ref.invalidate(isInWatchlistProvider(itemId));
    ref.invalidate(watchlistProvider);
  }

  /// Toggle a series in/out of the watchlist
  void _toggleSeriesWatchlist(SeriesItem series) {
    final service = ref.read(watchlistServiceProvider);
    final itemId = 'series_${series.seriesId}';
    final item = WatchlistItem(
      id: itemId,
      type: 'series',
      title: series.name,
      imageUrl: series.cover,
      playbackUrl: '',
      addedAt: DateTime.now(),
      streamId: series.seriesId,
    );
    service.toggle(item);
    ref.invalidate(isInWatchlistProvider(itemId));
    ref.invalidate(watchlistProvider);
  }

  /// Grid showing watchlist items (filtered by type: 'movie' or 'series')
  Widget _buildWatchlistGrid(String type) {
    final watchlist = ref.watch(watchlistProvider);
    final items = watchlist.where((w) => w.type == type).toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Tu lista está vacía',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'movie'
                  ? 'Toca el 🔖 en cualquier película para guardarla'
                  : 'Toca el 🔖 en cualquier serie para guardarla',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildWatchlistCard(items[index]);
      },
    );
  }

  /// Card for a watchlist item (movie or series) — tappable + removable
  Widget _buildWatchlistCard(WatchlistItem item) {
    return Card(
      color: NextvColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (item.type == 'movie') {
            // Play movie directly
            _playWatchlistMovie(item);
          } else {
            // Navigate to series detail — need to create a minimal SeriesItem
            _openWatchlistSeries(item);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: NextvColors.background,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NextvColors.accent,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: NextvColors.background,
                              child: Icon(
                                item.type == 'movie' ? Icons.movie : Icons.tv,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                            memCacheWidth: 200,
                            maxWidthDiskCache: 200,
                          )
                        : Container(
                            color: NextvColors.background,
                            child: Icon(
                              item.type == 'movie' ? Icons.movie : Icons.tv,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Remove from watchlist button
            Positioned(
              top: 4,
              right: 4,
              child: _buildWatchlistButton(
                isInList: true,
                onToggle: () {
                  final service = ref.read(watchlistServiceProvider);
                  service.remove(item.id);
                  ref.invalidate(isInWatchlistProvider(item.id));
                  ref.invalidate(watchlistProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Play a movie from the watchlist
  void _playWatchlistMovie(WatchlistItem item) {
    final playlist = ref.read(activePlaylistProvider);
    if (playlist == null) return;

    final creds = playlist.toXtreamCredentials;
    if (creds == null) return;

    // Default to mp4 extension — the player will handle format fallback
    final url =
        '${creds.serverUrl}/movie/${creds.username}/${creds.password}/${item.streamId}.mp4';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          meta: PlayerMeta(
            id: item.streamId.toString(),
            type: 'movie',
            title: item.title,
            imageUrl: item.imageUrl,
            streamId: item.streamId,
          ),
        ),
        settings: RouteSettings(arguments: url),
      ),
    );
  }

  /// Open a series from the watchlist (create a minimal SeriesItem)
  void _openWatchlistSeries(WatchlistItem item) {
    final series = SeriesItem(
      num: 0,
      name: item.title,
      seriesId: item.streamId,
      cover: item.imageUrl,
      plot: '',
      cast: '',
      director: '',
      genre: '',
      releaseDate: '',
      lastModified: 0,
      rating: '',
      rating5based: '',
      backdropPath: const [],
      youtubeTrailer: '',
      episodeRunTime: 0,
      categoryId: '',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobileSeriesDetailScreen(series: series),
      ),
    );
  }

  // ========== CATCH UP TAB ==========
  Widget _buildCatchUpTab() {
    return const MobileCatchUpScreen();
  }

  // ========== CATEGORY CHIPS ==========
  // Accepts a List of dynamic objects which must have categoryName and categoryId properties
  Widget _buildCategoryChips({
    required List<dynamic> categories,
    required String? selectedId,
    required Function(String) onSelect,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          // Determine if we have categoryId/Name, handle both Live/VOD models
          final id = category.categoryId;
          final name = category.categoryName;

          final isSelected = selectedId == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelect(id);
                }
              },
              selectedColor: NextvColors.accent,
              backgroundColor: NextvColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  // ========== BOTTOM NAV ==========
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.live_tv, 'Live TV'),
              _buildNavItem(1, Icons.movie_outlined, 'Movies'),
              _buildNavItem(2, Icons.tv, 'Series'),
              _buildNavItem(3, Icons.history, 'Catch Up'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? NextvColors.accent : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? NextvColors.accent : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPERS ==========
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: NextvColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.tv, color: Colors.white24, size: 32),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tv_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== PLAYBACK ==========
  void _playLiveChannel(LiveStream stream) {
    final playlist = ref.read(activePlaylistProvider);
    if (playlist == null) return;

    final creds = playlist.toXtreamCredentials;
    if (creds == null) return;

    final url =
        '${creds.serverUrl}/live/${creds.username}/${creds.password}/${stream.streamId}.m3u8';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          meta: PlayerMeta(
            id: stream.streamId.toString(),
            type: 'live',
            title: stream.name,
            imageUrl: stream.streamIcon,
            streamId: stream.streamId, // Fixed: passed as int
          ),
        ),
        settings: RouteSettings(arguments: url),
      ),
    );
  }

  void _playMovie(VODStream movie) {
    final playlist = ref.read(activePlaylistProvider);
    if (playlist == null) return;

    final creds = playlist.toXtreamCredentials;
    if (creds == null) return;

    // Use the container extension as-is (mp4, mkv, etc.)
    // The PlayerScreen will try fallback formats if the first one fails
    final extension = movie.containerExtension;
    final url =
        '${creds.serverUrl}/movie/${creds.username}/${creds.password}/${movie.streamId}.$extension';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          meta: PlayerMeta(
            id: movie.streamId.toString(),
            type: 'movie',
            title: movie.name,
            imageUrl: movie.streamIcon,
            streamId: movie.streamId, // Fixed: passed as int
          ),
        ),
        settings: RouteSettings(arguments: url),
      ),
    );
  }
}
