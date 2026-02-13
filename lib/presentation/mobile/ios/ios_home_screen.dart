import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/nextv_colors.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/providers/channel_providers.dart';
import '../../../core/providers/category_providers.dart';
import '../shared/mobile_channel_card.dart';
import '../shared/mobile_search_bar.dart';
import 'ios_player_screen.dart';

/// iOS-optimized home screen with native iOS design patterns
/// - Cupertino navigation
/// - iOS-style scrolling physics
/// - Native iOS gestures
class IOSHomeScreen extends ConsumerStatefulWidget {
  const IOSHomeScreen({super.key});

  @override
  ConsumerState<IOSHomeScreen> createState() => _IOSHomeScreenState();
}

class _IOSHomeScreenState extends ConsumerState<IOSHomeScreen> {
  String _selectedCategoryId = '';
  final ScrollController _scrollController = ScrollController();
  final List<LiveStream> _loadedChannels = [];
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _channelsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreChannels();
    }
  }

  Future<void> _loadMoreChannels() async {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    // Simulate pagination - in real app, fetch from API
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(liveCategoriesProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: NextvColors.background.withOpacity(0.9),
        border: null,
        leading: const Text(
          'NeXtv',
          style: TextStyle(
            color: NextvColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: Open search
              },
              child: const Icon(CupertinoIcons.search, color: Colors.white),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: Open settings
              },
              child: const Icon(CupertinoIcons.settings, color: Colors.white),
            ),
          ],
        ),
      ),
      backgroundColor: NextvColors.background,
      child: SafeArea(
        child: categoriesAsync.when(
          data: (categories) => _buildContent(categories),
          loading: () => const Center(
            child: CupertinoActivityIndicator(radius: 20),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading categories: $error',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<LiveCategory> categories) {
    final streamsAsync = _selectedCategoryId.isEmpty
        ? ref.watch(liveStreamsProvider)
        : ref.watch(liveCategoryStreamsProvider(_selectedCategoryId));

    return Column(
      children: [
        // Category chips
        _buildCategoryChips(categories),
        
        // Channel grid
        Expanded(
          child: streamsAsync.when(
            data: (streams) => _buildChannelGrid(streams),
            loading: () => const Center(
              child: CupertinoActivityIndicator(radius: 20),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading channels',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(List<LiveCategory> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategoryId == category.categoryId;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isSelected ? NextvColors.accent : NextvColors.surface,
              borderRadius: BorderRadius.circular(20),
              onPressed: () {
                setState(() {
                  _selectedCategoryId = isSelected ? '' : category.categoryId;
                  _loadedChannels.clear();
                  _currentPage = 0;
                });
              },
              child: Text(
                category.categoryName,
                style: TextStyle(
                  color: isSelected ? Colors.white : NextvColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelGrid(List<LiveStream> allStreams) {
    // Paginate channels
    final displayedStreams = allStreams.take((_currentPage + 1) * _channelsPerPage).toList();
    
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(), // iOS-style bounce
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(liveStreamsProvider);
            setState(() {
              _loadedChannels.clear();
              _currentPage = 0;
            });
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= displayedStreams.length) {
                  return const Center(
                    child: CupertinoActivityIndicator(),
                  );
                }
                
                final stream = displayedStreams[index];
                return MobileChannelCard(
                  stream: stream,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => IOSPlayerScreen(stream: stream),
                      ),
                    );
                  },
                );
              },
              childCount: displayedStreams.length + (_isLoadingMore ? 2 : 0),
            ),
          ),
        ),
      ],
    );
  }
}
