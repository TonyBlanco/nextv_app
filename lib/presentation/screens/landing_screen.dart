import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/provider_manager.dart';
import '../../core/services/xtream_api_service.dart';
import '../../core/providers/active_playlist_provider.dart';
import '../../core/providers/watch_providers.dart';
import '../../core/models/watch_history_item.dart';
import '../../core/models/watchlist_item.dart';
import 'nova_main_screen.dart';
import 'utilities_screen.dart';
import 'player_screen.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  int _liveCount = 0;
  int _vodCount = 0;
  int _seriesCount = 0;
  bool _countsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final api = ref.read(xtreamAPIProvider);
    final playlist = ref.read(activePlaylistProvider);
    
    // Ensure API is initialized
    if (!api.isInitialized && playlist != null) {
      final creds = playlist.toXtreamCredentials;
      if (creds != null) api.setCredentials(creds);
    }
    
    if (!api.isInitialized) return;
    
    try {
      final results = await Future.wait([
        api.getLiveCategories(),
        api.getVODCategories(),
        api.getSeriesCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _liveCount = results[0].length;
        _vodCount = results[1].length;
        _seriesCount = results[2].length;
        _countsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pm = ref.watch(providerManagerProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: NextvColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: NextvColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: NextvColors.accent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // NeXtv Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/nextv_home.png',
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NeXtv',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pm.activeProviderName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: NextvColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings icon
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    iconSize: 28,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UtilitiesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Continue Watching row
                    _buildContinueWatchingRow(),
                    // Watch Later row
                    _buildWatchLaterRow(),
                    // Category grid
                    screenWidth > 600
                        ? _buildGridLayout(context)
                        : _buildListLayout(context),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Premium Streaming Experience',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCategoryCard(
          context,
          title: 'LIVE TV',
          subtitle: _countsLoaded ? '$_liveCount categories' : null,
          icon: Icons.live_tv,
          onTap: () => _navigateToCategory(context, 0),
        ),
        _buildCategoryCard(
          context,
          title: 'MOVIES',
          subtitle: _countsLoaded ? '$_vodCount categories' : null,
          icon: Icons.movie,
          onTap: () => _navigateToCategory(context, 1),
        ),
        _buildCategoryCard(
          context,
          title: 'SERIES',
          subtitle: _countsLoaded ? '$_seriesCount categories' : null,
          icon: Icons.tv,
          onTap: () => _navigateToCategory(context, 2),
        ),
        _buildCategoryCard(
          context,
          title: 'CATCH UP',
          icon: Icons.history,
          onTap: () => _navigateToCategory(context, 3),
        ),
        _buildCategoryCard(
          context,
          title: 'FAVORITES',
          icon: Icons.favorite,
          onTap: () => _navigateToCategory(context, 0, favoritesOnly: true),
        ),
        _buildCategoryCard(
          context,
          title: 'UTILITIES',
          icon: Icons.settings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UtilitiesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return Column(
      children: [
        _buildLargeCard(
          context,
          title: 'LIVE TV',
          subtitle: _countsLoaded ? '$_liveCount categories' : 'Watch live channels',
          icon: Icons.live_tv,
          onTap: () => _navigateToCategory(context, 0),
        ),
        const SizedBox(height: 16),
        _buildLargeCard(
          context,
          title: 'MOVIES',
          subtitle: _countsLoaded ? '$_vodCount categories' : 'On-demand movies',
          icon: Icons.movie,
          onTap: () => _navigateToCategory(context, 1),
        ),
        const SizedBox(height: 16),
        _buildLargeCard(
          context,
          title: 'SERIES',
          subtitle: _countsLoaded ? '$_seriesCount categories' : 'TV shows & series',
          icon: Icons.tv,
          onTap: () => _navigateToCategory(context, 2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                context,
                title: 'CATCH UP',
                icon: Icons.history,
                onTap: () => _navigateToCategory(context, 3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallCard(
                context,
                title: 'FAVORITES',
                icon: Icons.favorite,
                onTap: () => _navigateToCategory(context, 0, favoritesOnly: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLargeCard(
          context,
          title: 'UTILITIES',
          subtitle: 'Settings & preferences',
          icon: Icons.settings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UtilitiesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Focus(
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return Container(
                decoration: BoxDecoration(
                  color: NextvColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: isFocused
                      ? Border.all(color: NextvColors.accent, width: 2)
                      : Border.all(color: Colors.white10),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: NextvColors.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                          )
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 48,
                            color: isFocused
                                ? NextvColors.accent
                                : Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isFocused
                                  ? NextvColors.accent
                                  : Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: NextvColors.accent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: NextvColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isFocused
                    ? Border.all(color: NextvColors.accent, width: 2)
                    : Border.all(color: Colors.white10),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: NextvColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 56,
                          color: isFocused
                              ? NextvColors.accent
                              : Colors.white,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isFocused
                                      ? NextvColors.accent
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isFocused
                              ? NextvColors.accent
                              : Colors.white60,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return Container(
              height: 140,
              decoration: BoxDecoration(
                color: NextvColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isFocused
                    ? Border.all(color: NextvColors.accent, width: 2)
                    : Border.all(color: Colors.white10),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: NextvColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: isFocused
                            ? NextvColors.accent
                            : Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isFocused
                              ? NextvColors.accent
                              : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== CONTINUE WATCHING ROW ====================
  Widget _buildContinueWatchingRow() {
    final history = ref.watch(watchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.play_circle_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Continue Watching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final service = ref.read(watchHistoryServiceProvider);
                await service.clearAll();
                ref.invalidate(watchHistoryProvider);
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildContinueWatchingCard(item);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildContinueWatchingCard(WatchHistoryItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              startPosition: item.position,
              meta: PlayerMeta(
                id: item.id,
                type: item.type,
                title: item.title,
                seriesName: item.seriesName,
                imageUrl: item.imageUrl,
                streamId: item.streamId,
              ),
            ),
            settings: RouteSettings(arguments: item.playbackUrl),
          ),
        );
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: NextvColors.surface,
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster with play overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: NextvColors.surface,
                            child: const Icon(Icons.movie, color: Colors.white24, size: 40),
                          ),
                        )
                      : Container(
                          color: NextvColors.surface,
                          child: const Icon(Icons.movie, color: Colors.white24, size: 40),
                        ),
                  // Play icon overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            LinearProgressIndicator(
              value: item.progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
              minHeight: 3,
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                item.seriesName ?? item.title,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WATCH LATER ROW ====================
  Widget _buildWatchLaterRow() {
    final watchlist = ref.watch(watchlistProvider);
    if (watchlist.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Watch Later',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${watchlist.length} items',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: watchlist.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = watchlist[index];
              return _buildWatchLaterCard(item);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWatchLaterCard(WatchlistItem item) {
    return GestureDetector(
      onTap: () {
        if (item.type == 'movie' && item.playbackUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                meta: PlayerMeta(
                  id: item.id,
                  type: 'movie',
                  title: item.title,
                  imageUrl: item.imageUrl,
                  streamId: item.streamId,
                ),
              ),
              settings: RouteSettings(arguments: item.playbackUrl),
            ),
          );
        } else {
          // For series, navigate to Movies/Series tab
          _navigateToCategory(context, item.type == 'series' ? 2 : 1);
        }
      },
      onLongPress: () async {
        // Long press to remove from watchlist
        final service = ref.read(watchlistServiceProvider);
        await service.remove(item.id);
        ref.invalidate(watchlistProvider);
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: NextvColors.surface,
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster with bookmark badge
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: NextvColors.surface,
                            child: const Icon(Icons.movie, color: Colors.white24, size: 40),
                          ),
                        )
                      : Container(
                          color: NextvColors.surface,
                          child: const Icon(Icons.movie, color: Colors.white24, size: 40),
                        ),
                  // Bookmark badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.bookmark, color: Colors.black, size: 14),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategory(
    BuildContext context,
    int tabIndex, {
    bool favoritesOnly = false,
  }) {
    // Set the active tab
    ref.read(selectedTabProvider.notifier).state = tabIndex;

    // Navigate to main screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovaMainScreen(),
      ),
    );
  }
}
