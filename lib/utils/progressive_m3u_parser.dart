import 'package:dio/dio.dart';
import 'm3u_parser.dart';

/// Progressive M3U Parser for large playlists
class ProgressiveM3UParser {
  final Function(M3UEntry)? onEntry;
  final Function(double)? onProgress;
  final int? maxChannels;

  ProgressiveM3UParser({
    this.onEntry,
    this.onProgress,
    this.maxChannels,
  });

  Future<List<M3UEntry>> parse(String content) async {
    final entries = <M3UEntry>[];
    final lines = content.split('\n');
    final totalLines = lines.length;
    
    String? currentExtinf;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('#EXTINF:')) {
        currentExtinf = line;
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentExtinf != null) {
          final entry = M3UEntry.fromLine(currentExtinf, line);
          entries.add(entry);
          onEntry?.call(entry);
          currentExtinf = null;

          if (maxChannels != null && entries.length >= maxChannels!) break;
        }
      }
      
      if (i % 100 == 0) {
        onProgress?.call(i / totalLines);
      }
    }
    
    onProgress?.call(1.0);
    return entries;
  }

  /// Parse from a URL (downloads and parses content)
  Future<List<M3UEntry>> parseFromUrl(dynamic dioOrUrl, [String? url]) async {
    try {
      String content;
      if (dioOrUrl is Dio && url != null) {
        final response = await dioOrUrl.get<String>(url);
        content = response.data ?? '';
      } else if (dioOrUrl is String) {
        final dio = Dio();
        final response = await dio.get<String>(dioOrUrl);
        content = response.data ?? '';
      } else {
        return [];
      }
      return parse(content);
    } catch (e) {
      return [];
    }
  }

  Stream<M3UEntry> parseStream(String content) async* {
    final lines = content.split('\n');
    String? currentExtinf;
    int count = 0;
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('#EXTINF:')) {
        currentExtinf = trimmed;
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        if (currentExtinf != null) {
          yield M3UEntry.fromLine(currentExtinf, trimmed);
          currentExtinf = null;
          count++;
          if (maxChannels != null && count >= maxChannels!) return;
        }
      }
    }
  }
}
