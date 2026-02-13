import 'package:equatable/equatable.dart';

/// Model representing a favorite channel
class FavoriteChannel extends Equatable {
  final int streamId;
  final String name;
  final String icon;
  final String categoryId;
  final DateTime addedAt;
  final String type; // 'channel', 'movie', 'series'
  final String? seriesId; // For series
  final String? cover; // For VOD/Series cover

  const FavoriteChannel({
    required this.streamId,
    required this.name,
    required this.icon,
    required this.categoryId,
    required this.addedAt,
    this.type = 'channel',
    this.seriesId,
    this.cover,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'streamId': streamId,
      'name': name,
      'icon': icon,
      'categoryId': categoryId,
      'addedAt': addedAt.toIso8601String(),
      'type': type,
      'seriesId': seriesId,
      'cover': cover,
    };
  }

  /// Create from JSON
  factory FavoriteChannel.fromJson(Map<String, dynamic> json) {
    return FavoriteChannel(
      streamId: json['streamId'] as int? ?? 0,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      type: json['type'] as String? ?? 'channel',
      seriesId: json['seriesId'] as String?,
      cover: json['cover'] as String?,
    );
  }

  @override
  List<Object?> get props => [streamId, name, icon, categoryId, addedAt, type, seriesId, cover];
}
