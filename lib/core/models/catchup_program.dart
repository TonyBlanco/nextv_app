import 'package:flutter/foundation.dart';

/// Represents a catch-up/replay TV program available for playback
/// 
/// This model extends EPG program data with catch-up specific properties
/// like stream URL, expiry time, and availability status.
@immutable
class CatchupProgram {
  final String id;
  final int channelId;
  final String channelName;
  final String channelLogo;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final String streamUrl;
  final String? thumbnailUrl;
  final String? category;
  final int retentionDays; // Provider's retention period

  const CatchupProgram({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelLogo,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.streamUrl,
    this.thumbnailUrl,
    this.category,
    this.retentionDays = 3, // Default minimum 3 days
  });

  /// Duration of the program
  Duration get duration => Duration(seconds: durationSeconds);

  /// Expiry time based on retention period
  DateTime get expiryTime => startTime.add(Duration(days: retentionDays));

  /// Check if program is still available
  bool get isExpired => DateTime.now().isAfter(expiryTime);

  /// Time remaining before expiry
  Duration get timeRemaining {
    final now = DateTime.now();
    return isExpired ? Duration.zero : expiryTime.difference(now);
  }

  /// Check if program is expiring soon (< 24 hours)
  bool get isExpiringSoon => !isExpired && timeRemaining.inHours < 24;

  /// Create from EPG program data
  factory CatchupProgram.fromEpgProgram({
    required String id,
    required int channelId,
    required String channelName,
    required String channelLogo,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String streamUrl,
    String? thumbnailUrl,
    String? category,
    int retentionDays = 3,
  }) {
    final durationSeconds = endTime.difference(startTime).inSeconds;
    
    return CatchupProgram(
      id: id,
      channelId: channelId,
      channelName: channelName,
      channelLogo: channelLogo,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
      streamUrl: streamUrl,
      thumbnailUrl: thumbnailUrl,
      category: category,
      retentionDays: retentionDays,
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'channelName': channelName,
      'channelLogo': channelLogo,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'streamUrl': streamUrl,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'retentionDays': retentionDays,
    };
  }

  /// Create from JSON
  factory CatchupProgram.fromJson(Map<String, dynamic> json) {
    return CatchupProgram(
      id: json['id'] as String,
      channelId: json['channelId'] as int,
      channelName: json['channelName'] as String,
      channelLogo: json['channelLogo'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationSeconds: json['durationSeconds'] as int,
      streamUrl: json['streamUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      category: json['category'] as String?,
      retentionDays: json['retentionDays'] as int? ?? 3,
    );
  }

  /// Create a copy with updated fields
  CatchupProgram copyWith({
    String? id,
    int? channelId,
    String? channelName,
    String? channelLogo,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    String? streamUrl,
    String? thumbnailUrl,
    String? category,
    int? retentionDays,
  }) {
    return CatchupProgram(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelLogo: channelLogo ?? this.channelLogo,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      streamUrl: streamUrl ?? this.streamUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      retentionDays: retentionDays ?? this.retentionDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatchupProgram && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CatchupProgram(id: $id, title: $title, channel: $channelName, '
        'start: $startTime, expired: $isExpired)';
  }
}
