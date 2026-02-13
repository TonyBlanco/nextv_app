import '../core/models/xtream_models.dart';

/// M3U Entry model
class M3UEntry {
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? tvgId;
  final String? category;
  final Map<String, String> attributes;
  final Map<String, String> httpHeaders;

  const M3UEntry({
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.tvgId,
    this.category,
    this.attributes = const {},
    this.httpHeaders = const {},
  });

  factory M3UEntry.fromLine(String extinf, String url) {
    final attributes = <String, String>{};
    String name = '';
    String? logo;
    String? group;
    String? tvgId;
    String? category;
    final httpHeaders = <String, String>{};

    // Parse EXTINF line
    final regex = RegExp(r'([a-zA-Z-]+)="([^"]*)"');
    final matches = regex.allMatches(extinf);
    
    for (final match in matches) {
      final key = match.group(1)!;
      final value = match.group(2)!;
      attributes[key] = value;
      
      if (key == 'tvg-logo') logo = value;
      if (key == 'group-title') {
        group = value;
        category = value;
      }
      if (key == 'tvg-id') tvgId = value;
    }

    // Extract name (after last comma)
    final nameMatch = RegExp(r',(.+)$').firstMatch(extinf);
    if (nameMatch != null) {
      name = nameMatch.group(1)!.trim();
    }

    return M3UEntry(
      name: name,
      url: url,
      logo: logo,
      group: group,
      tvgId: tvgId,
      category: category,
      attributes: attributes,
      httpHeaders: httpHeaders,
    );
  }

  /// Convert M3UEntry to LiveStream
  LiveStream toLiveStream([int index = 0]) {
    return LiveStream(
      num: index,
      name: name,
      streamType: 'live',
      streamId: tvgId != null ? int.tryParse(tvgId!) ?? name.hashCode : name.hashCode,
      streamIcon: logo ?? '',
      epgChannelId: tvgId != null ? int.tryParse(tvgId!) ?? 0 : 0,
      added: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      categoryId: category ?? group ?? 'Uncategorized',
      customSid: '',
      tvArchive: 0,
      tvArchiveDuration: 0,
      directSource: url,
      httpHeaders: httpHeaders,
    );
  }
}

/// M3U Parser
class M3UParser {
  static List<M3UEntry> parse(String content) {
    final entries = <M3UEntry>[];
    final lines = content.split('\n');
    
    String? currentExtinf;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('#EXTINF:')) {
        currentExtinf = line;
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentExtinf != null) {
          entries.add(M3UEntry.fromLine(currentExtinf, line));
          currentExtinf = null;
        }
      }
    }
    
    return entries;
  }

  static Future<List<M3UEntry>> parseFile(String filePath) async {
    // TODO: Implement file reading
    return [];
  }

  static Future<List<M3UEntry>> parseUrl(String url) async {
    // TODO: Implement HTTP request
    return [];
  }
}
