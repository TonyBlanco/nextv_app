import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mobile/ios/ios_home_screen.dart';
import 'mobile/android/android_home_screen.dart';
import 'screens/landing_screen.dart';

/// Platform-aware router that directs to appropriate UI
class PlatformRouter extends StatelessWidget {
  const PlatformRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // Web or Desktop -> Use existing desktop UI
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return const LandingScreen();
    }
    
    // iOS -> Use iOS-optimized UI
    if (Platform.isIOS) {
      return const IOSHomeScreen();
    }
    
    // Android -> Use Android-optimized UI
    if (Platform.isAndroid) {
      return const AndroidHomeScreen();
    }
    
    // Fallback to desktop UI
    return const LandingScreen();
  }
}
