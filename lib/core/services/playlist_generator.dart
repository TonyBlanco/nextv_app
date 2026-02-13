import '../models/xtream_models.dart';

/// Playlist Generator - generates M3U and XMLTV content from stream data
class PlaylistGenerator {
  /// Generate M3U playlist from live streams
  static String generateM3U(
    List<LiveStream> streams, {
    String serverUrl = '',
    String username = '',
    String password = '',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    
    for (final stream in streams) {
      buffer.writeln('#EXTINF:-1 tvg-id="${stream.epgChannelId}" tvg-logo="${stream.streamIcon}" group-title="${stream.categoryId}",${stream.name}');
      if (serverUrl.isNotEmpty) {
        buffer.writeln('$serverUrl/live/$username/$password/${stream.streamId}.ts');
      } else {
        buffer.writeln(stream.directSource);
      }
    }
    
    return buffer.toString();
  }

  /// Generate XMLTV EPG data from live streams 
  static String generateXMLTV(List<LiveStream> streams) {
    final buffer = StringBuffer();
    
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE tv SYSTEM "xmltv.dtd">');
    buffer.writeln('<tv generator-info-name="NeXtv Playlist Generator">');
    
    for (final stream in streams) {
      final channelId = stream.epgChannelId > 0 ? stream.epgChannelId.toString() : stream.streamId.toString();
      buffer.writeln('  <channel id="$channelId">');
      buffer.writeln('    <display-name>${_escapeXml(stream.name)}</display-name>');
      if (stream.streamIcon.isNotEmpty) {
        buffer.writeln('    <icon src="${_escapeXml(stream.streamIcon)}" />');
      }
      buffer.writeln('  </channel>');
    }
    
    buffer.writeln('</tv>');
    return buffer.toString();
  }

  /// Generate playlist filtered by country
  static String generatePlaylistByCountry(
    List<LiveStream> streams,
    String country, {
    String serverUrl = '',
    String username = '',
    String password = '',
  }) {
    final filtered = streams.where(
      (s) => s.name.toLowerCase().contains(country.toLowerCase()) ||
        s.categoryId.toLowerCase().contains(country.toLowerCase()),
    ).toList();
    return generateM3U(filtered, serverUrl: serverUrl, username: username, password: password);
  }

  /// Generate playlist filtered by language
  static String generatePlaylistByLanguage(
    List<LiveStream> streams,
    String language, {
    String serverUrl = '',
    String username = '',
    String password = '',
  }) {
    final filtered = streams.where(
      (s) => s.name.toLowerCase().contains(language.toLowerCase()) ||
        s.categoryId.toLowerCase().contains(language.toLowerCase()),
    ).toList();
    return generateM3U(filtered, serverUrl: serverUrl, username: username, password: password);
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
