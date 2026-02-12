import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings_service.dart';

/// TV Mode Components - Optimized for remote control and TV viewing
/// with full D-Pad navigation support

/// TVFocusWrapper - Universal wrapper for D-Pad navigation
/// Provides visual feedback and animation when focused with remote control
class TVFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final double scaleOnFocus;
  final EdgeInsetsGeometry? padding;
  final FocusNode? focusNode;
  final bool autofocus;

  const TVFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.scaleOnFocus = 1.05,
    this.padding,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<TVFocusWrapper> createState() => _TVFocusWrapperState();
}

class _TVFocusWrapperState extends State<TVFocusWrapper>
    with SingleTickerProviderStateMixin {
  late FocusNode _internalFocusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnFocus,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _internalFocusNode.hasFocus;
      if (_hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _internalFocusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _handleTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: _hasFocus
                      ? Border.all(
                          color: NextvColors.accent,
                          width: 3,
                        )
                      : null,
                  boxShadow: _hasFocus
                      ? [
                          BoxShadow(
                            color: NextvColors.accent.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class TvModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;
  final double size;
  final FocusNode? focusNode;
  final bool autofocus;

  const TvModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
    this.size = 80,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        final isTvMode = settings.tvMode;

        if (!isTvMode) {
          // Normal button for non-TV mode
          return IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            tooltip: label,
          );
        }

        // Large TV-optimized button with D-Pad navigation
        return TVFocusWrapper(
          onTap: onPressed,
          isSelected: isSelected,
          focusNode: focusNode,
          autofocus: autofocus,
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? NextvColors.accent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? NextvColors.accent
                    : Colors.white.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: size * 0.4,
                  color: isSelected ? NextvColors.accent : Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? NextvColors.accent : Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TvModeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  const TvModeCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        final isTvMode = settings.tvMode;

        final cardPadding = padding ??
            (isTvMode ? const EdgeInsets.all(24) : const EdgeInsets.all(16));

        final cardChild = Card(
          color: NextvColors.surface,
          margin: EdgeInsets.symmetric(
              vertical: isTvMode ? 12 : 8, horizontal: isTvMode ? 8 : 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTvMode ? 16 : 8),
          ),
          child: Padding(
            padding: cardPadding,
            child: this.child,
          ),
        );

        if (!isTvMode || onTap == null) {
          return cardChild;
        }

        // TV mode with D-Pad navigation
        return TVFocusWrapper(
          onTap: onTap,
          focusNode: focusNode,
          autofocus: autofocus,
          child: cardChild,
        );
      },
    );
  }
}

class TvModeListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final FocusNode? focusNode;
  final bool autofocus;

  const TvModeListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        final isTvMode = settings.tvMode;

        if (!isTvMode) {
          // Normal ListTile for non-TV mode
          return ListTile(
            leading: icon ?? const Icon(Icons.tv),
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle!) : null,
            trailing: trailing,
            onTap: onTap,
            selected: selected,
          );
        }

        // TV-optimized ListTile with D-Pad navigation
        return TVFocusWrapper(
          onTap: onTap,
          isSelected: selected,
          focusNode: focusNode,
          autofocus: autofocus,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? NextvColors.accent.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? NextvColors.accent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NextvColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: icon,
                  ),
                  const SizedBox(width: 20),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color:
                              selected ? NextvColors.accent : Colors.white,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing!,
                ],
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TvModeGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;

  const TvModeGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        final isTvMode = settings.tvMode;

        final gridCount = isTvMode ? (crossAxisCount + 1) : crossAxisCount;
        final aspectRatio = isTvMode ? 1.2 : childAspectRatio;

        return GridView.count(
          crossAxisCount: gridCount,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(isTvMode ? 16 : 8),
          mainAxisSpacing: isTvMode ? 16 : 8,
          crossAxisSpacing: isTvMode ? 16 : 8,
          children: children,
        );
      },
    );
  }
}

class TvModeNavigation extends StatelessWidget {
  final List<TvModeNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const TvModeNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        final isTvMode = settings.tvMode;

