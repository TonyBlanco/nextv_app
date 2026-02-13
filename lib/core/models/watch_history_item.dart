import 'package:equatable/equatable.dart';

/// Model for tracking playback progress (Netflix-style "Continue Watching")
class WatchHistoryItem extends Equatable {
  /// Unique key: "vod_123" or "series_456_ep_789"
  final String id;
  /// 'movie' | 'episode'
  final String type;
  final String title;
  /// For episodes: parent series name
  final String? seriesName;
  final String imageUrl;
  final String playbackUrl;
  /// Where user left off
  final Duration position;
  /// Total length (if known)
  final Duration? duration;
  final DateTime lastWatched;
  final int streamId;

  const WatchHistoryItem({
    required this.id,
    required this.type,
    required this.title,
    this.seriesName,
    required this.imageUrl,
    required this.playbackUrl,
    required this.position,
    this.duration,
    required this.lastWatched,
    required this.streamId,
  });

  /// Progress percentage 0.0 - 1.0
  double get progress {
    if (duration == null || duration!.inSeconds == 0) return 0.0;
    return (position.inSeconds / duration!.inSeconds).clamp(0.0, 1.0);
  }

  WatchHistoryItem copyWith({
    Duration? position,
    Duration? duration,
    DateTime? lastWatched,
  }) {
    return WatchHistoryItem(
      id: id,
      type: type,
      title: title,
      seriesName: seriesName,
      imageUrl: imageUrl,
      playbackUrl: playbackUrl,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      lastWatched: lastWatched ?? this.lastWatched,
      streamId: streamId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'seriesName': seriesName,
    'imageUrl': imageUrl,
    'playbackUrl': playbackUrl,
    'positionMs': position.inMilliseconds,
    'durationMs': duration?.inMilliseconds,
    'lastWatched': lastWatched.toIso8601String(),
    'streamId': streamId,
  };

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      seriesName: json['seriesName'] as String?,
      imageUrl: json['imageUrl'] as String? ?? '',
      playbackUrl: json['playbackUrl'] as String,
      position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      lastWatched: DateTime.parse(json['lastWatched'] as String),
      streamId: json['streamId'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, type, title, streamId, position, lastWatched];
}
