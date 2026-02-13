// TB Cinema - Xtream Codes API Models

/// Safely parse a JSON value to int, handling both int and String.
int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Safely parse a JSON value to List<String>, handling String, List, or null.
List<String> _toStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String) return v.isEmpty ? [] : [v];
  return [];
}
// Based on IPTV Smarters Pro functionality

class XtreamCredentials {
  final String serverUrl;
  final String username;
  final String password;

  XtreamCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
      };

  factory XtreamCredentials.fromJson(Map<String, dynamic> json) {
    return XtreamCredentials(
      serverUrl: json['serverUrl'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}

class UserInfo {
  final String username;
  final String password;
  final String status;
  final String expDate;
  final bool isTrial;
  final String activeCons;
  final String createdAt;
  final String maxConnections;

  UserInfo({
    required this.username,
    required this.password,
    required this.status,
    required this.expDate,
    required this.isTrial,
    required this.activeCons,
    required this.createdAt,
    required this.maxConnections,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expDate: json['exp_date'] as String? ?? '',
      isTrial: (json['is_trial'] as String?) == '1',
      activeCons: json['active_cons'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      maxConnections: json['max_connections'] as String? ?? '',
    );
  }
}

class ServerInfo {
  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;
  final String rtmpPort;
  final String timezone;

  ServerInfo({
    required this.url,
    required this.port,
    required this.httpsPort,
    required this.serverProtocol,
    required this.rtmpPort,
    required this.timezone,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      url: json['url'] as String? ?? '',
      port: json['port'] as String? ?? '',
      httpsPort: json['https_port'] as String? ?? '',
      serverProtocol: json['server_protocol'] as String? ?? 'http',
      rtmpPort: json['rtmp_port'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
    );
  }
}

class LiveCategory {
  final String categoryId;
  final String categoryName;
  final String parentId;

  LiveCategory({
    required this.categoryId,
    required this.categoryName,
    required this.parentId,
  });

  factory LiveCategory.fromJson(Map<String, dynamic> json) {
    return LiveCategory(
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'] as String? ?? '',
      parentId: json['parent_id']?.toString() ?? '0',
    );
  }
}

class LiveStream {
  final int num;
  final String name;
  final String streamType;
  final int streamId;
  final String streamIcon;
  final int epgChannelId;
  final int added;
  final String categoryId;
  final String customSid;
  final int tvArchive;
  final String directSource;
  final int tvArchiveDuration;
  final Map<String, String> httpHeaders; // HTTP headers for M3U streams
  final List<Subtitle> subtitles;

  LiveStream({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.epgChannelId,
    required this.added,
    required this.categoryId,
    required this.customSid,
    required this.tvArchive,
    required this.directSource,
    required this.tvArchiveDuration,
    this.httpHeaders = const {},
    this.subtitles = const [],
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      num: int.tryParse(json['num']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? '',
      streamType: json['stream_type'] as String? ?? '',
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      streamIcon: json['stream_icon'] as String? ?? '',
      epgChannelId: int.tryParse(json['epg_channel_id']?.toString() ?? '0') ?? 0,
      added: int.tryParse(json['added']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id']?.toString() ?? '',
      customSid: json['custom_sid'] as String? ?? '',
      tvArchive: int.tryParse(json['tv_archive']?.toString() ?? '0') ?? 0,
      directSource: json['direct_source'] as String? ?? '',
      tvArchiveDuration: int.tryParse(json['tv_archive_duration']?.toString() ?? '0') ?? 0,
      subtitles: (json['subtitles'] as List?)
              ?.map((e) => Subtitle.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  String getStreamUrl(String serverUrl, String username, String password) {
    return '$serverUrl/live/$username/$password/$streamId.m3u8';
  }
}

class VODCategory {
  final String categoryId;
  final String categoryName;
  final String parentId;

  VODCategory({
    required this.categoryId,
    required this.categoryName,
    required this.parentId,
  });

  factory VODCategory.fromJson(Map<String, dynamic> json) {
    return VODCategory(
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'] as String? ?? '',
      parentId: json['parent_id']?.toString() ?? '0',
    );
  }
}

class VODStream {
  final int num;
  final String name;
  final String streamType;
  final int streamId;
  final String streamIcon;
  final int rating;
  final String rating5based;
  final int added;
  final String categoryId;
  final String containerExtension;
  final String directSource;
  final List<Subtitle> subtitles;

  VODStream({
    required this.num,
    required this.name,
    required this.streamType,
    required this.streamId,
    required this.streamIcon,
    required this.rating,
    required this.rating5based,
    required this.added,
    required this.categoryId,
    required this.containerExtension,
    required this.directSource,
    this.subtitles = const [],
  });

  factory VODStream.fromJson(Map<String, dynamic> json) {
    return VODStream(
      num: _toInt(json['num']),
      name: json['name'] as String? ?? '',
      streamType: json['stream_type'] as String? ?? '',
      streamId: _toInt(json['stream_id']),
      streamIcon: json['stream_icon'] as String? ?? '',
      rating: _toInt(json['rating']),
      rating5based: json['rating_5based']?.toString() ?? '',
      added: _toInt(json['added']),
      categoryId: json['category_id']?.toString() ?? '',
      containerExtension: json['container_extension'] as String? ?? 'mp4',
      directSource: json['direct_source'] as String? ?? '',
      subtitles: (json['subtitles'] as List?)
              ?.map((e) => Subtitle.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  String getStreamUrl(String serverUrl, String username, String password) {
    return '$serverUrl/movie/$username/$password/$streamId.$containerExtension';
  }
}

class VODInfo {
  final MovieInfo info;
  final MovieData movieData;

  VODInfo({
    required this.info,
    required this.movieData,
  });

  factory VODInfo.fromJson(Map<String, dynamic> json) {
    return VODInfo(
      info: MovieInfo.fromJson(json['info'] as Map<String, dynamic>? ?? {}),
      movieData: MovieData.fromJson(json['movie_data'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MovieInfo {
  final String kinopoiskUrl;
  final String tmdbId;
  final String name;
  final String o_name;
  final String coverBig;
  final String movieImage;
  final String releasedate;
  final String youtubeTrailer;
  final String director;
  final String actors;
  final String cast;
  final String description;
  final String plot;
  final String age;
  final String mpaaRating;
  final String ratingCountKinopoisk;
  final String country;
  final String genre;
  final String duration;
  final List<String> backdropPath;

  MovieInfo({
    required this.kinopoiskUrl,
    required this.tmdbId,
    required this.name,
    required this.o_name,
    required this.coverBig,
    required this.movieImage,
    required this.releasedate,
    required this.youtubeTrailer,
    required this.director,
    required this.actors,
    required this.cast,
    required this.description,
    required this.plot,
    required this.age,
    required this.mpaaRating,
    required this.ratingCountKinopoisk,
    required this.country,
    required this.genre,
    required this.duration,
    required this.backdropPath,
  });

  factory MovieInfo.fromJson(Map<String, dynamic> json) {
    return MovieInfo(
      kinopoiskUrl: json['kinopoisk_url'] as String? ?? '',
      tmdbId: json['tmdb_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      o_name: json['o_name'] as String? ?? '',
      coverBig: json['cover_big'] as String? ?? '',
      movieImage: json['movie_image'] as String? ?? '',
      releasedate: json['releasedate'] as String? ?? '',
      youtubeTrailer: json['youtube_trailer'] as String? ?? '',
      director: json['director'] as String? ?? '',
      actors: json['actors'] as String? ?? '',
      cast: json['cast'] as String? ?? '',
      description: json['description'] as String? ?? '',
      plot: json['plot'] as String? ?? '',
      age: json['age'] as String? ?? '',
      mpaaRating: json['mpaa_rating'] as String? ?? '',
      ratingCountKinopoisk: json['rating_count_kinopoisk'] as String? ?? '',
      country: json['country'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      backdropPath: (json['backdrop_path'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class MovieData {
  final int streamId;
  final String name;
  final String added;
  final String categoryId;
  final String containerExtension;
  final String customSid;
  final String directSource;

  MovieData({
    required this.streamId,
    required this.name,
    required this.added,
    required this.categoryId,
    required this.containerExtension,
    required this.customSid,
    required this.directSource,
  });

  factory MovieData.fromJson(Map<String, dynamic> json) {
    return MovieData(
      streamId: _toInt(json['stream_id']),
      name: json['name'] as String? ?? '',
      added: json['added']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      containerExtension: json['container_extension'] as String? ?? 'mp4',
      customSid: json['custom_sid'] as String? ?? '',
      directSource: json['direct_source'] as String? ?? '',
    );
  }
}

class EPGProgram {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime stop;
  final String channelId;
  final bool hasCatchup;

  EPGProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.stop,
    required this.channelId,
    this.hasCatchup = false,
  });

  factory EPGProgram.fromJson(Map<String, dynamic> json) {
    return EPGProgram(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      start: DateTime.fromMillisecondsSinceEpoch(_toInt(json['start']) * 1000),
      stop: DateTime.fromMillisecondsSinceEpoch(_toInt(json['stop']) * 1000),
      channelId: json['channel_id']?.toString() ?? '',
      hasCatchup: json['has_archive'] == 1 || json['has_archive'] == true,
    );
  }
}

class Subtitle {
  final String url;
  final String language;
  final String? name;
  final String? format;

  Subtitle({
    required this.url,
    required this.language,
    this.name,
    this.format,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    return Subtitle(
      url: json['url'] as String? ?? '',
      language: json['language'] as String? ?? json['lang'] as String? ?? '',
      name: json['name'] as String? ?? json['title'] as String?,
      format: json['format'] as String?,
    );
  }
}

// ==================== SERIES MODELS ====================

class SeriesCategory {
  final String categoryId;
  final String categoryName;
  final String parentId;

  SeriesCategory({
    required this.categoryId,
    required this.categoryName,
    required this.parentId,
  });

  factory SeriesCategory.fromJson(Map<String, dynamic> json) {
    return SeriesCategory(
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'] as String? ?? '',
      parentId: json['parent_id']?.toString() ?? '0',
    );
  }
}

class SeriesItem {
  final int num;
  final String name;
  final int seriesId;
  final String cover;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final int lastModified;
  final String rating;
  final String rating5based;
  final List<String> backdropPath;
  final String youtubeTrailer;
  final int episodeRunTime;
  final String categoryId;

  SeriesItem({
    required this.num,
    required this.name,
    required this.seriesId,
    required this.cover,
    required this.plot,
    required this.cast,
    required this.director,
    required this.genre,
    required this.releaseDate,
    required this.lastModified,
    required this.rating,
    required this.rating5based,
    required this.backdropPath,
    required this.youtubeTrailer,
    required this.episodeRunTime,
    required this.categoryId,
  });

  factory SeriesItem.fromJson(Map<String, dynamic> json) {
    return SeriesItem(
      num: _toInt(json['num']),
      name: json['name'] as String? ?? '',
      seriesId: _toInt(json['series_id']),
      cover: json['cover'] as String? ?? '',
      plot: json['plot'] as String? ?? '',
      cast: json['cast'] as String? ?? '',
      director: json['director'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      lastModified: _toInt(json['last_modified']),
      rating: json['rating']?.toString() ?? '',
      rating5based: json['rating_5based']?.toString() ?? '',
      backdropPath: _toStringList(json['backdrop_path']),
      youtubeTrailer: json['youtube_trailer'] as String? ?? '',
      episodeRunTime: _toInt(json['episode_run_time']),
      categoryId: json['category_id']?.toString() ?? '',
    );
  }
}

class SeriesInfo {
  final Map<String, SeasonEpisodes> seasons;
  final SeriesDetails info;

  SeriesInfo({
    required this.seasons,
    required this.info,
  });

  factory SeriesInfo.fromJson(Map<String, dynamic> json) {
    // Xtream API returns episodes grouped by season number under 'episodes' key,
    // NOT under 'seasons' (which is just metadata array).
    final episodesData = json['episodes'] as Map<String, dynamic>? ?? {};
    final seasons = <String, SeasonEpisodes>{};
    
    episodesData.forEach((key, value) {
      if (value is List) {
        seasons[key] = SeasonEpisodes(
          seasonNumber: key,
          episodes: (value).map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    });

    return SeriesInfo(
      seasons: seasons,
      info: SeriesDetails.fromJson(json['info'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class SeasonEpisodes {
  final String seasonNumber;
  final List<Episode> episodes;

  SeasonEpisodes({
    required this.seasonNumber,
    required this.episodes,
  });
}

class Episode {
  final String id;
  final int episodeNum;
  final String title;
  final String containerExtension;
  final String info;
  final int duration;
  final String releaseDate;
  final String plot;
  final String movieImage;
  final List<String> bitrate;
  final String rating;
  final String season;
  final String directSource;

  Episode({
    required this.id,
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    required this.info,
    required this.duration,
    required this.releaseDate,
    required this.plot,
    required this.movieImage,
    required this.bitrate,
    required this.rating,
    required this.season,
    this.directSource = '',
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    // Xtream API can return 'info' as a nested Map with plot, duration, etc.
    final infoData = json['info'];
    final infoMap = infoData is Map<String, dynamic> ? infoData : <String, dynamic>{};
    
    return Episode(
      id: json['id']?.toString() ?? '',
      episodeNum: _toInt(json['episode_num']),
      title: json['title'] as String? ?? '',
      containerExtension: json['container_extension'] as String? ?? 'mp4',
      info: infoData is String ? infoData : '',
      duration: _toInt(json['duration'] ?? infoMap['duration']),
      releaseDate: json['releaseDate'] as String? ?? infoMap['releasedate'] as String? ?? '',
      plot: json['plot'] as String? ?? infoMap['plot'] as String? ?? '',
      movieImage: json['movie_image'] as String? ?? infoMap['movie_image'] as String? ?? '',
      bitrate: (json['bitrate'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: json['rating']?.toString() ?? infoMap['rating']?.toString() ?? '',
      season: json['season']?.toString() ?? '',
      directSource: json['direct_source'] as String? ?? '',
    );
  }

  String getStreamUrl(String serverUrl, String username, String password) {
    if (directSource.isNotEmpty) return directSource;
    return '$serverUrl/series/$username/$password/$id.$containerExtension';
  }
}

class SeriesDetails {
  final String name;
  final String cover;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final int lastModified;
  final String rating;
  final String rating5based;
  final List<String> backdropPath;
  final String youtubeTrailer;
  final int episodeRunTime;
  final String categoryId;
  final String tmdbId;

  SeriesDetails({
    required this.name,
    required this.cover,
    required this.plot,
    required this.cast,
    required this.director,
    required this.genre,
    required this.releaseDate,
    required this.lastModified,
    required this.rating,
    required this.rating5based,
    required this.backdropPath,
    required this.youtubeTrailer,
    required this.episodeRunTime,
    required this.categoryId,
    required this.tmdbId,
  });

  factory SeriesDetails.fromJson(Map<String, dynamic> json) {
    return SeriesDetails(
      name: json['name'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      plot: json['plot'] as String? ?? '',
      cast: json['cast'] as String? ?? '',
      director: json['director'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
      lastModified: _toInt(json['last_modified']),
      rating: json['rating']?.toString() ?? '',
      rating5based: json['rating_5based']?.toString() ?? '',
      backdropPath: (json['backdrop_path'] as List?)?.map((e) => e.toString()).toList() ?? [],
      youtubeTrailer: json['youtube_trailer'] as String? ?? '',
      episodeRunTime: _toInt(json['episode_run_time']),
      categoryId: json['category_id']?.toString() ?? '',
      tmdbId: json['tmdb_id']?.toString() ?? '',
    );
  }
}

// ==================== LIVE INDICATORS & EPG MODELS ====================

/// Channel live status information
class ChannelStatus {
  final int streamId;
  final bool isLive;
  final DateTime lastChecked;
  final int? bitrate;

  ChannelStatus({
    required this.streamId,
    required this.isLive,
    required this.lastChecked,
    this.bitrate,
  });

  /// Check if status is stale (older than 5 minutes)
  bool get isStale {
    return DateTime.now().difference(lastChecked).inMinutes > 5;
  }

  ChannelStatus copyWith({
    int? streamId,
    bool? isLive,
    DateTime? lastChecked,
    int? bitrate,
  }) {
    return ChannelStatus(
      streamId: streamId ?? this.streamId,
      isLive: isLive ?? this.isLive,
      lastChecked: lastChecked ?? this.lastChecked,
      bitrate: bitrate ?? this.bitrate,
    );
  }
}

/// Quick EPG information for channel preview
class EPGQuickInfo {
  final EPGProgram? current;
  final EPGProgram? next;

  EPGQuickInfo({
    this.current,
    this.next,
  });

  /// Get progress of current program (0.0 to 1.0)
  double? get progress {
    if (current == null) return null;
    final now = DateTime.now();
    if (now.isBefore(current!.start) || now.isAfter(current!.stop)) {
      return null;
    }
    final total = current!.stop.difference(current!.start).inSeconds;
    final elapsed = now.difference(current!.start).inSeconds;
    return elapsed / total;
  }

  /// Check if there's any EPG data available
  bool get hasData => current != null || next != null;
}
