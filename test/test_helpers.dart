import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Test helpers and utilities for NexTV app testing
class TestHelpers {
  /// Setup mock SharedPreferences for testing
  static Future<void> setupMockSharedPreferences() async {
    SharedPreferences.setMockInitialValues({});
  }

  /// Setup mock Secure Storage for testing
  static FlutterSecureStorage setupMockSecureStorage() {
    // Mock implementation will be added when migrating to secure storage
    return const FlutterSecureStorage();
  }

  /// Create a pump function that waits for animations
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }
}

/// Mock data generators for testing
class MockData {
  static Map<String, dynamic> mockXtreamLogin() {
    return {
      'user_info': {
        'username': 'testuser',
        'password': 'testpass',
        'auth': 1,
        'status': 'Active',
        'exp_date': '1735689600',
        'is_trial': '0',
        'active_cons': '0',
        'created_at': '1672531200',
        'max_connections': '1',
      },
      'server_info': {
        'url': 'http://test.server.com',
        'port': '8080',
        'https_port': '8443',
        'server_protocol': 'http',
        'rtmp_port': '1935',
        'timezone': 'America/New_York',
        'timestamp_now': 1704067200,
        'time_now': '2024-01-01 00:00:00',
      }
    };
  }

  static Map<String, dynamic> mockLiveStream() {
    return {
      'num': 1,
      'name': 'Test Channel',
      'stream_type': 'live',
      'stream_id': 12345,
      'stream_icon': 'http://test.server.com/icon.png',
      'epg_channel_id': 'testchannel',
      'added': '1672531200',
      'category_id': '1',
      'custom_sid': '',
      'tv_archive': 1,
      'direct_source': '',
      'tv_archive_duration': 7,
    };
  }

  static Map<String, dynamic> mockVODInfo() {
    return {
      'info': {
        'name': 'Test Movie',
        'o_name': 'Test Movie Original',
        'cover': 'http://test.server.com/cover.jpg',
        'plot': 'This is a test movie description',
        'cast': 'Actor 1, Actor 2',
        'director': 'Test Director',
        'genre': 'Action',
        'releaseDate': '2024-01-01',
        'duration': '7200',
        'rating': '8.5',
      },
      'movie_data': {
        'stream_id': 67890,
        'name': 'Test Movie',
        'added': '1672531200',
        'category_id': '2',
        'container_extension': 'mp4',
      }
    };
  }

  static Map<String, dynamic> mockSeriesInfo() {
    return {
      'info': {
        'name': 'Test Series',
        'cover': 'http://test.server.com/series_cover.jpg',
        'plot': 'This is a test series description',
        'cast': 'Actor 1, Actor 2',
        'director': 'Test Director',
        'genre': 'Drama',
        'releaseDate': '2024',
        'rating': '9.0',
      },
      'episodes': {
        '1': [
          {
            'id': '11111',
            'episode_num': 1,
            'title': 'Episode 1',
            'container_extension': 'mp4',
            'info': {
              'duration': '3600',
              'plot': 'First episode',
            }
          }
        ]
      },
      'seasons': [
        {'season_number': 1, 'name': 'Season 1', 'episode_count': '10'}
      ]
    };
  }

  static List<Map<String, dynamic>> mockCategories() {
    return [
      {'category_id': '1', 'category_name': 'News', 'parent_id': 0},
      {'category_id': '2', 'category_name': 'Movies', 'parent_id': 0},
      {'category_id': '3', 'category_name': 'Sports', 'parent_id': 0},
    ];
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for checking if a URL is valid
  static Matcher isValidUrl = predicate<String>(
    (url) => Uri.tryParse(url)?.hasAbsolutePath ?? false,
    'is a valid URL',
  );

  /// Matcher for checking if a stream ID is valid
  static Matcher isValidStreamId = predicate<int>(
    (id) => id > 0,
    'is a valid stream ID',
  );
}
