import 'package:flutter/foundation.dart';
import '../models/catchup_program.dart';
import '../models/catchup_item.dart';
import '../constants/catchup_config.dart';
import 'catchup_storage_service.dart';

/// Service for managing catch-up playback state and progress
/// 
/// Handles auto-resume functionality, progress tracking, and
/// completion detection.
class CatchupPlaybackService {
  final CatchupStorageService _storageService;

  CatchupPlaybackService(this._storageService);

  // ─── PLAYBACK INITIALIZATION ───

  /// Start playback for a catch-up program
  /// Returns playback info including resume position if available
  Future<PlaybackInfo> startPlayback(CatchupProgram program) async {
    // Check if there's saved progress
    final savedProgress = _storageService.getWatchProgress(program.id);

    if (savedProgress != null && savedProgress.hasStarted && !savedProgress.completed) {
      // Has progress, offer resume
      debugPrint('📺 Resume available for "${program.title}" at ${savedProgress.progressPercentage * 100}%');
      
      return PlaybackInfo(
        program: program,
        resumePosition: Duration(seconds: savedProgress.watchProgressSeconds),
        shouldResume: true,
      );
    }

    // No progress, start from beginning
    debugPrint('📺 Starting "${program.title}" from beginning');
    
    return PlaybackInfo(
      program: program,
      resumePosition: Duration.zero,
      shouldResume: false,
    );
  }

  // ─── PROGRESS TRACKING ───

  /// Update playback progress
  /// Should be called periodically during playback (every 10s)
  Future<void> updateProgress({
    required String programId,
    required Duration position,
    required Duration duration,
  }) async {
    await _storageService.saveWatchProgress(
      programId: programId,
      positionSeconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
    );

    // Check if completed (>= 90%)
    final progress = position.inSeconds / duration.inSeconds;
    if (progress >= CatchupConfig.completionThreshold) {
      await markCompleted(programId);
    }
  }

  /// Mark program as completed
  Future<void> markCompleted(String programId) async {
    debugPrint('✅ Program $programId marked as completed');
    
    // Progress is already saved with completed flag by storage service
    // Just add to history if not already there
    await _storageService.addToHistory(programId);
  }

  /// Get saved progress for a program
  CatchupItem? getProgress(String programId) {
    return _storageService.getWatchProgress(programId);
  }

  /// Check if program has been started
  bool hasProgress(String programId) {
    return _storageService.hasWatchProgress(programId);
  }

  /// Reset progress for a program (start over)
  Future<void> resetProgress(String programId) async {
    await _storageService.saveWatchProgress(
      programId: programId,
      positionSeconds: 0,
      durationSeconds: 0,
    );
  }

  // ─── PLAYBACK CONTROL HELPERS ───

  /// Calculate recommended save interval based on platform
  Duration get saveInterval => CatchupConfig.progressSaveInterval;

  /// Get completion threshold percentage
  double get completionThreshold => CatchupConfig.completionThreshold;
}

/// Playback information for a catch-up program
@immutable
class PlaybackInfo {
  final CatchupProgram program;
  final Duration resumePosition;
  final bool shouldResume;

  const PlaybackInfo({
    required this.program,
    required this.resumePosition,
    required this.shouldResume,
  });

  /// Get stream URL
  String get streamUrl => program.streamUrl;

  /// Check if should show resume dialog
  bool get showResumeDialog => shouldResume && resumePosition.inSeconds > 10;

  @override
  String toString() {
    return 'PlaybackInfo(program: ${program.title}, '
        'resume: $shouldResume, position: $resumePosition)';
  }
}
