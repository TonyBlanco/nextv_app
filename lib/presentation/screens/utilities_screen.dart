import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';

/// Placeholder utilities screen
class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        title: const Text('Utilidades'),
        backgroundColor: NextvColors.surface,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Utilidades',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
