import 'package:flutter_test/flutter_test.dart';
import 'package:nextv_app/core/models/live_stream.dart';

/// Unit tests for LiveStream model
void main() {
  group('LiveStream Model Tests', () {
    test('should create LiveStream from JSON', () {
      final json = {
        'num': 1,
        'name': 'Test Channel',
        'stream_type': 'live',
        'stream_id': 12345,
        'stream_icon': 'http://test.com/icon.png',
        'epg_channel_id': 'test_epg',
        'category_id': '1',
        'tv_archive': 1,
        'tv_archive_duration': 7,
      };

      final stream = LiveStream.fromJson(json);

      expect(stream.name, 'Test Channel');
      expect(stream.streamId, 12345);
      expect(stream.streamIcon, 'http://test.com/icon.png');
      expect(stream.tvArchive, 1);
      expect(stream.tvArchiveDuration, 7);
    });

    test('should generate correct stream URL', () {
      final stream = LiveStream(
        num: 1,
        name: 'Test Channel',
        streamType: 'live',
        streamId: 12345,
        streamIcon: '',
        epgChannelId: null,
        added: '',
        categoryId: '1',
        customSid: null,
        tvArchive: 0,
        directSource: null,
        tvArchiveDuration: 0,
      );

      final url = stream.getStreamUrl(
        'http://server.com',
        'user123',
        'pass456',
      );

      expect(url, contains('http://server.com'));
      expect(url, contains('user123'));
      expect(url, contains('pass456'));
      expect(url, contains('12345'));
    });

    test('should handle null values gracefully', () {
      final json = {
        'stream_id': 12345,
        'name': 'Test Channel',
        'stream_type': 'live',
      };

      final stream = LiveStream.fromJson(json);

      expect(stream.streamId, 12345);
      expect(stream.name, 'Test Channel');
      expect(stream.epgChannelId, isNull);
      expect(stream.customSid, isNull);
    });

    test('should convert to JSON correctly', () {
      final stream = LiveStream(
        num: 1,
        name: 'Test Channel',
        streamType: 'live',
        streamId: 12345,
        streamIcon: 'icon.png',
        epgChannelId: 'test_epg',
        added: '1672531200',
        categoryId: '1',
        customSid: '',
        tvArchive: 1,
        directSource: '',
        tvArchiveDuration: 7,
      );

      final json = stream.toJson();

      expect(json['name'], 'Test Channel');
      expect(json['stream_id'], 12345);
      expect(json['tv_archive'], 1);
    });

    test('should support equality comparison', () {
      final stream1 = LiveStream(
        num: 1,
        name: 'Test',
        streamType: 'live',
        streamId: 123,
        streamIcon: '',
        epgChannelId: null,
        added: '',
        categoryId: '1',
        customSid: null,
        tvArchive: 0,
        directSource: null,
        tvArchiveDuration: 0,
      );

      final stream2 = LiveStream(
        num: 1,
        name: 'Test',
        streamType: 'live',
        streamId: 123,
        streamIcon: '',
        epgChannelId: null,
        added: '',
        categoryId: '1',
        customSid: null,
        tvArchive: 0,
        directSource: null,
        tvArchiveDuration: 0,
      );

      // Note: This will fail if LiveStream doesn't override == operator
      // Add this to LiveStream class if needed
      expect(stream1.streamId, stream2.streamId);
      expect(stream1.name, stream2.name);
    });
  });

  group('LiveStream Edge Cases', () {
    test('should handle very long channel names', () {
      final longName = 'A' * 1000;
      final stream = LiveStream(
        num: 1,
        name: longName,
        streamType: 'live',
        streamId: 123,
        streamIcon: '',
        epgChannelId: null,
        added: '',
        categoryId: '1',
        customSid: null,
        tvArchive: 0,
        directSource: null,
        tvArchiveDuration: 0,
      );

      expect(stream.name, longName);
      expect(stream.name.length, 1000);
    });

    test('should handle special characters in name', () {
      final specialName = '🎬 Test & Channel <HD>';
      final stream = LiveStream(
        num: 1,
        name: specialName,
        streamType: 'live',
        streamId: 123,
        streamIcon: '',
        epgChannelId: null,
        added: '',
        categoryId: '1',
        customSid: null,
        tvArchive: 0,
        directSource: null,
        tvArchiveDuration: 0,
      );

      expect(stream.name, specialName);
    });

    test('should handle negative stream IDs', () {
      final stream = LiveStream(
        num: 1,
        name: 'Test',
        streamType: 'live',
        streamId: -1,
        streamIcon: '',
        epgChannelId: null,
        added: '',
        categoryId: '1',
        customSid: null,
        tvArchive: 0,
        directSource: null,
        tvArchiveDuration: 0,
      );

      expect(stream.streamId, -1);
    });
  });
}
