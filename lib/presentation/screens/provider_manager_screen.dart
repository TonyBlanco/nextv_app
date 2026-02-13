import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';

/// Placeholder provider manager screen
class ProviderManagerScreen extends StatelessWidget {
  const ProviderManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Proveedores'),
        backgroundColor: NextvColors.surface,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Gestión de Proveedores',
              style: TextStyle(color: Colors.white60, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
