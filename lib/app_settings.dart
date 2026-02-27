import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final int hintScanMs;
  final int hintEliminationMs;
  final int hintTargetMs;

  static const int _defaultScanMs = 1500;
  static const int _defaultEliminationMs = 2000;
  static const int _defaultTargetMs = 1500;

  static const String _keyScan = 'hint_scan_ms';
  static const String _keyElimination = 'hint_elimination_ms';
  static const String _keyTarget = 'hint_target_ms';

  const AppSettings({
    this.hintScanMs = _defaultScanMs,
    this.hintEliminationMs = _defaultEliminationMs,
    this.hintTargetMs = _defaultTargetMs,
  });

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      hintScanMs: (prefs.getInt(_keyScan) ?? _defaultScanMs).clamp(500, 4000),
      hintEliminationMs: (prefs.getInt(_keyElimination) ?? _defaultEliminationMs).clamp(500, 4000),
      hintTargetMs: (prefs.getInt(_keyTarget) ?? _defaultTargetMs).clamp(500, 4000),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScan, hintScanMs);
    await prefs.setInt(_keyElimination, hintEliminationMs);
    await prefs.setInt(_keyTarget, hintTargetMs);
  }

  AppSettings copyWith({
    int? hintScanMs,
    int? hintEliminationMs,
    int? hintTargetMs,
  }) {
    return AppSettings(
      hintScanMs: hintScanMs ?? this.hintScanMs,
      hintEliminationMs: hintEliminationMs ?? this.hintEliminationMs,
      hintTargetMs: hintTargetMs ?? this.hintTargetMs,
    );
  }
}
