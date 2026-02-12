import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/xtream_models.dart';
import '../models/playlist_model.dart';
import '../../utils/m3u_parser.dart';import '../../utils/progressive_m3u_parser.dart';import '../utils/m3u_to_xmltv.dart';
import 'xtream_api_service.dart';

/// Region bundles with local M3U asset files
class StreamRegion {
  final String id;
  final String name;
  final String emoji;
  final List<String> assetFiles;

  const StreamRegion({
    required this.id,
    required this.name,
    required this.emoji,
    required this.assetFiles,
  });
}

/// Built-in stream sources (disabled — users add their own via Xtream / M3U)
class BuiltInSources {
  /// No hardcoded regions — all content comes from user playlists
  static const List<StreamRegion> regions = [];
}

/// Result of a provider connection attempt
class ProviderResult {
  final bool success;
  final String? error;
  final String providerName;
  final List<LiveCategory> categories;
  final List<LiveStream> streams;
  final List<VODCategory> vodCategories;
  final List<SeriesCategory> seriesCategories;
  final String? epgPath;

  ProviderResult({
    required this.success,
    this.error,
    required this.providerName,
    this.epgPath,
    this.categories = const [],
    this.streams = const [],
    this.vodCategories = const [],
    this.seriesCategories = const [],
  });
}

/// Manages multiple providers with automatic fallback
final providerManagerProvider = Provider((ref) => ProviderManager(ref));

