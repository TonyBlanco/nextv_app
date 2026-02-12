import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/provider_manager.dart';
import '../../core/providers/active_playlist_provider.dart';
// nextv_logo widget used by other screens; landing uses Image.asset directly
import 'nova_main_screen.dart';
import 'utilities_screen.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pm = ref.watch(providerManagerProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: NextvColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: NextvColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: NextvColors.accent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // NeXtv Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/nextv_home.png',
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NeXtv',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pm.activeProviderName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: NextvColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings icon
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    iconSize: 28,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UtilitiesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: screenWidth > 600
                    ? _buildGridLayout(context, ref)
                    : _buildListLayout(context, ref),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Premium Streaming Experience',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      children: [
        _buildCategoryCard(
          context,
          ref,
          title: 'LIVE TV',
          icon: Icons.live_tv,
          gradient: const LinearGradient(
            colors: [NextvColors.accent, Color(0xFF0066A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToCategory(context, ref, 0),
        ),
        _buildCategoryCard(
          context,
          ref,
          title: 'MOVIES',
          icon: Icons.movie,
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToCategory(context, ref, 1),
        ),
        _buildCategoryCard(
          context,
          ref,
          title: 'SERIES',
          icon: Icons.tv,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToCategory(context, ref, 2),
        ),
        _buildCategoryCard(
          context,
          ref,
          title: 'SPORTS',
          icon: Icons.sports_soccer,
          gradient: const LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToCategory(context, ref, 0, sportsOnly: true),
        ),
        _buildCategoryCard(
          context,
          ref,
          title: 'FAVORITES',
          icon: Icons.favorite,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _navigateToCategory(context, ref, 0, favoritesOnly: true),
        ),
        _buildCategoryCard(
          context,
          ref,
          title: 'UTILITIES',
          icon: Icons.settings,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UtilitiesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListLayout(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        _buildLargeCard(
          context,
          ref,
          title: 'LIVE TV',
          subtitle: 'Watch live channels',
          icon: Icons.live_tv,
          gradient: const LinearGradient(
            colors: [NextvColors.accent, Color(0xFF0066A8)],
          ),
          onTap: () => _navigateToCategory(context, ref, 0),
        ),
        const SizedBox(height: 16),
        _buildLargeCard(
          context,
          ref,
          title: 'MOVIES',
          subtitle: 'On-demand movies',
          icon: Icons.movie,
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
          onTap: () => _navigateToCategory(context, ref, 1),
        ),
        const SizedBox(height: 16),
        _buildLargeCard(
          context,
          ref,
          title: 'SERIES',
          subtitle: 'TV shows & series',
          icon: Icons.tv,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          ),
          onTap: () => _navigateToCategory(context, ref, 2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSmallCard(
                context,
                title: 'SPORTS',
                icon: Icons.sports_soccer,
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                ),
                onTap: () => _navigateToCategory(context, ref, 0, sportsOnly: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallCard(
                context,
                title: 'FAVORITES',
                icon: Icons.favorite,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                ),
                onTap: () => _navigateToCategory(context, ref, 0, favoritesOnly: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLargeCard(
          context,
          ref,
          title: 'UTILITIES',
          subtitle: 'Settings & preferences',
          icon: Icons.settings,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UtilitiesScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Gradient gradient, // Mantener firma pero ignorar
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Focus(
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return Container(
                decoration: BoxDecoration(
                  color: NextvColors.surface, // Gris oscuro siempre
                  borderRadius: BorderRadius.circular(16),
                  border: isFocused
                      ? Border.all(color: NextvColors.accent, width: 2)
                      : Border.all(color: Colors.white10),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: NextvColors.accent.withOpacity(0.3),
                            blurRadius: 12,
                          )
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    onHover: (hovering) {},
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 48,
                            color: isFocused
                                ? NextvColors.accent
                                : Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isFocused
                                  ? NextvColors.accent
                                  : Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient, // Mantener firma pero ignorar
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return Container(
              height: 120,
              decoration: BoxDecoration(
                color: NextvColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isFocused
                    ? Border.all(color: NextvColors.accent, width: 2)
                    : Border.all(color: Colors.white10),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: NextvColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 56,
                          color: isFocused
                              ? NextvColors.accent
                              : Colors.white,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isFocused
                                      ? NextvColors.accent
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isFocused
                              ? NextvColors.accent
                              : Colors.white60,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Gradient gradient, // Mantener firma pero ignorar
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return Container(
              height: 140,
              decoration: BoxDecoration(
                color: NextvColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isFocused
                    ? Border.all(color: NextvColors.accent, width: 2)
                    : Border.all(color: Colors.white10),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: NextvColors.accent.withOpacity(0.3),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 48,
                        color: isFocused
                            ? NextvColors.accent
                            : Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isFocused
                              ? NextvColors.accent
                              : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToCategory(
    BuildContext context,
    WidgetRef ref,
    int tabIndex, {
    bool sportsOnly = false,
    bool favoritesOnly = false,
  }) {
    // Set the active tab
    ref.read(selectedTabProvider.notifier).state = tabIndex;

    // Navigate to main screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NovaMainScreen(),
      ),
    );
  }
}
