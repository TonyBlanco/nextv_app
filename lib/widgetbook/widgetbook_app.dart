import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nextv_app/core/constants/nextv_colors.dart';
import 'package:nextv_app/presentation/widgets/nextv_logo.dart';
import 'package:nextv_app/presentation/widgets/live_indicator_badge.dart';
import 'package:nextv_app/presentation/widgets/favorite_button.dart';
import 'package:nextv_app/presentation/widgets/premium_top_bar.dart';

/// NexTV Widgetbook - Catálogo visual de componentes UI
///
/// Ejecutar con: flutter run -t lib/widgetbook/widgetbook_app.dart
void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        // === Branding ===
        WidgetbookCategory(
          name: 'Branding',
          children: [
            WidgetbookComponent(
              name: 'NexTV Logo',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(child: NextvLogo()),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Small',
                  builder: (context) => const Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(child: NextvLogo(size: 24)),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Large',
                  builder: (context) => const Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(child: NextvLogo(size: 64)),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Colors',
              useCases: [
                WidgetbookUseCase(
                  name: 'Palette',
                  builder: (context) => Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _colorSwatch('Background', NextvColors.background),
                          _colorSwatch('Surface', NextvColors.surface),
                          _colorSwatch('Accent', NextvColors.accent),
                          _colorSwatch('Accent Bright', NextvColors.accentBright),
                          _colorSwatch('Text Primary', NextvColors.textPrimary),
                          _colorSwatch('Text Secondary', NextvColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // === Indicators ===
        WidgetbookCategory(
          name: 'Indicators',
          children: [
            WidgetbookComponent(
              name: 'Live Badge',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(child: LiveIndicatorBadge()),
                  ),
                ),
              ],
            ),
          ],
        ),

        // === Buttons ===
        WidgetbookCategory(
          name: 'Buttons',
          children: [
            WidgetbookComponent(
              name: 'Accent Button',
              useCases: [
                WidgetbookUseCase(
                  name: 'Primary',
                  builder: (context) => Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NextvColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Watch Now'),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Outlined',
                  builder: (context) => Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NextvColors.accent,
                          side: const BorderSide(color: NextvColors.accent),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Add to List'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // === Typography ===
        WidgetbookCategory(
          name: 'Typography',
          children: [
            WidgetbookComponent(
              name: 'Text Styles',
              useCases: [
                WidgetbookUseCase(
                  name: 'Hierarchy',
                  builder: (context) => Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Heading 1', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: NextvColors.textPrimary)),
                          const SizedBox(height: 12),
                          Text('Heading 2', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: NextvColors.textPrimary)),
                          const SizedBox(height: 12),
                          Text('Heading 3', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: NextvColors.textPrimary)),
                          const SizedBox(height: 12),
                          Text('Body Text', style: GoogleFonts.inter(fontSize: 14, color: NextvColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text('Secondary Text', style: GoogleFonts.inter(fontSize: 14, color: NextvColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Caption', style: GoogleFonts.inter(fontSize: 12, color: NextvColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // === Cards ===
        WidgetbookCategory(
          name: 'Cards',
          children: [
            WidgetbookComponent(
              name: 'Channel Card',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => Scaffold(
                    backgroundColor: NextvColors.background,
                    body: Center(
                      child: SizedBox(
                        width: 200,
                        child: Card(
                          color: NextvColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: NextvColors.accent.withOpacity(0.2),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: const Center(child: Icon(Icons.live_tv, size: 48, color: NextvColors.accent)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ESPN HD', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: NextvColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('Sports', style: GoogleFonts.inter(fontSize: 12, color: NextvColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      themes: [
        WidgetbookTheme(
          name: 'Dark (Default)',
          data: ThemeData(
            brightness: Brightness.dark,
            primaryColor: NextvColors.accent,
            scaffoldBackgroundColor: NextvColors.background,
          ),
        ),
      ],
    );
  }
}

Widget _colorSwatch(String name, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
      ),
      const SizedBox(height: 6),
      Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(
        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        style: const TextStyle(color: Colors.white38, fontSize: 10),
      ),
    ],
  );
}
