import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist_model.dart';

/// Tracks the currently active playlist being used in the player
final activePlaylistProvider = StateProvider<Playlist?>((ref) => null);
