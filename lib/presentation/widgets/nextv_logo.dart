import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';

/// Widget oficial del logo NeXtv.
/// Usa el PNG de marca NeXtv desde los assets, con fallback a texto.
class NextvLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool withGlow;

  const NextvLogo({
    super.key,
    this.size = 100.0,
    this.showText = true,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final double logoHeight = size;

    // Use PNG directly since SVG doesn't exist
    Widget logoImage = Image.asset(
      'assets/images/nextv_home.png',
      height: logoHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackLogo(logoHeight);
      },
    );

    if (withGlow) {
      logoImage = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.1),
          boxShadow: [
            BoxShadow(
              color: NextvColors.accent.withAlpha(60),
              blurRadius: size * 0.3,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.1),
          child: logoImage,
        ),
      );
    }

    return logoImage;
  }

  /// Fallback logo en caso de que no se carguen las imágenes
  Widget _buildFallbackLogo(double height) {
    final double fontSize = height * 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ne',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        Text(
          'X',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: NextvColors.accent,
            letterSpacing: -1.0,
          ),
        ),
        Text(
          'tv',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }
}
