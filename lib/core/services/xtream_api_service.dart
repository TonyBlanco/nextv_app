// TB Cinema - Xtream Codes API Service
// This replicates the core functionality of IPTV Smarters Pro

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/xtream_models.dart';

final xtreamAPIProvider = Provider((ref) => XtreamAPIService());

class XtreamAPIService {
  final Dio _dio;
  XtreamCredentials? _credentials;
  String? _authenticatedUserAgent; // Store the User-Agent that worked

  XtreamAPIService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
    headers: {
      if (!kIsWeb) 'User-Agent': 'IPTV Smarters Pro/3.0.9.4',
      'Accept': 'application/json, text/plain, */*',
      if (!kIsWeb) 'Accept-Encoding': 'gzip, deflate',
      if (!kIsWeb) 'Connection': 'keep-alive',
    },
    // Accept non-standard status codes (some IPTV servers return invalid codes like 884)
    validateStatus: (status) {
      // Accept any status code - we'll handle validation in the response
      return status != null;
    },
  ));

  String _formatDioError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status != null) {
        // Handle non-standard status codes (outside 100-599 range)
        if (status < 100 || status >= 600) {
          return 'El servidor devolvió un código de estado no estándar ($status). '
              'Esto suele indicar un problema con el servidor IPTV. '
              'Intenta de nuevo o contacta al proveedor del servicio.';
        }
        if (status >= 500) {
          return 'Server error ($status) — el servidor falló al procesar la petición. Intenta de nuevo más tarde o verifica la URL del servidor.';
        } else if (status >= 400) {
          return 'Error de cliente ($status) — comprueba las credenciales y la URL.';
        }
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Tiempo de espera agotado al conectar con el servidor. Verifica tu conexión o intenta más tarde.';
      }
      return 'Error de red: ${e.message}';
    }
    return e.toString();
  }

  // Initialize with credentials
  void setCredentials(XtreamCredentials credentials) {
    _credentials = credentials;
  }

  String _buildUrl([String? action]) {
    if (_credentials == null) {
      throw Exception('Credentials not set');
    }
    var url = '${_credentials!.serverUrl}/player_api.php?'
        'username=${_credentials!.username}&'
        'password=${_credentials!.password}';
    if (action != null) {
      url += '&action=$action';
    }
    return url;
  }

  // Authenticate and get user info
  Future<Map<String, dynamic>> authenticate() async {
    // Lista de User-Agents populares de players IPTV para probar
    final userAgents = [
      'smartersplayer', // IPTV Smarters Pro format
      'IPTV Smarters Pro/3.0.9.4',
      'TiviMate/4.4.0',
      'Perfect Player/1.5.10',
      'IPTV/1.0',
    ];

    Map<String, dynamic>? lastError;
    
    // Probar cada User-Agent hasta que uno funcione
    for (final userAgent in userAgents) {
      try {
        debugPrint('🔐 Trying authentication with: ${_credentials?.serverUrl}');
        debugPrint('👤 User-Agent: $userAgent');
        
        final url = _buildUrl(); // No 'action' parameter - server doesn't use it
        debugPrint('📡 Full URL: $url');
        
        final response = await _dio.get(
          url,
          options: Options(
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
            headers: {
              if (!kIsWeb) 'User-Agent': userAgent,
              'Accept': 'application/json',
              if (!kIsWeb) 'Accept-Encoding': 'gzip, deflate',
              if (!kIsWeb) 'Connection': 'keep-alive',
            },
          ),
        );
        
        debugPrint('📥 Status: ${response.statusCode}');
        debugPrint('📥 Content-Type: ${response.headers.value('content-type')}');
        debugPrint('📥 Response type: ${response.data.runtimeType}');
        debugPrint('📥 Response length: ${response.data?.toString().length ?? 0}');
        
        // Abort IMMEDIATELY on 403 — server has banned us, retrying makes it worse
        if (response.statusCode == 403) {
          debugPrint('🚫 Server returned 403 (banned/blocked). Aborting ALL retries.');
          return {
            'success': false,
            'error': 'El servidor ha bloqueado temporalmente las solicitudes. Intente más tarde.',
          };
        }
        
        // Check if response is null or empty
        if (response.data == null) {
          debugPrint('⚠️ Response data is null with User-Agent: $userAgent');
          lastError = {'success': false, 'error': 'El servidor no devolvió ningún dato.'};
          continue; // Try next User-Agent
        }
        
        // Debug raw response (first 500 chars)
        final dataStr = response.data.toString();
        debugPrint('📄 Response preview: ${dataStr.length > 500 ? dataStr.substring(0, 500) + "..." : dataStr}');
        
        dynamic data = response.data;
        
        // Check if it's HTML (error page)
        if (data is String) {
          if (data.toLowerCase().contains('<html') || data.toLowerCase().contains('<!doctype')) {
            debugPrint('⚠️ Server returned HTML with User-Agent: $userAgent');
            lastError = {'success': false, 'error': 'El servidor devolvió HTML en lugar de JSON.'};
            continue; // Try next User-Agent
          }
          // Try to parse string as JSON
          try {
            data = jsonDecode(data);
            debugPrint('✅ JSON parsed from string');
          } catch (e) {
            debugPrint('⚠️ Failed to parse JSON with User-Agent: $userAgent - $e');
            lastError = {'success': false, 'error': 'El servidor no devolvió JSON válido.'};
            continue; // Try next User-Agent
          }
        }

        // Check status code
        final statusOk = response.statusCode != null && 
                        (response.statusCode! >= 200 && response.statusCode! < 300);

        if (!statusOk) {
          debugPrint('⚠️ Bad status code: ${response.statusCode} with User-Agent: $userAgent');
          lastError = {'success': false, 'error': 'Error HTTP ${response.statusCode}.'};
          continue; // Try next User-Agent
        }

        if (data is! Map) {
          debugPrint('⚠️ Response is not a Map: ${data.runtimeType} with User-Agent: $userAgent');
          lastError = {'success': false, 'error': 'El servidor devolvió un formato inesperado.'};
          continue; // Try next User-Agent
        }

        final mapData = data as Map<String, dynamic>;
        debugPrint('📥 Response keys: ${mapData.keys.toList()}');
        
        // Check if user_info exists
        if (!mapData.containsKey('user_info')) {
          debugPrint('⚠️ Response missing user_info with User-Agent: $userAgent');
          // Check if there's an error message
          if (mapData.containsKey('message') || mapData.containsKey('error')) {
            final errorMsg = mapData['message'] ?? mapData['error'] ?? 'Usuario o contraseña incorrectos';
            lastError = {'success': false, 'error': 'Servidor: $errorMsg'};
            continue; // Try next User-Agent
          }
          lastError = {'success': false, 'error': 'Usuario o contraseña incorrectos.'};
          continue; // Try next User-Agent
        }

        // Try to parse user_info
        try {
          final userInfo = UserInfo.fromJson(mapData['user_info']);
          final serverInfo = mapData.containsKey('server_info') 
            ? ServerInfo.fromJson(mapData['server_info'])
            : null;

          debugPrint('✅ Authentication successful with User-Agent: $userAgent');
          debugPrint('✅ User: ${userInfo.username}');
          
          // Remember the User-Agent that worked for future API calls
          _authenticatedUserAgent = userAgent;
          if (!kIsWeb) {
            _dio.options.headers['User-Agent'] = userAgent;
          }
          
          // SUCCESS! Return immediately
          return {
            'success': true,
            'userInfo': userInfo,
            'serverInfo': serverInfo,
          };
        } catch (parseError) {
          debugPrint('⚠️ Error parsing user_info with User-Agent: $userAgent - $parseError');
          debugPrint('📄 user_info structure: ${mapData['user_info']}');
          lastError = {'success': false, 'error': 'Error al procesar los datos del servidor: $parseError'};
          continue; // Try next User-Agent
        }
        
      } catch (e) {
        debugPrint('⚠️ Exception with User-Agent: $userAgent - $e');
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout) {
            lastError = {'success': false, 'error': 'Tiempo de espera agotado.'};
          } else if (e.type == DioExceptionType.connectionError) {
            lastError = {'success': false, 'error': 'No se pudo conectar al servidor.'};
          } else {
            lastError = {'success': false, 'error': _formatDioError(e)};
          }
        } else {
          lastError = {'success': false, 'error': e.toString()};
        }
        continue; // Try next User-Agent
      }
    }
    
    // Si llegamos aquí, ningún User-Agent funcionó
    debugPrint('❌ All User-Agents failed');
    return lastError ?? {'success': false, 'error': 'No se pudo autenticar con ningún User-Agent.'};
  }

  // Get Live TV Categories
  Future<List<LiveCategory>> getLiveCategories({Function(int, int)? onProgress}) async {
    try {
      final response = await _dio.get(
        _buildUrl('get_live_categories'),
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => LiveCategory.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting live categories: ${_formatDioError(e)}');
      return [];
    }
  }

  // Get Live Streams by Category
  Future<List<LiveStream>> getLiveStreams({String? categoryId}) async {
    try {
      String url = _buildUrl('get_live_streams');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => LiveStream.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting live streams: ${_formatDioError(e)}');
      return [];
    }
  }

  // Get VOD Categories
  Future<List<VODCategory>> getVODCategories({Function(int, int)? onProgress}) async {
    try {
      final response = await _dio.get(
        _buildUrl('get_vod_categories'),
        onReceiveProgress: onProgress,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => VODCategory.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting VOD categories: ${_formatDioError(e)}');
      return [];
    }
  }

  // Get VOD Streams by Category
  Future<List<VODStream>> getVODStreams({String? categoryId}) async {
    try {
      String url = _buildUrl('get_vod_streams');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => VODStream.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting VOD streams: $e');
      return [];
    }
  }

  // Get VOD Info (movie details)
  Future<VODInfo?> getVODInfo(int vodId) async {
    try {
      final url = '${_buildUrl('get_vod_info')}&vod_id=$vodId';
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data != null) {
        return VODInfo.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      print('Error getting VOD info: $e');
      return null;
    }
  }

  // Get Series Categories
  Future<List<SeriesCategory>> getSeriesCategories({Function(int, int)? onProgress}) async {
    try {
      final response = await _dio.get(
        _buildUrl('get_series_categories'),
        onReceiveProgress: onProgress,
      );
      
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => SeriesCategory.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting series categories: $e');
      return [];
    }
  }

  // Get Series by Category
  Future<List<SeriesItem>> getSeries({String? categoryId}) async {
    try {
      String url = _buildUrl('get_series');
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => SeriesItem.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting series: $e');
      return [];
    }
  }

  // Get Series Info (episodes, seasons)
  Future<SeriesInfo?> getSeriesInfo(int seriesId) async {
    try {
      final url = '${_buildUrl('get_series_info')}&series_id=$seriesId';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return SeriesInfo.fromJson(response.data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting series info: ${_formatDioError(e)}');
      return null;
    }
  }

  // Get EPG for a stream
  Future<List<dynamic>> getEPG(int streamId, {int? limit}) async {
    try {
      String url = '${_buildUrl('get_simple_data_table')}&stream_id=$streamId';
      if (limit != null) {
        url += '&limit=$limit';
      }

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final epgListings = response.data['epg_listings'];
        if (epgListings is List) {
          return epgListings;
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error getting EPG: ${_formatDioError(e)}');
      return [];
    }
  }

  // Build stream URL for playback
  String getLiveStreamUrl(int streamId, {String extension = 'm3u8'}) {
    if (_credentials == null) {
      throw Exception('Credentials not set');
    }
    return '${_credentials!.serverUrl}/live/'
        '${_credentials!.username}/'
        '${_credentials!.password}/'
        '$streamId.$extension';
  }

  String getVODStreamUrl(int streamId, {String extension = 'mp4'}) {
    if (_credentials == null) {
      throw Exception('Credentials not set');
    }
    return '${_credentials!.serverUrl}/movie/'
        '${_credentials!.username}/'
        '${_credentials!.password}/'
        '$streamId.$extension';
  }

  String getSeriesStreamUrl(int seriesId, {String extension = 'mp4'}) {
    if (_credentials == null) {
      throw Exception('Credentials not set');
    }
    return '${_credentials!.serverUrl}/series/'
        '${_credentials!.username}/'
        '${_credentials!.password}/'
        '$seriesId.$extension';
  }

  // Check if service is initialized
  bool get isInitialized => _credentials != null;
  
  XtreamCredentials? get credentials => _credentials;
}
