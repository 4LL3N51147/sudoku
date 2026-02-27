import 'package:flutter/material.dart';
import '../app_settings.dart';

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
  late int _scanMs;
  late int _eliminationMs;
  late int _targetMs;

  @override
  void initState() {
    super.initState();
    _scanMs = widget.settings.hintScanMs;
    _eliminationMs = widget.settings.hintEliminationMs;
    _targetMs = widget.settings.hintTargetMs;
  }

  @override
  void didUpdateWidget(SettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings) {
      setState(() {
        _scanMs = widget.settings.hintScanMs;
        _eliminationMs = widget.settings.hintEliminationMs;
        _targetMs = widget.settings.hintTargetMs;
      });
    }
  }

  void _update({int? scan, int? elimination, int? target}) {
    final newScan = scan ?? _scanMs;
    final newElimination = elimination ?? _eliminationMs;
    final newTarget = target ?? _targetMs;
    setState(() {
      _scanMs = newScan;
      _eliminationMs = newElimination;
      _targetMs = newTarget;
    });
    widget.onChanged(AppSettings(
      hintScanMs: newScan,
      hintEliminationMs: newElimination,
      hintTargetMs: newTarget,
    ));
  }

  String _label(int ms) => '${(ms / 1000).toStringAsFixed(1)}s';

  Widget _slider({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(title, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 500,
            max: 4000,
            divisions: 7,
            onChanged: (v) => onChanged(v.round()),
            activeColor: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(_label(value), style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            'HINT ANIMATION',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _slider(
            title: 'Scan',
            value: _scanMs,
            onChanged: (v) => _update(scan: v),
          ),
          _slider(
            title: 'Elimination',
            value: _eliminationMs,
            onChanged: (v) => _update(elimination: v),
          ),
          _slider(
            title: 'Target',
            value: _targetMs,
            onChanged: (v) => _update(target: v),
          ),
        ],
      ),
    );
  }
}
