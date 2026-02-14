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

        // Auto-select first category
        if (_selectedVODCategory == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedVODCategory = categories.first.categoryId;
            });
          });
        }

        return Column(
          children: [
            _buildCategoryChips(
              categories: categories,
              selectedId: _selectedVODCategory,
              onSelect: (id) => setState(() => _selectedVODCategory = id),
            ),
            Expanded(
              child: _buildMoviesGrid(_selectedVODCategory),
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
    return Card(
      color: NextvColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _playMovie(movie),
        borderRadius: BorderRadius.circular(12),
        child: Column(
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

        // Auto-select first category
        if (_selectedSeriesCategory == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedSeriesCategory = categories.first.categoryId;
            });
          });
        }

        return Column(
          children: [
            _buildCategoryChips(
              categories: categories,
              selectedId: _selectedSeriesCategory,
              onSelect: (id) => setState(() => _selectedSeriesCategory = id),
            ),
            Expanded(
              child: _buildSeriesGrid(_selectedSeriesCategory),
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
        child: Column(
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
                        const Icon(Icons.star, color: Colors.amber, size: 12),
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
