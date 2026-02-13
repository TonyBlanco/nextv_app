import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';

/// Placeholder playlist selector screen
class PlaylistSelectorScreen extends StatelessWidget {
  const PlaylistSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        title: const Text('Seleccionar Playlist'),
        backgroundColor: NextvColors.surface,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Seleccionar Playlist',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
