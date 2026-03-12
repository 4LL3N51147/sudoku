import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool skipHintAnimation;
  final bool showAdvancedHints;

  static const bool _defaultSkipAnimation = false;
  static const bool _defaultShowAdvancedHints = false;

  static const String _keySkipAnimation = 'skip_hint_animation';
  static const String _keyShowAdvancedHints = 'show_advanced_hints';

  const AppSettings({
    this.skipHintAnimation = _defaultSkipAnimation,
    this.showAdvancedHints = _defaultShowAdvancedHints,
  });

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      skipHintAnimation: prefs.getBool(_keySkipAnimation) ?? _defaultSkipAnimation,
      showAdvancedHints: prefs.getBool(_keyShowAdvancedHints) ?? _defaultShowAdvancedHints,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySkipAnimation, skipHintAnimation);
    await prefs.setBool(_keyShowAdvancedHints, showAdvancedHints);
  }

  AppSettings copyWith({
    bool? skipHintAnimation,
    bool? showAdvancedHints,
  }) {
    return AppSettings(
      skipHintAnimation: skipHintAnimation ?? this.skipHintAnimation,
      showAdvancedHints: showAdvancedHints ?? this.showAdvancedHints,
    );
  }
}
