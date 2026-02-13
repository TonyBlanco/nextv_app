import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/nextv_colors.dart';
import '../../../core/models/xtream_models.dart';
import '../../../core/providers/channel_providers.dart';
import '../../../core/providers/category_providers.dart';
import '../shared/mobile_channel_card.dart';
import '../shared/mobile_search_bar.dart';
import 'android_player_screen.dart';

/// Android-optimized home screen with Material Design
/// - Material navigation
/// - Android-style scrolling physics
/// - Material design patterns
class AndroidHomeScreen extends ConsumerStatefulWidget {
  const AndroidHomeScreen({super.key});

  @override
  ConsumerState<AndroidHomeScreen> createState() => _AndroidHomeScreenState();
}

class _AndroidHomeScreenState extends ConsumerState<AndroidHomeScreen> {
  String _selectedCategoryId = '';
  final ScrollController _scrollController = ScrollController();
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
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(liveCategoriesProvider);

    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        backgroundColor: NextvColors.background,
        elevation: 0,
        title: const Text(
          'NeXtv',
          style: TextStyle(
            color: NextvColors.accent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Open search
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: Open settings
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildContent(categories),
        loading: () => const Center(
          child: CircularProgressIndicator(color: NextvColors.accent),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading categories: $error',
            style: const TextStyle(color: Colors.white),
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
              child: CircularProgressIndicator(color: NextvColors.accent),
            ),
            error: (error, stack) => const Center(
              child: Text(
                'Error loading channels',
                style: TextStyle(color: Colors.white),
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
            child: FilterChip(
              label: Text(category.categoryName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryId = selected ? category.categoryId : '';
                  _currentPage = 0;
                });
              },
              backgroundColor: NextvColors.surface,
              selectedColor: NextvColors.accent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : NextvColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelGrid(List<LiveStream> allStreams) {
    final displayedStreams = allStreams.take((_currentPage + 1) * _channelsPerPage).toList();
    
    return RefreshIndicator(
      color: NextvColors.accent,
      onRefresh: () async {
        ref.invalidate(liveStreamsProvider);
        setState(() => _currentPage = 0);
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: displayedStreams.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= displayedStreams.length) {
            return const Center(
              child: CircularProgressIndicator(color: NextvColors.accent),
            );
          }
          
          final stream = displayedStreams[index];
          return MobileChannelCard(
            stream: stream,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AndroidPlayerScreen(stream: stream),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
