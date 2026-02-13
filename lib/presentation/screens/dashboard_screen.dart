import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';

/// Placeholder dashboard screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: NextvColors.surface,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Dashboard',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
