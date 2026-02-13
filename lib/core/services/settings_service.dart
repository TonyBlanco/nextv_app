import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final String preferredPlayer; // 'better_player' or 'vlc'
  final String playerType; // 'better', 'vlc', 'external'
  final String locale; // language code
  final bool vpnEnabled; // VPN status
  final String epgUrl; // EPG URL
  final String vpnCountry; // VPN country
  final bool tvMode; // TV Sofa Mode for remote control optimization
  final String streamFormat; // 'auto', 'hls', 'mpegts'
  
  AppSettings({
    required this.preferredPlayer,
    this.playerType = 'better',
    this.locale = 'en',
    this.vpnEnabled = false,
    this.epgUrl = '',
    this.vpnCountry = '',
    this.tvMode = false,
    this.streamFormat = 'auto',
  });

  AppSettings copyWith({
    String? preferredPlayer,
    String? playerType,
    String? locale,
    bool? vpnEnabled,
    String? epgUrl,
    String? vpnCountry,
    bool? tvMode,
    String? streamFormat,
  }) {
    return AppSettings(
      preferredPlayer: preferredPlayer ?? this.preferredPlayer,
      playerType: playerType ?? this.playerType,
      locale: locale ?? this.locale,
      vpnEnabled: vpnEnabled ?? this.vpnEnabled,
      epgUrl: epgUrl ?? this.epgUrl,
      vpnCountry: vpnCountry ?? this.vpnCountry,
      tvMode: tvMode ?? this.tvMode,
      streamFormat: streamFormat ?? this.streamFormat,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings(preferredPlayer: 'better_player')) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final player = prefs.getString('preferred_player') ?? 'better_player';
    final playerType = prefs.getString('player_type') ?? 'better';
    final locale = prefs.getString('locale') ?? 'en';
    final vpnEnabled = prefs.getBool('vpn_enabled') ?? false;
    final epgUrl = prefs.getString('epg_url') ?? '';
    final vpnCountry = prefs.getString('vpn_country') ?? '';
    final tvMode = prefs.getBool('tv_mode') ?? false;
    final streamFormat = prefs.getString('stream_format') ?? 'auto';
    state = AppSettings(
      preferredPlayer: player,
      playerType: playerType,
      locale: locale,
      vpnEnabled: vpnEnabled,
      epgUrl: epgUrl,
      vpnCountry: vpnCountry,
      tvMode: tvMode,
      streamFormat: streamFormat,
    );
  }

  Future<void> setPlayer(String player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_player', player);
    state = state.copyWith(preferredPlayer: player);
  }

  Future<void> setPlayerType(String playerType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_type', playerType);
    state = state.copyWith(playerType: playerType);
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    state = state.copyWith(locale: locale);
  }

  Future<void> setVpnEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vpn_enabled', enabled);
    state = state.copyWith(vpnEnabled: enabled);
  }

  Future<void> setEpgUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epg_url', url);
    state = state.copyWith(epgUrl: url);
  }

  Future<void> setVpnCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vpn_country', country);
    state = state.copyWith(vpnCountry: country);
  }

  Future<void> setTvMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tv_mode', enabled);
    state = state.copyWith(tvMode: enabled);
  }

  Future<void> setStreamFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stream_format', format);
    state = state.copyWith(streamFormat: format);
  }
}
