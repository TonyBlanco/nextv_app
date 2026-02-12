import 'package:equatable/equatable.dart';

/// Model representing a favorite channel
class FavoriteChannel extends Equatable {
  final int streamId;
  final String name;
  final String icon;
  final String categoryId;
  final DateTime addedAt;

  const FavoriteChannel({
    required this.streamId,
    required this.name,
    required this.icon,
    required this.categoryId,
    required this.addedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'streamId': streamId,
      'name': name,
      'icon': icon,
      'categoryId': categoryId,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory FavoriteChannel.fromJson(Map<String, dynamic> json) {
    return FavoriteChannel(
      streamId: json['streamId'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [streamId, name, icon, categoryId, addedAt];
}
