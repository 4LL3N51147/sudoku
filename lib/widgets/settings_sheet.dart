import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../build_info.dart';

class SettingsSheet extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late bool _skipAnimation;
  late bool _showAdvancedHints;

  @override
  void initState() {
    super.initState();
    _skipAnimation = widget.settings.skipHintAnimation;
    _showAdvancedHints = widget.settings.showAdvancedHints;
  }

  @override
  void didUpdateWidget(SettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      setState(() {
        _skipAnimation = widget.settings.skipHintAnimation;
        _showAdvancedHints = widget.settings.showAdvancedHints;
      });
    }
  }

  void _update({bool? skipAnimation, bool? showAdvancedHints}) {
    final newSkipAnimation = skipAnimation ?? _skipAnimation;
    final newShowAdvancedHints = showAdvancedHints ?? _showAdvancedHints;
    setState(() {
      _skipAnimation = newSkipAnimation;
      _showAdvancedHints = newShowAdvancedHints;
    });
    widget.onChanged(AppSettings(
      skipHintAnimation: newSkipAnimation,
      showAdvancedHints: newShowAdvancedHints,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'HINTS',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text('Skip Animation', style: TextStyle(fontSize: 14)),
                ),
                Switch(
                  value: _skipAnimation,
                  onChanged: (v) => _update(skipAnimation: v),
                  activeTrackColor: const Color(0xFF1A237E).withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF1A237E);
                    }
                    return null;
                  }),
                ),
              ],
            ),
            Row(
              children: [
                const Expanded(
                  child: Text('Show Advanced Hints', style: TextStyle(fontSize: 14)),
                ),
                Switch(
                  value: _showAdvancedHints,
                  onChanged: (v) => _update(showAdvancedHints: v),
                  activeTrackColor: const Color(0xFF1A237E).withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF1A237E);
                    }
                    return null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Version'),
              trailing: Text(
                BuildInfo.version,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Build'),
              trailing: Text(
                BuildInfo.buildTime,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Commit'),
              trailing: Text(
                BuildInfo.commit,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
