import 'package:flutter/material.dart';

/// A banner widget that displays hint messages with an optional Next button.
class HintBanner extends StatelessWidget {
  final String message;
  final bool hasNextButton;
  final VoidCallback? onNextPressed;

  const HintBanner({
    super.key,
    required this.message,
    this.hasNextButton = false,
    this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A237E), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFF1A237E), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
            if (hasNextButton) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onNextPressed,
                child: const Text(
                  'Next \u2192',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
