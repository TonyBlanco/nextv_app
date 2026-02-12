import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../models/xtream_models.dart';

class EPGService {
  final Dio _dio = Dio();
  Map<String, List<EPGProgram>> _programs = {};

  // Fetch EPG from Xtream Codes API
  Future<void> fetchXtreamEPG(String serverUrl, String username, String password, int streamId) async {
    try {
      final url = '$serverUrl/player_api.php?username=$username&password=$password&action=get_epg&stream_id=$streamId';
      final response = await _dio.get(url);
      
      if (response.data is List) {
        final programs = (response.data as List).map((json) => EPGProgram.fromJson(json)).toList();
        _programs[streamId.toString()] = programs;
      }
    } catch (e) {
      print('Error fetching Xtream EPG: $e');
    }
  }

  // Fetch EPG from XMLTV URL
  Future<void> fetchXMLTVEPG(String url) async {
    try {
      final response = await _dio.get(url);
      final document = XmlDocument.parse(response.data);
      final programElements = document.findAllElements('programme');

      _programs = {};

      for (var element in programElements) {
        final channelId = element.getAttribute('channel') ?? '';
        final startStr = element.getAttribute('start') ?? '';
        final stopStr = element.getAttribute('stop') ?? '';
        final title = element.findElements('title').first.text;
        final desc = element.findElements('desc').isNotEmpty 
            ? element.findElements('desc').first.text 
            : 'No description';

        final program = EPGProgram(
          id: '',
          title: title,
          description: desc,
          start: _parseDate(startStr),
          stop: _parseDate(stopStr),
          channelId: channelId,
          hasCatchup: false,
        );

        if (!_programs.containsKey(channelId)) {
          _programs[channelId] = [];
        }
        _programs[channelId]!.add(program);
      }
    } catch (e) {
      print('Error fetching XMLTV EPG: $e');
    }
  }

  // Generate catch-up URL for Xtream Codes
  String getCatchupUrl(String serverUrl, String username, String password, int streamId, DateTime startTime, int durationHours) {
    final startTimestamp = startTime.millisecondsSinceEpoch ~/ 1000;
    return '$serverUrl/timeshift/$username/$password/${durationHours * 3600}/$startTimestamp/$streamId.m3u8';
  }

  DateTime _parseDate(String dateStr) {
    // Basic XMLTV date format: 20240205180000 +0100
    try {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(dateStr.substring(8, 10));
      final minute = int.parse(dateStr.substring(10, 12));
      final second = int.parse(dateStr.substring(12, 14));
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      return DateTime.now();
    }
  }

  EPGProgram? getCurrentProgram(String channelId) {
    if (!_programs.containsKey(channelId)) return null;
    final now = DateTime.now();
    for (var program in _programs[channelId]!) {
      if (now.isAfter(program.start) && now.isBefore(program.stop)) {
        return program;
      }
    }
    return null;
  }

  EPGProgram? getNextProgram(String channelId) {
    if (!_programs.containsKey(channelId)) return null;
    final now = DateTime.now();
    EPGProgram? next;
    for (var program in _programs[channelId]!) {
      if (program.start.isAfter(now)) {
        if (next == null || program.start.isBefore(next.start)) {
          next = program;
        }
      }
    }
    return next;
  }

  List<EPGProgram> getProgramsForChannel(String channelId) {
    return _programs[channelId] ?? [];
  }

  List<EPGProgram> getPastPrograms(String channelId, {int hoursBack = 24}) {
    if (!_programs.containsKey(channelId)) return [];
    final cutoff = DateTime.now().subtract(Duration(hours: hoursBack));
    return _programs[channelId]!.where((p) => p.stop.isBefore(DateTime.now()) && p.start.isAfter(cutoff)).toList();
  }
}