class ProviderManager {
  final Ref _ref;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    validateStatus: (status) => status != null && status < 600,
  ));

  String? _activeProviderName;
  String? _activeProviderType; // 'xtream', 'm3u', or 'local'
  String? _activeRegionId;

  // Cached M3U data
  List<M3UEntry>? _cachedM3UEntries;
  List<LiveCategory>? _cachedCategories;
  // Cached generated EPG XML paths by provider name
  final Map<String, String> _cachedEpgPaths = {};

  ProviderManager(this._ref);

  /// Format Dio errors into user-friendly messages
  String _formatDioError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final status = response.statusCode ?? 0;
        if (status >= 500) {
          return 'Error del servidor ($status). El servidor no está disponible o tiene problemas.';
        } else if (status >= 400) {
          return 'Error de solicitud ($status). Verifica la URL o credenciales.';
        }
        return 'HTTP $status: ${error.message ?? "Error desconocido"}';
      }
      
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Tiempo de espera agotado. Verifica tu conexión a internet.';
        case DioExceptionType.connectionError:
          return 'Error de conexión. Verifica tu red o la URL del servidor.';
        case DioExceptionType.badResponse:
          return 'Respuesta inválida del servidor. El servidor puede estar fuera de línea.';
        case DioExceptionType.cancel:
          return 'Solicitud cancelada.';
        default:
          return error.message ?? 'Error de red desconocido';
      }
    }
    return error.toString();
  }

  String get activeProviderName => _activeProviderName ?? 'Sin Proveedor';
  String get activeProviderType => _activeProviderType ?? 'unknown';
  String? get activeRegionId => _activeRegionId;
  String? get activeEpgPath => _activeProviderName != null ? _cachedEpgPaths[_activeProviderName!] : null;

  /// Manually set the active provider name and type without re-authenticating.
  /// Useful when the Xtream API is already initialized via login/dashboard.
  void setActiveProvider({required String name, required String type}) {
    _activeProviderName = name;
    _activeProviderType = type;
    _activeRegionId = null;
    debugPrint('ProviderManager: active provider set to "$name" ($type)');
  }

  /// Regenerate EPG for the currently active provider (if M3U entries cached).
  /// Returns the path to the generated XMLTV file or null on failure.
  Future<String?> regenerateActiveEpg() async {
    final name = _activeProviderName;
    if (name == null) return null;
    if (_cachedM3UEntries == null || _cachedM3UEntries!.isEmpty) return null;

    try {
      final epgPath = await M3UToXMLTV.convertAndCache(_cachedM3UEntries!, name);
      if (epgPath.isNotEmpty) {
        _cachedEpgPaths[name] = epgPath;
        return epgPath;
      }
    } catch (e) {
      debugPrint('regenerateActiveEpg failed: $e');
    }
    return null;
  }

  /// Connect to a SPECIFIC provider without fallbacks (for manual user selection)
  Future<ProviderResult> connectToProvider(Playlist playlist) async {
    debugPrint('Connecting to ${playlist.name} (${playlist.type})...');
    final result = await _tryProvider(playlist);
    if (result.success) {
      debugPrint('✓ Connected to ${playlist.name}');
    } else {
      debugPrint('✗ Failed to connect to ${playlist.name}: ${result.error}');
    }
    return result;
  }

  /// Fallback chain: Saved playlists → Local assets → Remote GitHub
  Future<ProviderResult> connectWithFallback(List<Playlist> playlists) async {
    // Try each saved playlist first
    for (final playlist in playlists) {
      final result = await _tryProvider(playlist);
      if (result.success) return result;
      debugPrint('Provider ${playlist.name} failed: ${result.error}');
    }

    // No hardcoded fallback — user must add their own playlist
    return ProviderResult(
      success: false,
      error: 'No hay listas configuradas. Añade una lista Xtream Codes o M3U.',
      providerName: 'Sin proveedor',
    );
  }

  /// Load a specific region from bundled assets
  Future<ProviderResult> loadRegion(String regionId) async {
    if (BuiltInSources.regions.isEmpty) {
      return ProviderResult(
        success: false,
        error: 'No hay regiones integradas disponibles.',
        providerName: 'Error',
      );
    }
    final region = BuiltInSources.regions.firstWhere(
      (r) => r.id == regionId,
      orElse: () => BuiltInSources.regions.first,
    );

    try {
      final List<M3UEntry> allEntries = [];
      int filesLoaded = 0;

      for (final file in region.assetFiles) {
        try {
          final content = await rootBundle.loadString('streams/$file');
          final entries = M3UParser.parse(content);
          allEntries.addAll(entries);
          filesLoaded++;
          debugPrint('Loaded $file: ${entries.length} channels');
        } catch (e) {
          debugPrint('Failed to load asset streams/$file: $e');
        }
      }

      if (allEntries.isEmpty) {
        return ProviderResult(
          success: false,
          error: 'No channels found in ${region.name}',
          providerName: region.name,
        );
      }

      // Deduplicate by URL
      final seen = <String>{};
      final deduped = <M3UEntry>[];
      for (final entry in allEntries) {
        if (seen.add(entry.url)) {
          deduped.add(entry);
        }
      }

      _cachedM3UEntries = deduped;
      _activeProviderName = '${region.emoji} ${region.name}';
      _activeProviderType = 'local';
      _activeRegionId = regionId;

      // Extract categories
      final categorySet = <String>{};
      for (final entry in deduped) {
        categorySet.add(entry.category ?? 'General');
      }

      final categories = categorySet
          .map((c) => LiveCategory(
                categoryId: c,
                categoryName: c,
                parentId: '0',
              ))
          .toList()
        ..sort((a, b) => a.categoryName.compareTo(b.categoryName));

      final streams = deduped
          .asMap()
          .entries
          .map((e) => e.value.toLiveStream(e.key + 1))
          .toList();

      _cachedCategories = categories;

      debugPrint(
          '✓ ${region.name}: ${deduped.length} channels, ${categories.length} categories, $filesLoaded files');

      return ProviderResult(
        success: true,
        providerName: '${region.emoji} ${region.name}',
        categories: categories,
        streams: streams,
      );
    } catch (e) {
      return ProviderResult(
        success: false,
        error: e.toString(),
        providerName: region.name,
      );
    }
  }

  /// Try connecting to a single Xtream or M3U provider with fallback support
  Future<ProviderResult> _tryProvider(Playlist playlist) async {
    try {
      if (playlist.type == 'xtream') {
        return await _tryXtreamProvider(playlist);
      } else {
        // Try primary M3U URL
        var result = await _tryRemoteM3U(playlist.name, playlist.m3uUrl ?? '');
        
        // If primary fails and fallback exists, try fallback
        if (!result.success && playlist.fallbackUrl != null && playlist.fallbackUrl!.isNotEmpty) {
          debugPrint('⚠ Primary M3U failed, trying fallback URL: ${playlist.fallbackUrl}');
          result = await _tryRemoteM3U('${playlist.name} (Fallback)', playlist.fallbackUrl!);
        }
        
        return result;
      }
    } catch (e) {
      return ProviderResult(
        success: false,
        error: e.toString(),
        providerName: playlist.name,
      );
    }
  }

  Future<ProviderResult> _tryXtreamProvider(Playlist playlist) async {
    final api = _ref.read(xtreamAPIProvider);
    final creds = playlist.toXtreamCredentials;
    if (creds == null) {
      return ProviderResult(
        success: false,
        error: 'Credenciales inválidas',
        providerName: playlist.name,
      );
    }

    // Try primary server
    api.setCredentials(creds);
    var result = await api.authenticate();

    // If primary fails and fallback exists, try fallback
    if (result['success'] != true && playlist.fallbackUrl != null && playlist.fallbackUrl!.isNotEmpty) {
      debugPrint('⚠ Primary server failed, trying fallback URL: ${playlist.fallbackUrl}');
      final fallbackCreds = XtreamCredentials(
        serverUrl: playlist.fallbackUrl!,
        username: creds.username,
        password: creds.password,
      );
      api.setCredentials(fallbackCreds);
      result = await api.authenticate();
    }

    if (result['success'] == true) {
      _activeProviderName = playlist.name;
      _activeProviderType = 'xtream';
      _activeRegionId = null;
      _cachedM3UEntries = null;

      // Load Live categories (REQUIRED - must succeed)
      List<LiveCategory> liveCats = [];
      try {
        liveCats = await api.getLiveCategories();
        debugPrint('✓ Loaded ${liveCats.length} live categories');
      } catch (e) {
        debugPrint('✗ Failed to load live categories: $e');
        return ProviderResult(
          success: false,
          error: 'No se pudieron cargar categorías: $e',
          providerName: playlist.name,
        );
      }

      // Load VOD categories (OPTIONAL - don't fail connection if not available)
      List<VODCategory> vodCats = [];
      try {
        vodCats = await api.getVODCategories();
        debugPrint('✓ Loaded ${vodCats.length} VOD categories');
      } catch (e) {
        debugPrint('⚠ VOD not available: $e');
      }

      // Load Series categories (OPTIONAL - don't fail connection if not available)
      List<SeriesCategory> seriesCats = [];
      try {
        seriesCats = await api.getSeriesCategories();
        debugPrint('✓ Loaded ${seriesCats.length} series categories');
      } catch (e) {
        debugPrint('⚠ Series not available: $e');
      }
      
      // ⚠️ NO CARGAR STREAMS AL INICIO - Se cargan bajo demanda cuando el usuario selecciona una categoría
      // Esto evita out of memory con listas grandes (500+ MB)
      debugPrint('✓ Categories loaded. Streams will be loaded on demand when user selects a category.');

      return ProviderResult(
        success: true,
        providerName: playlist.name,
        categories: liveCats,
        streams: [], // Empty - will be loaded on demand
        vodCategories: vodCats,
        seriesCategories: seriesCats,
      );
    } else {
      // ⚡ NUEVO: Si /player_api.php falla, intentar con /get.php (M3U endpoint)
      final errorMsg = result['error']?.toString() ?? '';
      if (errorMsg.contains('no devolvió ningún dato') || errorMsg.contains('vacío')) {
        debugPrint('⚠️ /player_api.php no disponible. Intentando endpoint M3U (/get.php)...');
        
        // Construir URL M3U con credenciales Xtream
        final m3uUrl = '${creds.serverUrl}/get.php?username=${creds.username}&password=${creds.password}&type=m3u_plus&output=ts';
        
        debugPrint('🔄 Trying M3U fallback: $m3uUrl');
        return await _tryRemoteM3U(playlist.name, m3uUrl);
      }
      
      return ProviderResult(
        success: false,
        error: result['error']?.toString() ?? 'Auth failed',
        providerName: playlist.name,
      );
    }
  }

  /// Try loading a remote M3U URL
  Future<ProviderResult> _tryRemoteM3U(String name, String url) async {
    if (url.isEmpty) {
      return ProviderResult(
        success: false,
        error: 'URL vacía',
        providerName: name,
      );
    }

    try {
      debugPrint('🔽 Loading M3U from: $url');
      debugPrint('📊 Using progressive parser (max 5000 channels)');
      
      // Usar parser progresivo para evitar OOM con M3U grandes
      final parser = ProgressiveM3UParser(
        maxChannels: 5000, // Límite razonable para Android
        onProgress: (count) {
          debugPrint('📊 Parsed $count channels...');
        },
      );
      
      final entries = await parser.parseFromUrl(_dio, url);

      if (entries.isEmpty) {
        return ProviderResult(
          success: false,
          error: 'No se encontraron canales en el M3U',
          providerName: name,
        );
      }

      _cachedM3UEntries = entries;
      _activeProviderName = name;
      _activeProviderType = 'm3u';
      _activeRegionId = null;

      // Try to generate and cache an XMLTV EPG for this M3U provider.
      try {
        final epgPath = await M3UToXMLTV.convertAndCache(entries, name);
        if (epgPath.isNotEmpty) {
          _cachedEpgPaths[name] = epgPath;
        }
      } catch (e) {
        debugPrint('EPG conversion failed for $name: $e');
      }

      final categorySet = <String>{};
      for (final entry in entries) {
        categorySet.add(entry.category ?? 'General');
      }

      final categories = categorySet
          .map((c) => LiveCategory(
                categoryId: c,
                categoryName: c,
                parentId: '0',
              ))
          .toList()
        ..sort((a, b) => a.categoryName.compareTo(b.categoryName));

      final streams = entries
          .asMap()
          .entries
          .map((e) => e.value.toLiveStream(e.key + 1))
          .toList();

      _cachedCategories = categories;

      debugPrint('✅ M3U loaded: ${entries.length} channels, ${categories.length} categories');

      return ProviderResult(
        success: true,
        providerName: name,
        epgPath: _cachedEpgPaths[name],
        categories: categories,
        streams: streams,
      );
    } on OutOfMemoryError catch (e) {
      debugPrint('❌ Out of Memory loading M3U: $e');
      return ProviderResult(
        success: false,
        error: 'La lista M3U es demasiado grande para la memoria disponible. '
               'Solución: Contacta al proveedor para reducir el tamaño de la lista o solicita acceso a Xtream Codes API.',
        providerName: name,
      );
    } catch (e) {
      debugPrint('M3U download error for $name: $e');
      // Check if error message contains "memory" or "allocation"
      String errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('memory') || errorMsg.contains('allocation') || errorMsg.contains('out of')) {
        return ProviderResult(
          success: false,
          error: 'Out of Memory: La lista M3U es demasiado grande. '
                 'Solución: Contacta al proveedor para una lista más pequeña o usa Xtream Codes API.',
          providerName: name,
        );
      }
      return ProviderResult(
        success: false,
        error: _formatDioError(e),
        providerName: name,
      );
    }
  }

  /// Get streams for a category from M3U cache
  List<LiveStream> getM3UStreamsByCategory(String categoryId) {
    if (_cachedM3UEntries == null) return [];

    final filtered = _cachedM3UEntries!
        .where((e) => (e.category ?? 'General') == categoryId)
        .toList();

    return filtered
        .asMap()
        .entries
        .map((e) => e.value.toLiveStream(e.key + 1))
        .toList();
  }

  /// Get all M3U streams (no category filter)
  List<LiveStream> getAllM3UStreams() {
    if (_cachedM3UEntries == null) return [];
    return _cachedM3UEntries!
        .asMap()
        .entries
        .map((e) => e.value.toLiveStream(e.key + 1))
        .toList();
  }

  /// Get the direct stream URL for an M3U entry
  String? getM3UStreamUrl(int streamId) {
    if (_cachedM3UEntries == null) return null;
    final index = streamId - 1;
    if (index < 0 || index >= _cachedM3UEntries!.length) return null;
    return _cachedM3UEntries![index].url;
  }

  /// Get HTTP headers for an M3U entry
  Map<String, String> getM3UStreamHeaders(int streamId) {
    if (_cachedM3UEntries == null) return {};
    final index = streamId - 1;
    if (index < 0 || index >= _cachedM3UEntries!.length) return {};
    return _cachedM3UEntries![index].httpHeaders;
  }

  /// Get cached categories
  List<LiveCategory> get cachedCategories => _cachedCategories ?? [];

  /// Get available regions
  List<StreamRegion> get availableRegions => BuiltInSources.regions;
}