        if (!isTvMode) {
          // Normal bottom navigation
          return BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onItemSelected,
            items: items
                .map((item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ))
                .toList(),
            backgroundColor: NextvColors.surface,
            selectedItemColor: NextvColors.accent,
            unselectedItemColor: Colors.white38,
          );
        }

        // TV-optimized navigation with D-Pad support
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          color: NextvColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == selectedIndex;

              return TVFocusWrapper(
                onTap: () => onItemSelected(index),
                isSelected: isSelected,
                autofocus: index == 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NextvColors.accent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? NextvColors.accent
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 36,
                        color: isSelected
                            ? NextvColors.accent
                            : Colors.white70,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? NextvColors.accent
                              : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class TvModeNavItem {
  final String label;
  final IconData icon;

  const TvModeNavItem({
    required this.label,
    required this.icon,
  });
}

/// TvModeChannelCard - Optimized card for displaying channel information
/// with D-Pad navigation support
class TvModeChannelCard extends StatelessWidget {
  final String channelName;
  final String? channelNumber;
  final String? logoUrl;
  final String? currentProgram;
  final bool isSelected;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget? trailing;

  const TvModeChannelCard({
    super.key,
    required this.channelName,
    this.channelNumber,
    this.logoUrl,
    this.currentProgram,
    this.isSelected = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider);
        final isTvMode = settings.tvMode;

        if (!isTvMode) {
          // Compact mode for non-TV
          return Card(
            color: NextvColors.surface,
            child: ListTile(
              leading: logoUrl != null
                  ? Image.network(
                      logoUrl!,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.tv, size: 40),
                    )
                  : const Icon(Icons.tv, size: 40),
              title: Text(channelName),
              subtitle: currentProgram != null
                  ? Text(currentProgram!)
                  : (channelNumber != null ? Text('Ch. $channelNumber') : null),
              trailing: trailing,
              onTap: onTap,
              selected: isSelected,
            ),
          );
        }

        // TV-optimized large card with D-Pad navigation
        return TVFocusWrapper(
          onTap: onTap,
          isSelected: isSelected,
          focusNode: focusNode,
          autofocus: autofocus,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? NextvColors.accent.withOpacity(0.2)
                  : NextvColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? NextvColors.accent
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: NextvColors.accent.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Channel logo or icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            logoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.tv, size: 40, color: Colors.white70),
                          ),
                        )
                      : const Icon(Icons.tv, size: 40, color: Colors.white70),
                ),
                const SizedBox(width: 20),
                // Channel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (channelNumber != null)
                        Text(
                          'CH. $channelNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? NextvColors.accent
                                : Colors.white60,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        channelName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? NextvColors.accent : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (currentProgram != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.live_tv,
                              size: 14,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                currentProgram!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// TvModePlayerControls - Full-screen player controls optimized for TV
class TvModePlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNextChannel;
  final VoidCallback? onPreviousChannel;
  final VoidCallback? onShowChannelList;
  final VoidCallback? onShowSettings;
  final String? currentChannelName;
  final String? currentChannelNumber;

  const TvModePlayerControls({
    super.key,
    required this.isPlaying,
    this.onPlayPause,
    this.onNextChannel,
    this.onPreviousChannel,
    this.onShowChannelList,
    this.onShowSettings,
    this.currentChannelName,
    this.currentChannelNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar with channel info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (currentChannelNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: NextvColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentChannelNumber!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                if (currentChannelName != null)
                  Expanded(
                    child: Text(
                      currentChannelName!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                TVFocusWrapper(
                  onTap: onShowSettings,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TVFocusWrapper(
                  onTap: onPreviousChannel,
                  autofocus: true,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(width: 24),
                TVFocusWrapper(
                  onTap: onPlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: NextvColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                TVFocusWrapper(
                  onTap: onNextChannel,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.skip_next, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(width: 48),
                TVFocusWrapper(
                  onTap: onShowChannelList,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.list, color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}