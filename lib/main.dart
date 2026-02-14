import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:device_preview/device_preview.dart';
import 'core/constants/nextv_colors.dart';
import 'core/models/playlist_model.dart';
import 'core/models/xtream_models.dart';
import 'core/providers/active_playlist_provider.dart';
import 'core/providers/favorites_provider.dart';
import 'core/services/playlist_manager.dart';
import 'core/services/provider_manager.dart';
import 'core/services/xtream_api_service.dart';
import 'presentation/screens/landing_screen.dart';
import 'presentation/screens/nova_main_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/provider_manager_screen.dart';
import 'presentation/screens/playlist_selector_screen.dart';
import 'presentation/widgets/nextv_logo.dart';
import 'presentation/platform_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for desktop + iOS (iOS needs it for MKV movie playback)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isIOS)) {
    media_kit.MediaKit.ensureInitialized();
  }

  // Force BetterPlayer as default - VLC plugin has init issues
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('player_type') == 'vlc' || !prefs.containsKey('player_type')) {
    await prefs.setString('player_type', 'better');
    await prefs.setString('preferred_player', 'better_player');
  }
  // Device Preview: solo activo en debug, cambiar a true para probar UI en otros dispositivos
  const bool enableDevicePreview = false;

  runApp(
    DevicePreview(
      enabled: enableDevicePreview && kDebugMode,
      builder: (context) => ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const XuperApp(),
      ),
    ),
  );
}

class XuperApp extends StatelessWidget {
  const XuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeXTV',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: NextvColors.accent,
        scaffoldBackgroundColor: NextvColors.background,
        cardColor: NextvColors.surface,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: NextvColors.accent,
          secondary: NextvColors.accentBright,
          surface: NextvColors.surface,
        ),
      ),
      home: const StartupScreen(),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/dashboard': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/player': (context) => const NovaMainScreen(),
        '/providers': (context) => const ProviderManagerScreen(),
        '/playlist-selector': (context) => const PlaylistSelectorScreen(),
      },
    );
  }
}

/// Startup screen with automatic fallback chain
class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  String _statusMessage = 'Cargando...';
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _hasFailed = false;
      _statusMessage = 'Cargando listas guardadas...';
    });

    try {
      // Add timeout to prevent infinite hanging
      final playlistManager = ref.read(playlistManagerProvider.notifier);
      await playlistManager.loadPlaylists().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Playlist loading timed out - falling back to login');
          throw TimeoutException('Playlist loading timed out');
        },
      );

      final playlists = ref.read(playlistManagerProvider);

      if (!mounted) return;

      if (playlists.isEmpty) {
        // No saved playlists → go to login
        Navigator.of(context).pushReplacementNamed('/login');
      } else if (playlists.length == 1) {
        // Exactly one playlist → auto-connect directly
        await _autoConnect(playlists.first);
      } else {
        // Multiple playlists → show selector
        Navigator.of(context).pushReplacementNamed('/playlist-selector');
      }
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
      if (!mounted) return;

      // On error, go to login screen (fresh start)
      setState(() {
        _statusMessage = 'Error al cargar datos. Iniciando sesión...';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  /// Auto-connect to a single saved playlist (skip selector)
  Future<void> _autoConnect(Playlist playlist) async {
    final pm = ref.read(providerManagerProvider);
    final api = ref.read(xtreamAPIProvider);

    setState(() => _statusMessage = 'Conectando a ${playlist.name}...');

    // Set Xtream credentials if available
    if (playlist.type == 'xtream') {
      final creds = playlist.toXtreamCredentials;
      if (creds != null) api.setCredentials(creds);
    } else if (playlist.m3uUrl != null) {
      // Auto-detect Xtream from M3U URL
      try {
        final uri = Uri.parse(playlist.m3uUrl!);
        final username = uri.queryParameters['username'];
        final password = uri.queryParameters['password'];
        if (username != null && password != null) {
          final serverUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
          api.setCredentials(XtreamCredentials(
            serverUrl: serverUrl,
            username: username,
            password: password,
          ));
        }
      } catch (_) {}
    }

    final result = await pm.connectToProvider(playlist);

    if (!mounted) return;

    debugPrint('🔍 Connection result: success=${result.success}, error=${result.error}');

    if (result.success) {
      ref.read(activePlaylistProvider.notifier).state = playlist;
      ref.read(currentProviderName.notifier).state = result.providerName;

      if (result.categories.isNotEmpty) {
        ref.read(categoriesProvider.notifier).state = result.categories;
        ref.read(currentCategoryName.notifier).state =
            result.categories.first.categoryName;
      }
      if (result.streams.isNotEmpty) {
        ref.read(streamsProvider.notifier).state = result.streams;
      }

      debugPrint('🚀 Navigating to PlatformRouter (auto-detects iOS/Android/Desktop)...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlatformRouter()),
      );
    } else {
      setState(() {
        _hasFailed = true;
        _statusMessage = result.error ?? 'Error desconocido';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NextvLogo(
              size: 150.0,
              showText: true,
              withGlow: true,
            ),
            const SizedBox(height: 16),
            Text(
              'PREMIUM STREAMING',
              style: TextStyle(
                fontSize: 14,
                color: NextvColors.textSecondary.withOpacity(0.5),
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 48),
            if (!_hasFailed)
              const CircularProgressIndicator(color: NextvColors.accent),
            if (_hasFailed)
              const Icon(Icons.error_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: NextvColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            if (_hasFailed) ...[
              const SizedBox(height: 24),
              // Primary: Retry connection
              ElevatedButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NextvColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary: Manage existing providers
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/providers'),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Gestionar Proveedores'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NextvColors.accentBright,
                  side: const BorderSide(color: NextvColors.accentSoft),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              // Tertiary: Add new provider
              TextButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir nueva lista'),
                style: TextButton.styleFrom(foregroundColor: NextvColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
