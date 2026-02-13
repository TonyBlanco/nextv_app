import 'package:flutter/foundation.dart';

/// Represents a catch-up program in user's favorites, watch later, or history
/// 
/// This model is used for persistent storage in SharedPreferences.
/// It stores minimal data (just IDs and progress) to keep storage efficient.
@immutable
class CatchupItem {
  final String programId;
  final DateTime addedAt;
  final int watchProgressSeconds;
  final int totalDurationSeconds;
  final bool completed;

  const CatchupItem({
    required this.programId,
    required this.addedAt,
    this.watchProgressSeconds = 0,
    this.totalDurationSeconds = 0,
    this.completed = false,
  });

  /// Progress as percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalDurationSeconds == 0) return 0.0;
    return (watchProgressSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  /// Check if program has been started
  bool get hasStarted => watchProgressSeconds > 0;

  /// Check if program is partially watched (> 10% and < 90%)
  bool get isPartiallyWatched {
    return progressPercentage > 0.1 && progressPercentage < 0.9;
  }

  /// Remaining watch time
  Duration get remainingTime {
    final remaining = totalDurationSeconds - watchProgressSeconds;
    return Duration(seconds: remaining.clamp(0, totalDurationSeconds));
  }

  /// Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'addedAt': addedAt.toIso8601String(),
      'watchProgressSeconds': watchProgressSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'completed': completed,
    };
  }

  /// Create from JSON
  factory CatchupItem.fromJson(Map<String, dynamic> json) {
    return CatchupItem(
      programId: json['programId'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      watchProgressSeconds: json['watchProgressSeconds'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  CatchupItem copyWith({
    String? programId,
    DateTime? addedAt,
    int? watchProgressSeconds,
    int? totalDurationSeconds,
    bool? completed,
  }) {
    return CatchupItem(
      programId: programId ?? this.programId,
      addedAt: addedAt ?? this.addedAt,
      watchProgressSeconds: watchProgressSeconds ?? this.watchProgressSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      completed: completed ?? this.completed,
    );
  }

  /// Update watch progress
  CatchupItem updateProgress({
    required int positionSeconds,
    required int durationSeconds,
  }) {
    // Mark as completed if watched > 90%
    final progress = positionSeconds / durationSeconds;
    final isCompleted = progress >= 0.9;

    return copyWith(
      watchProgressSeconds: positionSeconds,
      totalDurationSeconds: durationSeconds,
      completed: isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatchupItem && other.programId == programId;
  }

  @override
  int get hashCode => programId.hashCode;

  @override
  String toString() {
    return 'CatchupItem(programId: $programId, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%, completed: $completed)';
  }
}
