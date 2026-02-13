import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service to validate if a stream URL is accessible before playing
/// This prevents showing broken/slow streams to the user
class StreamValidatorService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    followRedirects: true,
    maxRedirects: 3,
    validateStatus: (status) => status != null && status < 500,
  ));

  /// Quick health check for a stream URL
  /// Returns true if stream is likely playable, false otherwise
  Future<bool> isStreamAccessible(String url) async {
    try {
      debugPrint('🔍 Validating stream: $url');
      
      // For HLS streams (.m3u8), check if the playlist is accessible
      if (url.contains('.m3u8')) {
        final response = await _dio.head(
          url,
          options: Options(
            headers: {
              'User-Agent': 'smartersplayer',
              'Connection': 'keep-alive',
            },
          ),
        ).timeout(const Duration(seconds: 3));

        final isAccessible = response.statusCode == 200 || response.statusCode == 302;
        
        if (isAccessible) {
          debugPrint('✅ Stream accessible: $url');
        } else {
          debugPrint('❌ Stream not accessible (${response.statusCode}): $url');
        }
        
        return isAccessible;
      }
      
      // For other formats, do a quick HEAD request
      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'User-Agent': 'smartersplayer',
          },
        ),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200 || response.statusCode == 302;
      
    } on DioException catch (e) {
      debugPrint('❌ Stream validation failed: ${e.type} - ${e.message}');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Stream validation timeout: $e');
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error validating stream: $e');
      return false;
    }
  }

  /// Validate multiple streams and return only the accessible ones
  /// Useful for filtering a list of channels before displaying
  Future<List<T>> filterAccessibleStreams<T>({
    required List<T> streams,
    required String Function(T) getUrl,
    int maxConcurrent = 5,
  }) async {
    final accessible = <T>[];
    
    // Process streams in batches to avoid overwhelming the network
    for (var i = 0; i < streams.length; i += maxConcurrent) {
      final batch = streams.skip(i).take(maxConcurrent).toList();
      
      final results = await Future.wait(
        batch.map((stream) async {
          final url = getUrl(stream);
          final isAccessible = await isStreamAccessible(url);
          return isAccessible ? stream : null;
        }),
      );
      
      accessible.addAll(results.whereType<T>());
    }
    
    debugPrint('📊 Filtered ${streams.length} streams → ${accessible.length} accessible');
    return accessible;
  }

  void dispose() {
    _dio.close();
  }
}
