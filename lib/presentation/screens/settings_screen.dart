import 'package:flutter/material.dart';
import '../../core/constants/nextv_colors.dart';
import '../../core/constants/app_strings.dart'; // Import AppStrings
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/services/settings_service.dart';
import '../widgets/nextv_logo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  final _epgController = TextEditingController();
  final _searchController = TextEditingController();
  double? _downloadSpeed;
  double? _uploadSpeed;
  bool _testingSpeed = false;
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _epgController.text = settings.epgUrl;
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _epgController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runSpeedTest() async {
    setState(() => _testingSpeed = true);
    try {
      final dio = Dio();
      final stopwatch = Stopwatch()..start();
      
      // Download test (5MB file from Cloudflare)
      await dio.get('https://speed.cloudflare.com/__down?bytes=5000000');
      stopwatch.stop();
      
      final downloadMbps = (5 * 8) / (stopwatch.elapsedMilliseconds / 1000);
      
      setState(() {
        _downloadSpeed = downloadMbps;
        _uploadSpeed = downloadMbps * 0.3; // Estimate
      });
    } catch (e) {
      debugPrint('Speed test error: $e');
    }
    setState(() => _testingSpeed = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    // Use AppStrings for translation
    String tr(String key) => AppStrings.get(key, settings.locale);

    return Scaffold(
      backgroundColor: NextvColors.background,
      appBar: AppBar(
        backgroundColor: NextvColors.surface,
        title: Text(tr('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NextvColors.accent,
          labelColor: NextvColors.accent,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.tune), text: 'General'),
            Tab(icon: const Icon(Icons.play_circle), text: tr('player_selection')),
            Tab(icon: const Icon(Icons.security), text: 'Security'),
            Tab(icon: const Icon(Icons.info), text: 'System'),
            const Tab(icon: Icon(Icons.tv), text: 'Display'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: NextvColors.surface,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('search'),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: NextvColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(tr, settings),
                _buildPlayerTab(tr, settings),
                _buildSecurityTab(tr, settings),
                _buildSystemTab(tr, settings),
                _buildDisplayTab(tr, settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(String Function(String) tr, AppSettings settings) {
    // Filter logic can be improved, but keeping simple for now
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(tr('language'), Icons.language, 'Choose app language'),
        Card(
          color: NextvColors.surface,
          child: Column(
            children: AppStrings.languages.entries.map((entry) {
              final isSelected = settings.locale == entry.key;
              return ListTile(
                title: Text(entry.value, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: NextvColors.accent) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLocale(entry.key);
                  setState(() {});
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('EPG', Icons.calendar_today, 'Configure electronic program guide'),
        Card(
          color: NextvColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EPG URL', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _epgController,
                  decoration: InputDecoration(
                    hintText: 'http://example.com/xmltv.php',
                    filled: true,
                    fillColor: NextvColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setEpgUrl(_epgController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('EPG URL saved!')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save EPG URL'),
                    style: ElevatedButton.styleFrom(backgroundColor: NextvColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerTab(String Function(String) tr, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(tr('player_selection'), Icons.play_circle, 'Choose video player'),
        Card(
          color: NextvColors.surface,
          child: Column(
            children: [
              _buildPlayerOption(
                title: 'ExoPlayer',
                subtitle: 'Android native player (fastest)',
                value: 'exoplayer',
                groupValue: settings.playerType,
                icon: Icons.android,
                onChanged: (v) => ref.read(settingsProvider.notifier).setPlayerType(v!),
              ),
              _buildPlayerOption(
                title: 'VLC',
                subtitle: 'Best compatibility for all formats',
                value: 'vlc',
                groupValue: settings.playerType,
                icon: Icons.video_library,
                onChanged: (v) => ref.read(settingsProvider.notifier).setPlayerType(v!),
              ),
              _buildPlayerOption(
                title: tr('external_player'),
                subtitle: 'Use MX Player, VLC, etc.',
                value: 'external',
                groupValue: settings.playerType,
                icon: Icons.open_in_new,
                onChanged: (v) => ref.read(settingsProvider.notifier).setPlayerType(v!),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader(tr('stream_format'), Icons.hd, 'Default stream quality'),
        Card(
          color: NextvColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildQualityOption('Auto', Icons.auto_mode, true),
                _buildQualityOption('4K', Icons.high_quality, false),
                _buildQualityOption('HD', Icons.hd, false),
                _buildQualityOption('SD', Icons.sd, false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTab(String Function(String) tr, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('VPN Protection', Icons.shield, 'Secure your connection'),
        Card(
          color: NextvColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: settings.vpnEnabled ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: settings.vpnEnabled ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        settings.vpnEnabled ? Icons.verified_user : Icons.warning,
                        color: settings.vpnEnabled ? Colors.green : Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.vpnEnabled ? 'VPN Connected' : 'VPN Disconnected',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            settings.vpnEnabled ? 'Protected • ${settings.vpnCountry}' : 'Not protected • Tap to enable',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          if (settings.vpnEnabled)
                            const Text(
                              '✓ Encrypted connection\n✓ IP hidden\n✓ Location masked',
                              style: TextStyle(color: Colors.green, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.vpnEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setVpnEnabled(v),
                      activeThumbColor: NextvColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!settings.vpnEnabled)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your connection is not protected. Enable VPN for secure streaming.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemTab(String Function(String) tr, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(tr('account'), Icons.info_outline, 'App Information'),
        Card(
          color: NextvColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: NextvColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.tv, color: NextvColors.accent, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const NextvLogo(size: 20, showText: true, withGlow: false),
                          const SizedBox(height: 4),
                          const Text('Version 1.0.0', style: TextStyle(color: Colors.white38)),
                          const Text('Premium IPTV Experience', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                _buildInfoRow('Build', '2024.02.06'),
                _buildInfoRow('Platform', 'Flutter'),
                _buildInfoRow('Architecture', 'Cross-platform'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton('Privacy Policy', Icons.privacy_tip, () {}),
                    _buildActionButton('Terms of Service', Icons.description, () {}),
                    _buildActionButton('Support', Icons.help, () {}),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('Storage', Icons.storage, 'Manage app data'),
        Card(
          color: NextvColors.surface,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services, color: NextvColors.accent),
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space', style: TextStyle(color: Colors.white38)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('Reset Settings'),
                subtitle: const Text('Restore default configuration', style: TextStyle(color: Colors.white38)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayTab(String Function(String) tr, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('TV Sofa Mode', Icons.tv, 'Optimize interface for TV viewing and remote control'),
        Card(
          color: NextvColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: settings.tvMode ? NextvColors.accent.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: settings.tvMode ? NextvColors.accent : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.tv,
                        color: settings.tvMode ? NextvColors.accent : Colors.grey,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TV Sofa Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: settings.tvMode ? Colors.white : Colors.white70,
                            ),
                          ),
                          const Text(
                            'Larger buttons, simplified navigation, remote-friendly interface',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          if (settings.tvMode) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NextvColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: NextvColors.accent, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'TV Mode Active',
                                    style: TextStyle(
                                      color: NextvColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Switch(
                      value: settings.tvMode,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setTvMode(v),
                      activeThumbColor: NextvColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (settings.tvMode) ...[
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  _buildTvModeFeature('Larger Touch Targets', '48px minimum button size', Icons.touch_app),
                  _buildTvModeFeature('Simplified Navigation', 'Streamlined menu system', Icons.navigation),
                  _buildTvModeFeature('Remote Control Optimized', 'D-pad and select button support', Icons.gamepad),
                  _buildTvModeFeature('High Contrast', 'Better visibility on TV screens', Icons.visibility),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('Display Settings', Icons.display_settings, 'Adjust visual preferences'),
        Card(
          color: NextvColors.surface,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6, color: NextvColors.accent),
                title: const Text('Theme'),
                subtitle: const Text('Dark theme optimized for TV', style: TextStyle(color: Colors.white38)),
                trailing: const Text('Dark', style: TextStyle(color: Colors.white70)),
                onTap: () {},
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.text_fields, color: NextvColors.accent),
                title: const Text('Font Size'),
                subtitle: const Text('Adjust text size for TV viewing', style: TextStyle(color: Colors.white38)),
                trailing: const Text('Large', style: TextStyle(color: Colors.white70)),
                onTap: () {},
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.aspect_ratio, color: NextvColors.accent),
                title: const Text('Screen Ratio'),
                subtitle: const Text('16:9 widescreen optimization', style: TextStyle(color: Colors.white38)),
                trailing: const Text('16:9', style: TextStyle(color: Colors.white70)),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTvModeFeature(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NextvColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: NextvColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: NextvColors.accent, size: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NextvColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: NextvColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? NextvColors.accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? NextvColors.accent : Colors.white70),
      ),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
      trailing: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: NextvColors.accent,
      ),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildQualityOption(String quality, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? NextvColors.accent : Colors.white70),
      title: Text(quality, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: NextvColors.accent) : null,
      onTap: () {
        // TODO: Implement quality selection
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildSpeedResult(String label, double speed, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: NextvColors.accent),
        const SizedBox(height: 8),
        Text('${speed.toStringAsFixed(1)} Mbps', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}

class _SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;

  _SettingsItem(this.title, this.subtitle, this.icon);
}
