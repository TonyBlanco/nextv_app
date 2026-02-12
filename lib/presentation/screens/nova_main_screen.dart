import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/playlist_generator.dart';
import '../../core/models/xtream_models.dart';
import '../../core/models/playlist_model.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/xtream_api_service.dart';
import '../../core/services/provider_manager.dart';
import '../../core/providers/active_playlist_provider.dart';
import '../../core/localization.dart';
import '../../core/parental_provider.dart';
import '../../core/constants/nextv_colors.dart';
import '../widgets/epg_modal.dart';
import '../widgets/parental_control_modal.dart';
import '../widgets/category_filter.dart';
import '../widgets/pro_ui_widgets.dart';
import '../widgets/tv_mode_widgets.dart';
import '../widgets/nextv_logo.dart';
import '../widgets/premium_top_bar.dart';
import '../widgets/favorite_button.dart';
import '../../core/providers/favorites_provider.dart';
import 'settings_screen.dart';
import 'provider_manager_screen.dart';
import 'vod_grid_screen.dart';
import 'series_grid_screen.dart';


// ========== PROVIDERS ==========
final currentProviderName = StateProvider<String>((ref) => 'TREXRES');
final currentCategoryName = StateProvider<String>((ref) => 'All Categories');
final categoriesProvider = StateProvider<List<LiveCategory>>((ref) => []);
final streamsProvider = StateProvider<List<LiveStream>>((ref) => []);
final currentStreamProvider = StateProvider<LiveStream?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final selectedTabProvider = StateProvider<int>((ref) => 0); // 0=Live, 1=Movies, 2=Series
final streamModeProvider = StateProvider<String>((ref) => 'live');
final loadErrorProvider = StateProvider<String?>((ref) => null);

class NovaMainScreen extends ConsumerStatefulWidget {
  const NovaMainScreen({super.key});

  @override
  ConsumerState<NovaMainScreen> createState() => _NovaMainScreenState();
}

