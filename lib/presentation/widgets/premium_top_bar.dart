import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'nextv_logo.dart';

/// Premium top bar with modern design, hover effects, and glassmorphism
class PremiumTopBar extends StatefulWidget {
  final int selectedTab;
  final Function(int) onTabChanged;
  final VoidCallback onSettingsPressed;
  final VoidCallback onParentalPressed;
  final bool showVPNIndicator;
  final bool tvMode;

  const PremiumTopBar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onSettingsPressed,
    required this.onParentalPressed,
    this.showVPNIndicator = false,
    this.tvMode = false,
  });

  @override
  State<PremiumTopBar> createState() => _PremiumTopBarState();
}

class _PremiumTopBarState extends State<PremiumTopBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  int? _hoveredTab;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.tvMode ? 80 : 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0a0e27),
            const Color(0xFF1a1f3a),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: NextvColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // NeXtv Logo with animated glow
            _buildAnimatedLogo(),
            const SizedBox(width: 32),
            // Tab Navigation
            Expanded(child: _buildTabNavigation()),
            const SizedBox(width: 16),
            // VPN Indicator (if enabled)
            if (widget.showVPNIndicator) ...[
              _buildVPNIndicator(),
              const SizedBox(width: 12),
            ],
            // Parental Control
            _buildIconButton(
              icon: Icons.lock_outline,
              tooltip: 'Control Parental',
              onPressed: widget.onParentalPressed,
            ),
            const SizedBox(width: 8),
            // Settings
            _buildIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: widget.onSettingsPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: NextvColors.accent.withOpacity(
                  0.2 + (_glowController.value * 0.2),
                ),
                blurRadius: 15 + (_glowController.value * 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: const NextvLogo(
            size: 36,
            showText: true,
            withGlow: false,
          ),
        );
      },
    );
  }

  Widget _buildTabNavigation() {
    final tabs = [
      _TabData(label: 'Live TV', icon: Icons.live_tv_rounded, index: 0),
      _TabData(label: 'Movies', icon: Icons.movie_rounded, index: 1),
      _TabData(label: 'Series', icon: Icons.video_library_rounded, index: 2),
      _TabData(label: 'Catch up', icon: Icons.history_rounded, index: 3),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: tabs.map((tab) => _buildTab(tab)).toList(),
    );
  }

  Widget _buildTab(_TabData tab) {
    final isSelected = widget.selectedTab == tab.index;
    final isHovered = _hoveredTab == tab.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTab = tab.index),
      onExit: (_) => setState(() => _hoveredTab = null),
      child: GestureDetector(
        onTap: () => widget.onTabChanged(tab.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      const Color(0xFF8b5cf6),
                      const Color(0xFF06b6d4),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : isHovered
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected || isHovered
                ? [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF8b5cf6).withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                      blurRadius: isSelected ? 15 : 8,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.identity()
            ..scale(isHovered && !isSelected ? 1.05 : 1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : isHovered
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF6b7280),
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isHovered
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF6b7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVPNIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: Colors.green[400],
          ),
          const SizedBox(width: 6),
          Text(
            'VPN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF9ca3af),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabData {
  final String label;
  final IconData icon;
  final int index;

  _TabData({
    required this.label,
    required this.icon,
    required this.index,
  });
}
