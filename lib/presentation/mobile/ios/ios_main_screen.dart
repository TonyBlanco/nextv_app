import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nextv_colors.dart';
import 'ios_live_screen.dart';
import 'ios_vod_screen.dart';
import 'ios_series_screen.dart';

/// iOS main screen with bottom navigation
class IOSMainScreen extends ConsumerStatefulWidget {
  const IOSMainScreen({super.key});

  @override
  ConsumerState<IOSMainScreen> createState() => _IOSMainScreenState();
}

class _IOSMainScreenState extends ConsumerState<IOSMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    IOSLiveScreen(),
    IOSVODScreen(),
    IOSSeriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: NextvColors.surface,
        activeColor: NextvColors.accent,
        inactiveColor: NextvColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tv),
            label: 'Live TV',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.film),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_stack_3d_up),
            label: 'Series',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => _screens[index],
        );
      },
    );
  }
}
