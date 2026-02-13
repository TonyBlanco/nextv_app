import 'package:equatable/equatable.dart';

/// Model for "Watch Later" bookmarks
class WatchlistItem extends Equatable {
  /// Unique key: "vod_123" or "series_456"
  final String id;
  /// 'movie' | 'series'
  final String type;
  final String title;
  final String imageUrl;
  /// For movies: direct playback URL; for series: empty (navigate to detail)
  final String playbackUrl;
  final DateTime addedAt;
  final int streamId;

  const WatchlistItem({
    required this.id,
    required this.type,
    required this.title,
    required this.imageUrl,
    required this.playbackUrl,
    required this.addedAt,
    required this.streamId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'imageUrl': imageUrl,
    'playbackUrl': playbackUrl,
    'addedAt': addedAt.toIso8601String(),
    'streamId': streamId,
  };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      playbackUrl: json['playbackUrl'] as String? ?? '',
      addedAt: DateTime.parse(json['addedAt'] as String),
      streamId: json['streamId'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, type, title, streamId, addedAt];
}
