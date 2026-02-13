import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/nextv_colors.dart';
import '../widgets/nextv_logo.dart';
import 'nova_main_screen.dart';

/// Simplified Netflix-style mobile layout for phones only
/// This is a wrapper that shows the NovaMainScreen but with better mobile UX
class MobileMainScreen extends ConsumerWidget {
  const MobileMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, just use the NovaMainScreen
    // The mobile layout detection is already built into NovaMainScreen
    return const NovaMainScreen();
  }
}