class _NovaMainScreenState extends ConsumerState<NovaMainScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Dio _dio = Dio();
  BetterPlayerController? _betterPlayerController;
  VlcPlayerController? _vlcPlayerController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _playbackError;
  bool _isRecording = false;
  String? _recordingPath;
  bool _isCheckingChannel = false;
  bool _isChannelLive = false;
  String? _currentQuality;
  String? _currentPlayer;
  String? _changeFeedbackMessage;
  Timer? _feedbackTimer;
  Timer? _playbackTimeoutTimer;
  int _autoSkipCount = 0;
  static const int _maxAutoSkips = 5; // Don't auto-skip more than 5 in a row
  late AnimationController _badgeAnimationController;
  late Animation<double> _badgeOpacityAnimation;
  bool _isEPGOverlayVisible = false;
  bool _showDisclaimer = true;
  Timer? _disclaimerTimer;

  // PlayerControls state variables
  bool _isPlaying = false;
  bool _isFullscreen = false;
  double _volume = 0.7;
  Duration? _position;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _badgeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeAnimationController, curve: Curves.easeInOut),
    );
    _badgeAnimationController.forward();
    _currentQuality = 'auto'; // Initialize default quality
    // Auto-dismiss disclaimer after 5 seconds
    _disclaimerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showDisclaimer = false);
    });
    Future.microtask(() {
      // Sync provider name from ProviderManager
      final pm = ref.read(providerManagerProvider);
      final playlist = ref.read(activePlaylistProvider);
      if (pm.activeProviderType == 'unknown' && playlist != null) {
        // ProviderManager not synced yet — fix it
        pm.setActiveProvider(
          name: playlist.name,
          type: playlist.type == 'xtream' ? 'xtream' : 'm3u',
        );
      }
      ref.read(currentProviderName.notifier).state = pm.activeProviderName;

      // If categories were pre-loaded by StartupScreen, don't reload
      final existingCats = ref.read(categoriesProvider);
      final existingStreams = ref.read(streamsProvider);
      if (existingCats.isNotEmpty && existingStreams.isNotEmpty) {
        debugPrint('Categories pre-loaded: ${existingCats.length} cats, ${existingStreams.length} streams');
        return; // Already loaded by main.dart StartupScreen
      }
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _dio.close(force: true);
    _betterPlayerController?.dispose();
    _vlcPlayerController?.dispose();
    _searchController.dispose();
    _badgeAnimationController.dispose();
    _playbackTimeoutTimer?.cancel();
    _feedbackTimer?.cancel();
    _disclaimerTimer?.cancel();
    // Restore system UI on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _loadCategories() async {
    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(loadErrorProvider.notifier).state = null;
    final selectedTab = ref.read(selectedTabProvider);
    final api = ref.read(xtreamAPIProvider);
    final playlist = ref.read(activePlaylistProvider);
    final pm = ref.read(providerManagerProvider);

    // Update provider name
    ref.read(currentProviderName.notifier).state = pm.activeProviderName;

    // M3U/Local provider - categories already loaded by ProviderManager
    if (pm.activeProviderType == 'm3u' || pm.activeProviderType == 'local') {
      final cats = pm.cachedCategories;
      ref.read(categoriesProvider.notifier).state = cats;
      if (cats.isNotEmpty) {
        ref.read(currentCategoryName.notifier).state = cats.first.categoryName;
        _loadStreams(cats.first.categoryId);
      } else {
        ref.read(streamsProvider.notifier).state = pm.getAllM3UStreams();
      }
      ref.read(isLoadingProvider.notifier).state = false;
      return;
    }

    // Xtream provider
    if (!api.isInitialized && playlist != null) {
      final creds = playlist.toXtreamCredentials;
      if (creds != null) api.setCredentials(creds);
    }

    if (!api.isInitialized) {
      ref.read(loadErrorProvider.notifier).state = 
        'No hay credenciales configuradas. Añade una lista o usa un fallback.';
      ref.read(isLoadingProvider.notifier).state = false;
      return;
    }
    
    try {
      List<LiveCategory> cats = [];
      if (selectedTab == 0) {
        cats = await api.getLiveCategories();
      } else if (selectedTab == 1) {
        final vodCats = await api.getVODCategories();
        cats = vodCats.map((vc) => LiveCategory(
          categoryId: vc.categoryId,
          categoryName: vc.categoryName,
          parentId: vc.parentId,
        )).toList();
      } else if (selectedTab == 2) {
        final seriesCats = await api.getSeriesCategories();
        cats = seriesCats.map((sc) => LiveCategory(
          categoryId: sc.categoryId,
          categoryName: sc.categoryName,
          parentId: sc.parentId,
        )).toList();
      } else if (selectedTab == 3) {
        // Catch Up: load live categories (catch-up streams are live channels with tv_archive=1)
        cats = await api.getLiveCategories();
      }

      ref.read(categoriesProvider.notifier).state = cats;
      if (cats.isNotEmpty) {
        ref.read(currentCategoryName.notifier).state = cats.first.categoryName;
        await _loadStreams(cats.first.categoryId);
      } else {
        ref.read(loadErrorProvider.notifier).state = 
          'No se encontraron categorías. Prueba otro proveedor o un fallback.';
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      ref.read(loadErrorProvider.notifier).state = 
        'Error al cargar: ${e.toString().substring(0, e.toString().length.clamp(0, 100))}';
    }
    ref.read(isLoadingProvider.notifier).state = false;
  }

  Future<void> _loadStreams(String categoryId) async {
    ref.read(isLoadingProvider.notifier).state = true;
    final selectedTab = ref.read(selectedTabProvider);
    final api = ref.read(xtreamAPIProvider);
    final pm = ref.read(providerManagerProvider);

    // M3U/Local provider - get from cached entries
    if (pm.activeProviderType == 'm3u' || pm.activeProviderType == 'local') {
      final streams = pm.getM3UStreamsByCategory(categoryId);
      ref.read(streamsProvider.notifier).state = streams;
      ref.read(isLoadingProvider.notifier).state = false;
      return;
    }
    
    try {
      List<LiveStream> streams = [];
      if (selectedTab == 0) {
        streams = await api.getLiveStreams(categoryId: categoryId);
      } else if (selectedTab == 1) {
        // VOD streams - convert to LiveStream for UI compatibility
        final vodStreams = await api.getVODStreams(categoryId: categoryId);
        streams = vodStreams.map((vs) => LiveStream(
          num: vs.num,
          name: vs.name,
          streamType: 'movie',
          streamId: vs.streamId,
          streamIcon: vs.streamIcon,
          epgChannelId: 0,
          added: vs.added,
          categoryId: vs.categoryId,
          customSid: '',
          tvArchive: 0,
          directSource: vs.directSource,
          tvArchiveDuration: 0,
        )).toList();
      } else if (selectedTab == 2) {
        // Series - use SeriesItem objects and convert to LiveStream
        final seriesList = await api.getSeries(categoryId: categoryId);
        streams = seriesList.map((s) => LiveStream(
          num: s.num,
          name: s.name,
          streamType: 'series',
          streamId: s.seriesId,
          streamIcon: s.cover,
          epgChannelId: 0,
          added: s.lastModified,
          categoryId: s.categoryId,
          customSid: '',
          tvArchive: 0,
          directSource: '',
          tvArchiveDuration: 0,
        )).toList();
      }
      ref.read(streamsProvider.notifier).state = streams;
    } catch (e) {
      debugPrint('Error loading streams: $e');
      ref.read(loadErrorProvider.notifier).state = 'Error al cargar streams: $e';
    }
    ref.read(isLoadingProvider.notifier).state = false;
  }

  Future<void> _checkChannelStatus(String url, [Map<String, String> headers = const {}]) async {
    setState(() => _isCheckingChannel = true);
    try {
      final response = await _dio.head(url, options: Options(
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
          ...headers,
        },
      ));
      setState(() => _isChannelLive = response.statusCode == 200);
    } catch (e) {
      setState(() => _isChannelLive = false);
    }
    setState(() => _isCheckingChannel = false);
  }

  /// Auto-skip to next channel when current one fails
  void _skipToNextChannel() {
    if (_autoSkipCount >= _maxAutoSkips) {
      debugPrint('Auto-skip limit reached ($_maxAutoSkips). Stopping.');
      setState(() {
        _playbackError = 'Varios canales sin señal. Selecciona otro canal manualmente.';
        _autoSkipCount = 0;
      });
      return;
    }

    final currentStream = ref.read(currentStreamProvider);
    final streams = ref.read(streamsProvider);
    if (currentStream == null || streams.isEmpty) return;

    final currentIndex = streams.indexWhere((s) => s.streamId == currentStream.streamId);
    if (currentIndex == -1 || currentIndex >= streams.length - 1) {
      setState(() => _playbackError = 'No hay más canales disponibles.');
      return;
    }

    final nextStream = streams[currentIndex + 1];
    _autoSkipCount++;
    debugPrint('Auto-skipping to next channel ($_autoSkipCount/$_maxAutoSkips): ${nextStream.name}');
    
    setState(() {
      _playbackError = null;
      _changeFeedbackMessage = 'Canal sin señal → ${nextStream.name}';
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _changeFeedbackMessage = null);
    });

    _playStream(nextStream);
  }

  /// Start a timeout that auto-skips if no video plays within the given duration
  void _startPlaybackTimeout() {
    _playbackTimeoutTimer?.cancel();
    _playbackTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      // If still no progress after 15s, the stream is dead
      if (_position == null || _position == Duration.zero) {
        debugPrint('Playback timeout: no progress after 15s, skipping...');
        _skipToNextChannel();
      }
    });
  }

  void _playStream(LiveStream stream) async {
    ref.read(currentStreamProvider.notifier).state = stream;
    setState(() {
      _playbackError = null;
      _position = null; // Reset position for timeout check
    });
    _playbackTimeoutTimer?.cancel();

    final settings = ref.read(settingsProvider);
    final selectedTab = ref.read(selectedTabProvider);
    final streamMode = ref.read(streamModeProvider);
    final api = ref.read(xtreamAPIProvider);
    
    final pm = ref.read(providerManagerProvider);
    
    // Build URL based on provider type
    String url;
    String extension = 'm3u8';
    
    if (pm.activeProviderType == 'm3u' || pm.activeProviderType == 'local') {
      // M3U/Local provider - use directSource URL
      url = stream.directSource;
      if (url.isEmpty) {
        final m3uUrl = pm.getM3UStreamUrl(stream.streamId);
        if (m3uUrl == null) {
          setState(() => _playbackError = 'URL del canal no disponible');
          return;
        }
        url = m3uUrl;
      }
      extension = url.endsWith('.mp4') ? 'mp4' : 'm3u8';
    } else if (api.isInitialized) {
      // Xtream provider
      if (selectedTab == 0) {
        // Apply user's stream format setting
        final streamFormat = settings.streamFormat;
        if (streamFormat == 'hls') {
          extension = 'm3u8';
        } else if (streamFormat == 'mpegts') {
          extension = 'ts';
        } else {
          // Auto: use streamMode-based logic
          switch (streamMode) {
            case '4k':
              extension = 'm3u8';
              break;
            case 'hd':
            case 'sd':
              extension = 'ts';
              break;
            default:
              extension = 'm3u8';
          }
        }
        url = api.getLiveStreamUrl(stream.streamId, extension: extension);
      } else {
        extension = 'mp4';
        url = api.getVODStreamUrl(stream.streamId, extension: extension);
      }
    } else {
      setState(() => _playbackError = 'No hay proveedor configurado');
      return;
    }

    // Check channel status
    await _checkChannelStatus(url, stream.httpHeaders);

    if (settings.playerType == 'external') {
      // Launch external player
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (settings.playerType == 'vlc') {
      try {
        await _playWithVLC(url);
      } catch (e) {
        debugPrint('VLC failed, falling back to BetterPlayer: $e');
        await _playWithBetterPlayer(url, extension, stream.httpHeaders);
      }
    } else {
      await _playWithBetterPlayer(url, extension, stream.httpHeaders);
    }
    // Start timeout: if no progress in 10s, skip to next
    _startPlaybackTimeout();
  }

  Future<void> _playWithBetterPlayer(String fullUrl, String extension, [Map<String, String> extraHeaders = const {}]) async {
    _vlcPlayerController?.dispose();
    _vlcPlayerController = null;

    final url = fullUrl;
    debugPrint('Playing: $url');
    if (extraHeaders.isNotEmpty) debugPrint('With headers: $extraHeaders');

    // Build headers map - always include User-Agent and Referer for M3U streams
    final Map<String, String> headers = {
      if (extraHeaders.isEmpty) ...{
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
        'Referer': Uri.parse(url).origin,
        'Origin': Uri.parse(url).origin,
      },
      ...extraHeaders,
    };
      
    try {
      // Attempt to attach subtitles from the current stream metadata
      final currentStream = ref.read(currentStreamProvider);
      List<BetterPlayerSubtitlesSource>? bpSubs;
      if (currentStream != null && currentStream.subtitles.isNotEmpty) {
        bpSubs = currentStream.subtitles.map((s) {
          return BetterPlayerSubtitlesSource(
            type: BetterPlayerSubtitlesSourceType.network,
            urls: [s.url],
            name: s.name ?? s.language,
          );
        }).toList();
      }

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        headers: headers,
        subtitles: bpSubs,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 15000,
          maxBufferMs: 50000,
          bufferForPlaybackMs: 3000,
          bufferForPlaybackAfterRebufferMs: 8000,
        ),
        liveStream: extension != 'mp4',
        videoFormat: extension == 'm3u8' || extension == 'm3u' ? BetterPlayerVideoFormat.hls : null,
      );

        if (_betterPlayerController != null) {
          await _betterPlayerController!.setupDataSource(dataSource);
        } else {
          _betterPlayerController = BetterPlayerController(
            BetterPlayerConfiguration(
              aspectRatio: 16 / 9,
              autoPlay: true,
              autoDispose: false,
              fit: BoxFit.contain,
              handleLifecycle: true,
              autoDetectFullscreenAspectRatio: true,
              allowedScreenSleep: false,
              controlsConfiguration: const BetterPlayerControlsConfiguration(
                enableFullscreen: true,
                enableSkips: false,
                enablePlayPause: true,
                enableProgressBar: true,
                enableProgressText: true,
                enableRetry: true,
              ),
              errorBuilder: (context, errorMessage) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_next, size: 48, color: Colors.orangeAccent),
                      SizedBox(height: 16),
                      Text('Canal sin señal, buscando siguiente...', 
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                );
              },
              eventListener: (event) {
                if (event.betterPlayerEventType == BetterPlayerEventType.openFullscreen) {
                  setState(() => _isFullscreen = true);
                } else if (event.betterPlayerEventType == BetterPlayerEventType.hideFullscreen) {
                  setState(() => _isFullscreen = false);
                } else if (event.betterPlayerEventType == BetterPlayerEventType.play) {
                  _playbackTimeoutTimer?.cancel(); // Cancel timeout, we got playback
                  _autoSkipCount = 0; // Reset skip counter on successful play
                  setState(() {
                    _isPlaying = true;
                    _playbackError = null;
                  });
                } else if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
                  setState(() => _isPlaying = false);
                } else if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
                  _playbackTimeoutTimer?.cancel(); // Got progress, stream is alive
                  setState(() {
                    _position = event.parameters?['progress'] as Duration?;
                    _duration = event.parameters?['duration'] as Duration?;
                  });
                } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
                  debugPrint('BetterPlayer exception: ${event.parameters}');
                  _playbackTimeoutTimer?.cancel();
                  // Try to retry the same stream first, then skip
                  final currentStream = ref.read(currentStreamProvider);
                  if (currentStream != null && _autoSkipCount < 2) {
                    _autoSkipCount++;
                    debugPrint('Retrying stream (attempt $_autoSkipCount/2)...');
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) _playStream(currentStream);
                    });
                  } else {
                    // After 2 retries, skip to next channel
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) _skipToNextChannel();
                    });
                  }
                }
              },
            ),
            betterPlayerDataSource: dataSource,
          );
        }
        setState(() => _isPlaying = true);
        return; // Success
      } catch (e) {
        debugPrint('Failed to play: $e');
      }
    
    // Failed
    setState(() => _playbackError = 'Could not play stream. Try VLC player in Settings.');
  }

  Future<void> _playWithVLC(String url) async {
    _betterPlayerController?.dispose();
    _betterPlayerController = null;

    try {
      if (_vlcPlayerController != null) {
        _vlcPlayerController!.setMediaFromNetwork(url, hwAcc: HwAcc.full, autoPlay: true);
      } else {
        _vlcPlayerController = VlcPlayerController.network(
          url,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
            ]),
          ),
        );

        // Add listeners for VLC player
        _vlcPlayerController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _vlcPlayerController!.value.isPlaying;
              _position = _vlcPlayerController!.value.position;
              _duration = _vlcPlayerController!.value.duration;
            });
          }
        });
      }
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('VLC player error: $e');
      _vlcPlayerController?.dispose();
      _vlcPlayerController = null;
      rethrow; // Let _playStream catch and fallback to BetterPlayer
    }
  }

  bool get _isMobilePortrait {
    final size = MediaQuery.of(context).size;
    return size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    String tr(String key) => Localization.tr(key, settings.locale);
    final selectedTab = ref.watch(selectedTabProvider);
    final pm = ref.read(providerManagerProvider);

    if (_isMobilePortrait) {
      return _buildMobileLayout(tr, settings, selectedTab);
    }

    return Scaffold(
      backgroundColor: NextvColors.background,
      body: _isFullscreen
        ? _buildMainArea(tr, settings) // Fullscreen: player only
        : Column(
            children: [
              _buildTopBar(tr, settings),
              _buildSecondaryBar(tr),
              Expanded(
                child: selectedTab == 1
                    ? _buildVODContent() // Movies tab
                    : selectedTab == 2
                        ? _buildSeriesContent() // Series tab
                        : selectedTab == 3
                            ? _buildCatchUpContent() // Catch Up tab
                            : Row( // Live TV tab (default)
                                children: [
                                  _buildSidebar(tr),
                                  Expanded(child: _buildMainArea(tr, settings)),
                                ],
                          ),
              ),
              _buildBottomBar(tr),
            ],
          ),
    );
  }

  // ========== MOBILE PORTRAIT LAYOUT ==========
  Widget _buildMobileLayout(String Function(String) tr, AppSettings settings, int selectedTab) {
    final currentStream = ref.watch(currentStreamProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: NextvColors.background,
      // Drawer = channel list, auto-closes on select
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Drawer(
          backgroundColor: NextvColors.surface,
          child: _buildMobileDrawerContent(tr),
        ),
      ),
      body: _isFullscreen
        ? _buildMainArea(tr, settings)
        : Column(
            children: [
              // Simplified mobile top bar
              _buildMobileTopBar(tr, currentStream),
              // Main content area
              Expanded(
                child: selectedTab == 1
                    ? _buildVODContent()
                    : selectedTab == 2
                        ? _buildSeriesContent()
                        : selectedTab == 3
                            ? _buildCatchUpContent()
                            : _buildMainArea(tr, settings),
              ),
            ],
          ),
      // Bottom tab navigation
      bottomNavigationBar: _isFullscreen ? null : _buildMobileBottomNav(tr, selectedTab),
    );
  }

  // ========== MOBILE TOP BAR ==========
  Widget _buildMobileTopBar(String Function(String) tr, LiveStream? currentStream) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Hamburger menu to open drawer
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white70),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            // Logo
            const NextvLogo(size: 20, showText: true, withGlow: false),
            const SizedBox(width: 12),
            // Current channel name
            Expanded(
              child: Text(
                currentStream?.name ?? tr('select_channel'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // Live indicator dot
            if (currentStream != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _isChannelLive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            // Settings
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white54, size: 20),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // ========== MOBILE BOTTOM NAV ==========
  Widget _buildMobileBottomNav(String Function(String) tr, int selectedTab) {
    return BottomNavigationBar(
      currentIndex: selectedTab,
      onTap: (index) {
        ref.read(selectedTabProvider.notifier).state = index;
        _loadCategories();
      },
      backgroundColor: NextvColors.surface,
      selectedItemColor: NextvColors.voltGreen,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.live_tv, size: 22),
          label: tr('live_tv'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.movie, size: 22),
          label: tr('movies'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.tv, size: 22),
          label: tr('series'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.replay, size: 22),
          label: tr('catch_up'),
        ),
      ],
    );
  }

  // ========== MOBILE DRAWER CONTENT ==========
  Widget _buildMobileDrawerContent(String Function(String) tr) {
    final streams = ref.watch(streamsProvider);
    final currentStream = ref.watch(currentStreamProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final currentCat = ref.watch(currentCategoryName);
    final parentalSettings = ref.watch(parentalProvider);
    final categories = ref.watch(categoriesProvider);
    final loadError = ref.watch(loadErrorProvider);

    final categoryMap = {for (var c in categories) c.categoryId: c.categoryName};
    final filteredCategories = parentalSettings.enabled
        ? categories.where((c) => !parentalSettings.blockedCategories.contains(c.categoryName)).toList()
        : categories;

    final filteredStreams = _searchQuery.isEmpty
        ? streams.where((s) => !parentalSettings.enabled || !parentalSettings.blockedCategories.contains(categoryMap[s.categoryId] ?? '')).toList()
        : streams.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            (!parentalSettings.enabled || !parentalSettings.blockedCategories.contains(categoryMap[s.categoryId] ?? ''))
          ).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header with provider name
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: NextvColors.surfaceDark,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const NextvLogo(size: 16, showText: true, withGlow: false),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category dropdown
                PopupMenuButton<LiveCategory>(
                  onSelected: (cat) {
                    ref.read(currentCategoryName.notifier).state = cat.categoryName;
                    _loadStreams(cat.categoryId);
                  },
                  itemBuilder: (context) => filteredCategories.map((c) => PopupMenuItem(
                    value: c,
                    child: Text(c.categoryName),
                  )).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: NextvColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category, size: 16, color: NextvColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(currentCat, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: tr('search_channels'),
                hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                filled: true,
                fillColor: NextvColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Loading / Error / Channel List
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (loadError != null)
            Expanded(child: Center(child: Text(loadError, style: const TextStyle(color: Colors.red))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredStreams.length,
                itemBuilder: (context, index) {
                  final stream = filteredStreams[index];
                  final isSelected = currentStream?.streamId == stream.streamId;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: NextvColors.accent.withOpacity(0.15),
                    leading: stream.streamIcon.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(stream.streamIcon, width: 32, height: 32, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 24, color: Colors.white38)),
                          )
                        : const Icon(Icons.tv, size: 24, color: Colors.white38),
                    title: Text(
                      stream.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? NextvColors.accent : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _playStream(stream);
                      Navigator.pop(context); // Auto-close drawer
                    },
                  );
                },
              ),
            ),
          // Channel count
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Text(
              '${filteredStreams.length} channels',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVODContent() {
    final pm = ref.read(providerManagerProvider);
    final api = ref.read(xtreamAPIProvider);
    final playlist = ref.read(activePlaylistProvider);
    
    // Ensure provider is synced from active playlist
    if (pm.activeProviderType == 'unknown' && playlist != null) {
      pm.setActiveProvider(
        name: playlist.name,
        type: playlist.type == 'xtream' ? 'xtream' : 'm3u',
      );
    }
    // Ensure Xtream API is initialized
    if (!api.isInitialized && playlist != null) {
      final creds = playlist.toXtreamCredentials;
      if (creds != null) api.setCredentials(creds);
    }
    
    // Only show VOD content for Xtream providers
    if (pm.activeProviderType != 'xtream' || !api.isInitialized) {
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
              'VOD solo disponible con proveedores Xtream',
              style: TextStyle(color: Colors.white60),
            ),
            SizedBox(height: 8),
            Text(
              'Conecta una cuenta Xtream para ver películas',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Get VOD categories from the last provider result
    final vodCategories = <VODCategory>[];
    // Note: We need to store VOD categories in state when connecting
    // For now, we'll load them on demand
    
    return FutureBuilder<List<VODCategory>>(
      future: api.getVODCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: NextvColors.accent),
                SizedBox(height: 16),
                Text(
                  'Cargando películas...',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
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
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final categories = snapshot.data ?? [];
        return VODGridScreen(
          categories: categories,
          api: api,
        );
      },
    );
  }

  Widget _buildSeriesContent() {
    final pm = ref.read(providerManagerProvider);
    final api = ref.read(xtreamAPIProvider);
    final playlist = ref.read(activePlaylistProvider);
    
    // Ensure provider is synced from active playlist
    if (pm.activeProviderType == 'unknown' && playlist != null) {
      pm.setActiveProvider(
        name: playlist.name,
        type: playlist.type == 'xtream' ? 'xtream' : 'm3u',
      );
    }
    // Ensure Xtream API is initialized
    if (!api.isInitialized && playlist != null) {
      final creds = playlist.toXtreamCredentials;
      if (creds != null) api.setCredentials(creds);
    }
    
    // Only show Series content for Xtream providers
    if (pm.activeProviderType != 'xtream' || !api.isInitialized) {
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
              'Series solo disponibles con proveedores Xtream',
              style: TextStyle(color: Colors.white60),
            ),
            SizedBox(height: 8),
            Text(
              'Conecta una cuenta Xtream para ver series',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return FutureBuilder<List<SeriesCategory>>(
      future: api.getSeriesCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: NextvColors.accent),
                SizedBox(height: 16),
                Text(
                  'Cargando series...',
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
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
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final categories = snapshot.data ?? [];
        return SeriesGridScreen(
          categories: categories,
          api: api,
        );
      },
    );
  }

  Widget _buildCatchUpContent() {
    final pm = ref.read(providerManagerProvider);
    final api = ref.read(xtreamAPIProvider);
    final playlist = ref.read(activePlaylistProvider);

    // Ensure provider is synced from active playlist
    if (pm.activeProviderType == 'unknown' && playlist != null) {
      pm.setActiveProvider(
        name: playlist.name,
        type: playlist.type == 'xtream' ? 'xtream' : 'm3u',
      );
    }
    // Ensure Xtream API is initialized
    if (!api.isInitialized && playlist != null) {
      final creds = playlist.toXtreamCredentials;
      if (creds != null) api.setCredentials(creds);
    }

    if (pm.activeProviderType != 'xtream' || !api.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.replay, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Catch Up solo disponible con proveedores Xtream',
                style: TextStyle(color: Colors.white60)),
            SizedBox(height: 8),
            Text('Conecta una cuenta Xtream para ver programas anteriores',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    // Catch Up: show live channels that support catch-up (tv_archive == 1)
    return FutureBuilder<List<LiveStream>>(
      future: _loadCatchUpStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: NextvColors.accent),
                SizedBox(height: 16),
                Text('Cargando Catch Up...', style: TextStyle(color: Colors.white60)),
              ],
            ),
          );
        }

        final streams = snapshot.data ?? [];
        if (streams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text('No hay canales con Catch Up disponibles',
                    style: TextStyle(color: Colors.white60)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: streams.length,
          itemBuilder: (context, index) {
            final stream = streams[index];
            return ListTile(
              leading: stream.streamIcon.isNotEmpty
                  ? Image.network(stream.streamIcon, width: 40, height: 40,
                      errorBuilder: (_, __, ___) => const Icon(Icons.replay, color: Colors.white54))
                  : const Icon(Icons.replay, color: Colors.white54),
              title: Text(stream.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('Catch Up: ${stream.tvArchiveDuration} days',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () => _playStream(stream),
            );
          },
        );
      },
    );
  }

  Future<List<LiveStream>> _loadCatchUpStreams() async {
    final api = ref.read(xtreamAPIProvider);
    final categories = await api.getLiveCategories();
    final List<LiveStream> catchUpStreams = [];
    for (final cat in categories) {
      try {
        final streams = await api.getLiveStreams(categoryId: cat.categoryId);
        catchUpStreams.addAll(streams.where((s) => s.tvArchive == 1));
      } catch (_) {}
      if (catchUpStreams.length >= 200) break; // Limit for performance
    }
    return catchUpStreams;
  }

  // ========== TOP BAR (Logo + Tabs + VPN indicator) ==========
  Widget _buildTopBar(String Function(String) tr, AppSettings settings) {
    final selectedTab = ref.watch(selectedTabProvider);

    return PremiumTopBar(
      selectedTab: selectedTab,
      tvMode: settings.tvMode,
      showVPNIndicator: settings.vpnEnabled,
      onTabChanged: (index) {
        ref.read(selectedTabProvider.notifier).state = index;
        _loadCategories();
      },
      onSettingsPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      onParentalPressed: () => _showParentalModal(),
    );
  }

  Widget _buildTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? NextvColors.voltGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.white54),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  // ========== SHOW FULL EPG ==========
  void _showFullEPG(BuildContext context) {
    final currentStream = ref.read(currentStreamProvider);
    if (currentStream != null) {
      final pm = ref.read(providerManagerProvider);
      final playlist = ref.read(activePlaylistProvider);
      
      if (pm.activeProviderType == 'm3u' || pm.activeProviderType == 'local') {
        // M3U/Local provider - use XMLTV EPG from playlist if available
        final epgUrl = playlist?.epgUrl;
        showDialog(
          context: context,
          builder: (_) => EPGModal(
            stream: currentStream,
            xmltvUrl: epgUrl,
          ),
        );
      } else if (playlist != null) {
        // Xtream provider
        final creds = playlist.toXtreamCredentials;
        if (creds != null) {
          showDialog(
            context: context,
            builder: (_) => EPGModal(
              stream: currentStream,
              serverUrl: creds.serverUrl,
              username: creds.username,
              password: creds.password,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un canal primero para ver la guía EPG')),
      );
    }
  }

  // ========== SHOW CATEGORY FILTER ==========
  void _showCategoryFilter(BuildContext context) {
    final categories = ref.read(categoriesProvider);
    showDialog(
      context: context,
      builder: (_) => CategoryFilterDialog(
        availableCategories: categories,
      ),
    ).then((_) {
      // After dialog closes, apply the filter from the provider state
      final filterState = ref.read(categoryFilterProvider);
      if (filterState.selectedCategories.isNotEmpty) {
        final filtered = categories.where(
          (c) => filterState.selectedCategories.contains(c.categoryName),
        ).toList();
        if (filtered.isNotEmpty) {
          ref.read(currentCategoryName.notifier).state = filtered.first.categoryName;
          _loadStreams(filtered.first.categoryId);
        }
      } else {
        // No filter - reload all
        _loadCategories();
      }
    });
  }

  // ========== SECONDARY BAR (Provider/Category dropdowns + EPG buttons) ==========
  Widget _buildSecondaryBar(String Function(String) tr) {
    final pm = ref.watch(providerManagerProvider);
    final categories = ref.watch(categoriesProvider);
    final currentCat = ref.watch(currentCategoryName);
    final parentalSettings = ref.watch(parentalProvider);
    final settings = ref.watch(settingsProvider);

    final filteredCategories = parentalSettings.enabled
        ? categories.where((c) => !parentalSettings.blockedCategories.contains(c.categoryName)).toList()
        : categories;

    if (settings.tvMode) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: NextvColors.background,
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            // Provider dropdown
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderManagerScreen()));
                _loadCategories();
              },
              child: TvModeCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(ref.watch(currentProviderName), style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Category dropdown
            TvModeCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(currentCat, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // EPG & Category buttons
            TvModeButton(
              icon: Icons.calendar_today,
              label: tr('show_full_epg'),
              onPressed: () => _showFullEPG(context),
            ),
            const SizedBox(width: 12),
            TvModeButton(
              icon: Icons.category,
              label: tr('add_remove_categories'),
              onPressed: () => _showCategoryFilter(context),
            ),
          ],
        ),
      );
    }

    // Standard secondary bar
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: NextvColors.background,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Provider dropdown
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderManagerScreen()));
              _loadCategories();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NextvColors.accent.withOpacity(0.15),
                border: Border.all(color: NextvColors.accent, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns, size: 14, color: NextvColors.accent),
                  const SizedBox(width: 6),
                  Text(ref.watch(currentProviderName), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Category dropdown
          PopupMenuButton<LiveCategory>(
            onSelected: (cat) {
              ref.read(currentCategoryName.notifier).state = cat.categoryName;
              _loadStreams(cat.categoryId);
            },
            itemBuilder: (context) => filteredCategories.map((c) => PopupMenuItem(
              value: c,
              child: Text(c.categoryName),
            )).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NextvColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(currentCat, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const Spacer(),
          // EPG & Category buttons
          OutlinedButton.icon(
            onPressed: () => _showFullEPG(context),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(tr('show_full_epg')),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showCategoryFilter(context),
            icon: const Icon(Icons.category, size: 16),
            label: Text(tr('add_remove_categories')),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
          ),
        ],
      ),
    );
  }

  // ========== SIDEBAR (Channel list with live/dead indicator) ==========
  Widget _buildSidebar(String Function(String) tr) {
    final streams = ref.watch(streamsProvider);
    final currentStream = ref.watch(currentStreamProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final currentCat = ref.watch(currentCategoryName);
    final parentalSettings = ref.watch(parentalProvider);
    final categories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);
    final loadError = ref.watch(loadErrorProvider);

    final categoryMap = {for (var c in categories) c.categoryId: c.categoryName};

    final filteredStreams = _searchQuery.isEmpty
        ? streams.where((s) => !parentalSettings.enabled || !parentalSettings.blockedCategories.contains(categoryMap[s.categoryId] ?? '')).toList()
        : streams.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            (!parentalSettings.enabled || !parentalSettings.blockedCategories.contains(categoryMap[s.categoryId] ?? ''))
          ).toList();

    if (settings.tvMode) {
      return Container(
        width: 320,
        decoration: const BoxDecoration(
          color: NextvColors.surface,
          border: Border(right: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing ${tr('all_categories')} from ${ref.watch(currentProviderName)}',
                      style: const TextStyle(fontSize: 14, color: Colors.white54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TvModeButton(
                    icon: Icons.chevron_left,
                    label: 'Back',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TvModeCard(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: tr('search_channels'),
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.white38),
                    filled: true,
                    fillColor: NextvColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Provider label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ref.watch(currentProviderName),
                style: const TextStyle(fontSize: 12, color: NextvColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
            // Channel list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : loadError != null
                    ? _buildErrorWidget(loadError, tr)
                    : filteredStreams.isEmpty
                      ? const Center(child: Text('No hay canales', style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                      itemCount: filteredStreams.length,
                      itemBuilder: (context, index) {
                        final stream = filteredStreams[index];
                        final isPlaying = currentStream?.streamId == stream.streamId;
                        return TvModeListTile(
                          icon: stream.streamIcon.isNotEmpty
                              ? Image.network(stream.streamIcon, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 24))
                              : const Icon(Icons.tv, size: 24),
                          title: stream.name,
                          subtitle: currentCat,
                          selected: isPlaying,
                          onTap: () { _autoSkipCount = 0; _playStream(stream); },
                          trailing: TvModeButton(
                            icon: Icons.star_border,
                            label: 'Favorite',
                            onPressed: () {},
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    // Standard sidebar
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${tr('all_categories')} from ${ref.watch(currentProviderName)}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_left, size: 18),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: tr('search_channels'),
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                filled: true,
                fillColor: NextvColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Provider label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              ref.watch(currentProviderName),
              style: const TextStyle(fontSize: 10, color: NextvColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
          // Channel list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : loadError != null
                  ? _buildErrorWidget(loadError, tr)
                  : filteredStreams.isEmpty
                    ? const Center(child: Text('No hay canales', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                    itemCount: filteredStreams.length,
                    itemBuilder: (context, index) {
                      final stream = filteredStreams[index];
                      final isPlaying = currentStream?.streamId == stream.streamId;
                      return ListTile(
                        dense: true,
                        selected: isPlaying,
                        selectedTileColor: NextvColors.accent.withOpacity(0.15),
                        leading: SizedBox(
                          width: 32,
                          height: 24,
                          child: stream.streamIcon.isNotEmpty
                              ? Image.network(stream.streamIcon, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 18))
                              : const Icon(Icons.tv, size: 18),
                        ),
                        title: Row(
                          children: [
                            // Live indicator
                            if (isPlaying)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: _isCheckingChannel ? Colors.yellow : (_isChannelLive ? Colors.green : Colors.red),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                stream.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isPlaying ? NextvColors.accent : Colors.white,
                                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          currentCat,
                          style: const TextStyle(fontSize: 10, color: Colors.white38),
                        ),
                        trailing: FavoriteButton(
                          stream: stream,
                          size: 18,
                        ),
                        onTap: () { _autoSkipCount = 0; _playStream(stream); },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ========== MAIN AREA (Player) ==========
  Widget _buildMainArea(String Function(String) tr, AppSettings settings) {
    final currentStream = ref.watch(currentStreamProvider);

    return Column(
      children: [
        // Banner (hidden in fullscreen)
        if (!_isFullscreen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: NextvColors.accent,
            child: const Center(
              child: Text('NeXTV - PREMIUM STREAMING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        // Player area
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Video player
                Center(
                  child: currentStream == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.live_tv, size: 64, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(tr('no_channel_selected'), style: const TextStyle(color: Colors.white38)),
                          ],
                        )
                      : _playbackError != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.warning_amber, size: 48, color: Colors.amber),
                                const SizedBox(height: 16),
                                Text(tr('video_error'), style: const TextStyle(color: Colors.white)),
                                const SizedBox(height: 8),
                                Text(_playbackError!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () { _autoSkipCount = 0; _playStream(currentStream); },
                                  child: Text(tr('retry')),
                                ),
                              ],
                            )
                          : settings.playerType == 'vlc' && _vlcPlayerController != null
                              ? VlcPlayer(
                                  controller: _vlcPlayerController!,
                                  aspectRatio: 16 / 9,
                                  placeholder: const Center(child: CircularProgressIndicator()),
                                )
                              : _betterPlayerController != null
                                  ? BetterPlayer(controller: _betterPlayerController!)
                                  : const CircularProgressIndicator(),
                ),
                // Professional badges overlay (hidden in fullscreen — shown in bottom bar instead)
                if (currentStream != null && !_isFullscreen) ...[
                  // LIVE badge (top-left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: AnimatedOpacity(
                      opacity: _badgeOpacityAnimation.value,
                      duration: const Duration(milliseconds: 300),
                      child: const ProBadge(
                        text: 'LIVE',
                        icon: Icons.live_tv,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  // Quality badge (top-right)
                  if (_currentQuality != null && _currentQuality != 'auto')
                    Positioned(
                      top: 16,
                      right: 16,
                      child: AnimatedOpacity(
                        opacity: _badgeOpacityAnimation.value,
                        duration: const Duration(milliseconds: 300),
                        child: ProBadge(
                          text: _currentQuality!.toUpperCase(),
                          icon: _currentQuality == '4k' ? Icons.hd : Icons.high_quality,
                          color: NextvColors.accent,
                        ),
                      ),
                    ),
                  // Trust Signals - Channel Verification (top-center)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _badgeOpacityAnimation.value,
                        duration: const Duration(milliseconds: 300),
                        child: VerificationBadge(
                          isVerified: _isChannelLive,
                          verifiedText: 'VERIFIED',
                          unverifiedText: 'CHECKING',
                        ),
                      ),
                    ),
                  ),
                  // Recording badge (bottom-left)
                  if (_isRecording)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: AnimatedOpacity(
                        opacity: _badgeOpacityAnimation.value,
                        duration: const Duration(milliseconds: 300),
                        child: const ProBadge(
                          text: 'REC',
                          icon: Icons.videocam,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  // Trust Signals - Connection Trust (bottom-right)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: AnimatedOpacity(
                      opacity: _badgeOpacityAnimation.value,
                      duration: const Duration(milliseconds: 300),
                      child: TrustBadge(
                        label: 'SECURE',
                        icon: Icons.verified_user,
                        level: ref.watch(settingsProvider).vpnEnabled
                            ? TrustLevel.verified
                            : TrustLevel.warning,
                        tooltip: ref.watch(settingsProvider).vpnEnabled
                            ? 'Connection is protected by VPN'
                            : 'Enable VPN for secure streaming',
                      ),
                    ),
                  ),
                ],
                // Disclaimer banner (live TV only, auto-dismiss)
                if (ref.watch(selectedTabProvider) == 0 && _showDisclaimer && !_isFullscreen)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _showDisclaimer = false),
                      child: AnimatedOpacity(
                        opacity: _showDisclaimer ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            border: Border(top: BorderSide(color: NextvColors.accent.withOpacity(0.4), width: 1)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: NextvColors.accent.withOpacity(0.7), size: 14),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'NeXtv does not provide any content. Streams are delivered by your IPTV service provider.',
                                  style: TextStyle(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ),
                              Icon(Icons.close, color: Colors.white38, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Change feedback overlay (bottom-center)
                if (_changeFeedbackMessage != null)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ChangeFeedback(message: _changeFeedbackMessage!, color: Colors.blue),
                    ),
                  ),
                // EPG overlay (full screen)
                if (currentStream != null)
                  Builder(builder: (context) {
                    final api = ref.read(xtreamAPIProvider);
                    final pm = ref.read(providerManagerProvider);
                    final creds = api.credentials;
                    return EPGOverlay(
                      stream: currentStream,
                      serverUrl: creds?.serverUrl ?? '',
                      username: creds?.username ?? '',
                      password: creds?.password ?? '',
                      isVisible: _isEPGOverlayVisible,
                      onDismiss: _hideEPGOverlay,
                    );
                  }),
                // Professional Player Controls overlay
                if (currentStream != null && _playbackError == null)
                  PlayerControls(
                    isPlaying: _isPlaying,
                    isFullscreen: _isFullscreen,
                    volume: _volume,
                    currentQuality: _currentQuality ?? 'auto',
                    position: _position,
                    duration: _duration,
                    onPlayPause: _onPlayPause,
                    onVolumeChanged: _onVolumeChanged,
                    onQualityChanged: _onQualityChanged,
                    onFullscreenToggle: _onFullscreenToggle,
                    onSeek: _onSeek,
                    onRewind: _onRewind,
                    onFastForward: _onFastForward,
                  ),
              ],
            ),
          ),
        ),
        // Legacy controls (minimal fallback)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: NextvColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentStream != null)
                IconButton(
                  icon: const Icon(Icons.schedule, color: NextvColors.accent),
                  onPressed: () => _showEPG(currentStream),
                  tooltip: 'EPG & Catch-up',
                ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                icon: const Icon(Icons.hd, color: Colors.white70),
                tooltip: 'Quality',
                onSelected: (quality) => _changeQuality(quality),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'auto', child: Text('Auto')),
                  const PopupMenuItem(value: '4k', child: Text('4K')),
                  const PopupMenuItem(value: 'hd', child: Text('HD')),
                  const PopupMenuItem(value: 'sd', child: Text('SD')),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.videocam,
                  color: _isRecording ? Colors.red : Colors.white70,
                ),
                onPressed: () => _startRecording(),
                tooltip: _isRecording ? 'Stop Recording' : 'Record Stream',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== BOTTOM BAR (Now/Next EPG) ==========
  Widget _buildBottomBar(String Function(String) tr) {
    final currentStream = ref.watch(currentStreamProvider);
    final settings = ref.watch(settingsProvider);

    if (settings.tvMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: NextvColors.surface,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: TvModeCard(
          child: Row(
            children: [
              // Current channel info with live indicator
              Expanded(
                child: Row(
                  children: [
                    // Trust Signals - Live Status with enhanced indicator
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: _isCheckingChannel
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _isChannelLive ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isChannelLive ? Colors.green : Colors.red).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const Icon(Icons.tv, size: 24, color: NextvColors.accent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentStream?.name ?? 'No channel selected',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Trust Signals - Channel Trust Badge
                              if (currentStream != null) ...[
                                const SizedBox(width: 12),
                                TrustBadge(
                                  label: _isChannelLive ? 'LIVE' : 'OFFLINE',
                                  icon: _isChannelLive ? Icons.verified : Icons.warning,
                                  level: _isChannelLive ? TrustLevel.verified : TrustLevel.danger,
                                  tooltip: _isChannelLive
                                      ? 'Channel is live and verified'
                                      : 'Channel is currently offline',
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _isChannelLive ? tr('channel_live') : tr('channel_offline'),
                            style: TextStyle(fontSize: 12, color: _isChannelLive ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // EPG Button for TV Mode
              TvModeButton(
                icon: Icons.schedule,
                label: 'EPG',
                onPressed: currentStream != null ? () => _showEPG(currentStream) : () {},
              ),
              const SizedBox(width: 8),
              // Subtitles selection button for TV Mode
              TvModeButton(
                icon: Icons.closed_caption,
                label: 'Subtitles',
                onPressed: currentStream != null ? () => _showSubtitleSelection() : () {},
              ),
            ],
          ),
        ),
      );
    }

    // Standard bottom bar
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: NextvColors.surface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Current channel info with live indicator
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NextvColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // Trust Signals - Live Status with enhanced indicator
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: _isCheckingChannel
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1),
                          )
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isChannelLive ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isChannelLive ? Colors.green : Colors.red).withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                  ),
                  const Icon(Icons.tv, size: 20, color: NextvColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentStream?.name ?? 'No channel selected',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Trust Signals - Channel Trust Badge
                            if (currentStream != null) ...[
                              const SizedBox(width: 8),
                              TrustBadge(
                                label: _isChannelLive ? 'LIVE' : 'OFFLINE',
                                icon: _isChannelLive ? Icons.verified : Icons.warning,
                                level: _isChannelLive ? TrustLevel.verified : TrustLevel.danger,
                                tooltip: _isChannelLive
                                    ? 'Channel is live and verified'
                                    : 'Channel is currently offline',
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _isChannelLive ? tr('channel_live') : tr('channel_offline'),
                              style: TextStyle(fontSize: 10, color: _isChannelLive ? Colors.green : Colors.red),
                            ),
                            // Trust Signals - Connection Quality
                            if (_isChannelLive) ...[
                              const SizedBox(width: 8),
                              const TrustBadge(
                                label: 'HD',
                                icon: Icons.high_quality,
                                level: TrustLevel.secure,
                                tooltip: 'High quality stream available',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 20),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.closed_caption, color: Colors.white70),
                    onPressed: _showSubtitleSelection,
                    tooltip: 'Subtitles',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, String Function(String) tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadCategories(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NextvColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir nueva lista'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParentalModal() {
    showDialog(
      context: context,
      builder: (context) => const ParentalControlModal(),
    );
  }

  void _showEPG(LiveStream stream) {
    setState(() {
      _isEPGOverlayVisible = true;
    });
  }

  /// Show subtitle selection dialog for current player (BetterPlayer or VLC)
  void _showSubtitleSelection() async {
    final currentStream = ref.read(currentStreamProvider);
    if (currentStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un canal primero')));
      return;
    }

    // BetterPlayer path
    if (_betterPlayerController != null) {
      try {
        final sources = _betterPlayerController!.betterPlayerSubtitlesSourceList ?? [];
        final items = <Map<String, dynamic>>[];
        items.add({'id': -1, 'label': 'Off'});
        for (var i = 0; i < sources.length; i++) {
          final s = sources[i];
          final label = s.name ?? (s.urls != null && s.urls!.isNotEmpty ? s.urls!.first : 'Track $i');
          items.add({'id': i, 'label': label});
        }

        final choice = await showDialog<int>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Select Subtitles'),
            children: items.map((it) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, it['id'] as int),
              child: Text(it['label'] as String),
            )).toList(),
          ),
        );

        if (choice == null) return;
        if (choice < 0) {
          _betterPlayerController!.setupSubtitleSource(
            BetterPlayerSubtitlesSource(type: BetterPlayerSubtitlesSourceType.none),
          );
        } else {
          final src = sources[choice];
          _betterPlayerController!.setupSubtitleSource(src);
        }
        _showFeedback('Subtitles updated', Colors.blue);
      } catch (e) {
        debugPrint('Subtitle selection error (BetterPlayer): $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al seleccionar subtítulos')));
      }
      return;
    }

    // VLC path
    if (_vlcPlayerController != null) {
      try {
        final tracks = await _vlcPlayerController!.getSpuTracks();
        final items = <Map<String, dynamic>>[];
        items.add({'id': -1, 'label': 'Off'});
        tracks.forEach((k, v) { items.add({'id': k, 'label': v}); });

        final choice = await showDialog<int>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Select Subtitles'),
            children: items.map((it) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, it['id'] as int),
              child: Text(it['label'] as String),
            )).toList(),
          ),
        );

        if (choice == null) return;
        if (choice < 0) {
          await _vlcPlayerController!.setSpuTrack(-1);
        } else {
          await _vlcPlayerController!.setSpuTrack(choice);
        }
        _showFeedback('Subtitles updated', Colors.blue);
      } catch (e) {
        debugPrint('Subtitle selection error (VLC): $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al seleccionar subtítulos')));
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No player available')));
  }

  void _hideEPGOverlay() {
    setState(() {
      _isEPGOverlayVisible = false;
    });
  }

  void _changeQuality(String quality) {
    setState(() {
      _currentQuality = quality;
      _showFeedback('Calidad: ${quality.toUpperCase()}', Colors.blue);
    });

    // Update stream mode based on quality
    String mode;
    switch (quality) {
      case '4k':
        mode = '4k';
        break;
      case 'hd':
        mode = 'hd';
        break;
      case 'sd':
        mode = 'sd';
        break;
      default:
        mode = 'auto';
    }
    ref.read(streamModeProvider.notifier).state = mode;
    // Re-play current stream with new quality
    final currentStream = ref.read(currentStreamProvider);
    if (currentStream != null) {
      _playStream(currentStream);
    }
  }

  // PlayerControls callback methods
  void _onPlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_betterPlayerController != null) {
      if (_isPlaying) {
        _betterPlayerController!.play();
      } else {
        _betterPlayerController!.pause();
      }
    } else if (_vlcPlayerController != null) {
      if (_isPlaying) {
        _vlcPlayerController!.play();
      } else {
        _vlcPlayerController!.pause();
      }
    }
    _showFeedback(_isPlaying ? 'Reproduciendo' : 'Pausado', Colors.green);
  }

  void _onVolumeChanged(double volume) {
    setState(() => _volume = volume);
    if (_betterPlayerController != null) {
      _betterPlayerController!.setVolume(volume);
    } else if (_vlcPlayerController != null) {
      _vlcPlayerController!.setVolume((volume * 100).toInt());
    }
  }

  void _onQualityChanged(String quality) {
    _changeQuality(quality);
  }

  void _onFullscreenToggle() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _onSeek(Duration position) {
    if (_betterPlayerController != null) {
      _betterPlayerController!.seekTo(position);
    } else if (_vlcPlayerController != null) {
      _vlcPlayerController!.seekTo(Duration(milliseconds: (position.inMilliseconds / 1000).toInt()));
    }
  }

  void _onRewind() {
    final currentPosition = _position ?? Duration.zero;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _onSeek(newPosition < Duration.zero ? Duration.zero : newPosition);
    _showFeedback('Retroceder 10s', Colors.blue);
  }

  void _onFastForward() {
    final currentPosition = _position ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final maxPosition = _duration ?? const Duration(hours: 24);
    _onSeek(newPosition > maxPosition ? maxPosition : newPosition);
    _showFeedback('Avanzar 10s', Colors.blue);
  }

  void _showFeedback(String message, Color color) {
    setState(() => _changeFeedbackMessage = message);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _changeFeedbackMessage = null);
      }
    });
  }

  void _startRecording() async {
    final currentStream = ref.read(currentStreamProvider);
    if (currentStream == null) return;

    if (_isRecording) {
      // Stop recording
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording stopped')),
      );
      return;
    }

    // Request storage permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission required for recording')),
      );
      return;
    }

    // Start recording
    setState(() => _isRecording = true);
    
    try {
      final directory = await getExternalStorageDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${currentStream.name.replaceAll(RegExp(r'[^\w\s]'), '')}_$timestamp.mp4';
      _recordingPath = '${directory?.path}/$filename';

      // For demo, just show message. Real recording would require native implementation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording started: $filename')),
      );
    } catch (e) {
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  void _generatePlaylist(String type, String value) async {
    final streams = ref.read(streamsProvider);
    final categories = ref.read(categoriesProvider);
    
    if (streams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No streams available')),
      );
      return;
    }

    try {
      String content;
      String filename;
      
      switch (type) {
        case 'country':
          content = await PlaylistGenerator.generatePlaylistByCountry(
            streams, categories, value, value,
          );
          filename = 'playlist_$value';
          break;
        case 'language':
          content = await PlaylistGenerator.generatePlaylistByLanguage(streams, value);
          filename = 'playlist_$value';
          break;
        default:
          return;
      }

      final path = await PlaylistGenerator.savePlaylist(content, filename);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist saved: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate playlist: $e')),
      );
    }
  }

  void _playCustomUrl(String url) async {
    // For demo, just show the URL. In real implementation, this would play the custom URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing custom URL: $url')),
    );
  }
}
