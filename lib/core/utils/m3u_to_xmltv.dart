import '../models/xtream_models.dart';
import '../../utils/m3u_parser.dart';

/// M3U to XMLTV converter
class M3UToXMLTV {
  static String convert(List<M3UEntry> entries) {
    final buffer = StringBuffer();
    
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE tv SYSTEM "xmltv.dtd">');
    buffer.writeln('<tv generator-info-name="NeXtv M3U to XMLTV Converter">');
    
    for (final entry in entries) {
      final channelId = entry.tvgId ?? entry.name.replaceAll(' ', '_');
      buffer.writeln('  <channel id="$channelId">');
      buffer.writeln('    <display-name>${_escapeXml(entry.name)}</display-name>');
      if (entry.logo != null) {
        buffer.writeln('    <icon src="${_escapeXml(entry.logo!)}" />');
      }
      buffer.writeln('  </channel>');
    }
    
    buffer.writeln('</tv>');
    return buffer.toString();
  }

  /// Convert M3U entries and cache the result
  static Future<String> convertAndCache(List<M3UEntry> entries, String cachePath) async {
    final xmltv = convert(entries);
    // TODO: Save to file for caching
    return xmltv;
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
