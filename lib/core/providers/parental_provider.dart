import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentalSettings {
  final bool enabled;
  final String pin;
  final List<String> blockedCategories;

  const ParentalSettings({
    this.enabled = false,
    this.pin = '',
    this.blockedCategories = const [],
  });

  ParentalSettings copyWith({
    bool? enabled,
    String? pin,
    List<String>? blockedCategories,
  }) {
    return ParentalSettings(
      enabled: enabled ?? this.enabled,
      pin: pin ?? this.pin,
      blockedCategories: blockedCategories ?? this.blockedCategories,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'pin': pin,
    'blockedCategories': blockedCategories,
  };

  factory ParentalSettings.fromJson(Map<String, dynamic> json) => ParentalSettings(
    enabled: json['enabled'] ?? false,
    pin: json['pin'] ?? '',
    blockedCategories: List<String>.from(json['blockedCategories'] ?? []),
  );
}

class ParentalNotifier extends StateNotifier<ParentalSettings> {
  ParentalNotifier() : super(const ParentalSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('parental_enabled') ?? false;
    final pin = prefs.getString('parental_pin') ?? '';
    final blockedCategories = prefs.getStringList('blocked_categories') ?? [];

    state = ParentalSettings(
      enabled: enabled,
      pin: pin,
      blockedCategories: blockedCategories,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('parental_enabled', state.enabled);
    await prefs.setString('parental_pin', state.pin);
    await prefs.setStringList('blocked_categories', state.blockedCategories);
  }

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
    _saveSettings();
  }

  void setPin(String pin) {
    state = state.copyWith(pin: pin);
    _saveSettings();
  }

  void toggleCategory(String category) {
    final blocked = List<String>.from(state.blockedCategories);
    if (blocked.contains(category)) {
      blocked.remove(category);
    } else {
      blocked.add(category);
    }
    state = state.copyWith(blockedCategories: blocked);
    _saveSettings();
  }

  bool isCategoryBlocked(String category) {
    if (!state.enabled) return false;
    return state.blockedCategories.contains(category);
  }

  bool verifyPin(String inputPin) {
    return state.pin == inputPin;
  }
}

final parentalProvider = StateNotifierProvider<ParentalNotifier, ParentalSettings>((ref) {
  return ParentalNotifier();
});