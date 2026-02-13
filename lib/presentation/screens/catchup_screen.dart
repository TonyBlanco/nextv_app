import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/constants/catchup_config.dart';
import '../../core/models/catchup_program.dart';
import '../../core/models/catchup_filter.dart';
import '../../core/models/xtream_models.dart';
import '../../core/providers/catchup_providers.dart';
import '../../core/providers/channel_providers.dart';
import 'player_screen.dart';
import '../widgets/catchup_filters_bar.dart';
import '../widgets/catchup_program_card.dart';

/// Main screen for catch-up/replay TV functionality
/// 
/// Features:
/// - Hybrid layout: channel sidebar + program grid
/// - Filters: category, date range, search
/// - Program cards with progress, favorites, watch later
/// - Pagination for large datasets
class CatchupScreen extends ConsumerStatefulWidget {
  const CatchupScreen({super.key});

  @override
  ConsumerState<CatchupScreen> createState() => _CatchupScreenState();
}

class _CatchupScreenState extends ConsumerState<CatchupScreen> {
  int? _selectedChannelId;
  final ScrollController _scrollController = ScrollController();

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
    // Pagination: load more when near bottom
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    // Increment page
    final currentPage = ref.read(catchupPageProvider);
    ref.read(catchupPageProvider.notifier).state = currentPage + 1;
  }

  @override
  Widget build(BuildContext context) {
    final liveStreamsAsync = ref.watch(liveStreamsProvider);

    return liveStreamsAsync.when(
      data: (streams) {
        if (streams.isEmpty) {
          return _buildEmptyState();
        }

        // Auto-select first channel if none selected
        if (_selectedChannelId == null && streams.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedChannelId = streams.first.streamId;
            });
          });
        }

        return _buildContent(streams);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildContent(List<LiveStream> channels) {
    final currentFilter = ref.watch(catchupFiltersProvider);
    final categories = _extractCategories(channels);

    return Row(
      children: [
        // Left sidebar: Channel list
        _buildChannelSidebar(channels),
        
        // Right content: Filters + Program grid
        Expanded(
          child: Container(
            color: const Color(0xFF0F1419),
            child: Column(
              children: [
                // Filters bar
                CatchupFiltersBar(
                  currentFilter: currentFilter,
                  categories: categories,
                  onFilterChanged: (filter) {
                    ref.read(catchupFiltersProvider.notifier).state = filter;
                    ref.read(catchupPageProvider.notifier).state = 0; // Reset page
                  },
                ),
                
                // Program grid
                Expanded(
                  child: _selectedChannelId != null
                      ? _buildProgramGrid(_selectedChannelId!)
                      : _buildSelectChannelPrompt(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSidebar(List<LiveStream> channels) {
    return Container(
      width: 250,
      color: NextvColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: NextvColors.surface, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: NextvColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Canales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Channel list
          Expanded(
            child: ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                final isSelected = channel.streamId == _selectedChannelId;
                
                return Material(
                  color: isSelected 
                      ? NextvColors.accent.withOpacity(0.2) 
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedChannelId = channel.streamId;
                      });
                      // Reset page when changing channel
                      ref.read(catchupPageProvider.notifier).state = 0;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isSelected 
                                ? NextvColors.accent 
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Channel logo (if available)
                          if (channel.streamIcon.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                channel.streamIcon,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.tv,
                                  size: 32,
                                  color: Colors.white24,
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.tv,
                              size: 32,
                              color: Colors.white24,
                            ),
                          
                          const SizedBox(width: 12),
                          
                          // Channel name
                          Expanded(
                            child: Text(
                              channel.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 14,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramGrid(int channelId) {
    final programsAsync = ref.watch(catchupForChannelProvider(channelId));
    final currentFilter = ref.watch(catchupFiltersProvider);

    return programsAsync.when(
      data: (programs) {
        if (programs.isEmpty) {
          return _buildNoProgramsState();
        }

        // Apply filters
        final filteredPrograms = _applyFilters(programs, currentFilter);

        if (filteredPrograms.isEmpty) {
          return _buildNoResultsState();
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: CatchupConfig.getGridColumns(),
            childAspectRatio: 0.7, // Slightly taller for program cards
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredPrograms.length,
          itemBuilder: (context, index) {
            final program = filteredPrograms[index];
            return _buildProgramCard(program);
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: NextvColors.accent),
            SizedBox(height: 16),
            Text(
              'Cargando programas...',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar programas',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard(CatchupProgram program) {
    final storageService = ref.watch(catchupStorageServiceProvider);
    final isFavorite = storageService.isFavorite(program.id);
    final isInWatchLater = storageService.isInWatchLater(program.id);
    final watchProgress = storageService.getWatchProgress(program.id);

    return CatchupProgramCard(
      program: program,
      watchProgress: watchProgress,
      isFavorite: isFavorite,
      isInWatchLater: isInWatchLater,
      onTap: () => _playProgram(program),
      onFavoriteToggle: () => _toggleFavorite(program.id),
      onWatchLaterToggle: () => _toggleWatchLater(program.id),
    );
  }

  void _playProgram(CatchupProgram program) async {
    final playbackService = ref.read(catchupPlaybackServiceProvider);
    final storageService = ref.read(catchupStorageServiceProvider);
    
    try {
      // Get playback info (checks for resume position)
      final playbackInfo = await playbackService.startPlayback(program);
      
      // Show resume dialog if has previous progress
      if (playbackInfo.shouldResume && mounted) {
        final shouldResume = await _showResumeDialog(
          program.title,
          playbackInfo.resumePosition!,
        );
        
        if (shouldResume == null) return; // User cancelled
        
        if (!shouldResume) {
          // User chose to start from beginning - reset progress
          await playbackService.resetProgress(program.id);
        }
      }
      
      
      // Navigate to player
      if (mounted) {
        // Use the stream URL from the catch-up program
        final url = program.streamUrl;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
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
        
        // Start progress tracking
        _simulateProgressTracking(program);
      }
    } catch (e) {
      _showError('Error al iniciar reproducción: $e');
    }
  }

  Future<bool?> _showResumeDialog(String title, Duration resumePosition) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NextvColors.surface,
        title: const Row(
          children: [
            Icon(Icons.play_circle_outline, color: NextvColors.accent),
            SizedBox(width: 12),
            Text(
              'Continuar viendo',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tienes progreso guardado en ${_formatDuration(resumePosition)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Deseas continuar desde donde lo dejaste?',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Desde el inicio',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: NextvColors.accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _simulateProgressTracking(CatchupProgram program) {
    // Simulate progress tracking (in real implementation, this would be in the player)
    // This is just for demonstration
    Future.delayed(const Duration(seconds: 5), () async {
      if (mounted) {
        final playbackService = ref.read(catchupPlaybackServiceProvider);
        // Simulate 30 seconds of playback
        await playbackService.updateProgress(
          programId: program.id,
          position: const Duration(seconds: 30),
          duration: program.duration,
        );
        debugPrint('Progress updated: 30s / ${program.duration.inSeconds}s');
      }
    });
  }

  Future<void> _toggleFavorite(String programId) async {
    final storageService = ref.read(catchupStorageServiceProvider);
    try {
      await storageService.toggleFavorite(programId);
      setState(() {}); // Refresh UI
    } catch (e) {
      _showError('Error al actualizar favoritos: $e');
    }
  }

  Future<void> _toggleWatchLater(String programId) async {
    final storageService = ref.read(catchupStorageServiceProvider);
    try {
      if (storageService.isInWatchLater(programId)) {
        await storageService.removeFromWatchLater(programId);
      } else {
        await storageService.addToWatchLater(programId);
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      _showError('Error al actualizar "Ver más tarde": $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<CatchupProgram> _applyFilters(
    List<CatchupProgram> programs,
    CatchupFilter filter,
  ) {
    var filtered = programs;

    // Filter by category
    if (filter.category != null) {
      filtered = filtered.where((p) => p.category == filter.category).toList();
    }

    // Filter by date range
    if (filter.dateRange != null) {
      filtered = filtered.where((p) {
        return p.startTime.isAfter(filter.dateRange!.start) &&
               p.startTime.isBefore(filter.dateRange!.end);
      }).toList();
    }

    // Filter by search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(query) ||
               p.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sort order
    switch (filter.sortOrder) {
      case CatchupSortOrder.newestFirst:
        filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case CatchupSortOrder.oldestFirst:
        filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case CatchupSortOrder.channelName:
        filtered.sort((a, b) => a.channelName.compareTo(b.channelName));
        break;
      case CatchupSortOrder.programName:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return filtered;
  }

  List<String> _extractCategories(List<LiveStream> channels) {
    final categories = <String>{};
    for (final channel in channels) {
      // Extract category from channel if available
      // This is a placeholder - actual implementation depends on API
      if (channel.categoryId.isNotEmpty) {
        categories.add(channel.categoryId);
      }
    }
    return categories.toList()..sort();
  }

  // ─── EMPTY STATES ───

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'No hay canales disponibles',
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

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NextvColors.accent),
          SizedBox(height: 16),
          Text(
            'Cargando canales...',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar canales',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectChannelPrompt() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back,
            size: 64,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'Selecciona un canal',
            style: TextStyle(color: Colors.white60),
          ),
          SizedBox(height: 8),
          Text(
            'Elige un canal de la lista para ver programas disponibles',
            style: TextStyle(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoProgramsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv_off,
            size: 64,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'No hay programas disponibles',
            style: TextStyle(color: Colors.white60),
          ),
          SizedBox(height: 8),
          Text(
            'Este canal no tiene catch-up habilitado',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white24,
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(color: Colors.white60),
          ),
          SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
