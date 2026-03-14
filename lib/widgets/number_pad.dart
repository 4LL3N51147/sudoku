import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final void Function(int) onNumber;
  final void Function() onErase;
  final void Function() onTogglePencilMode;
  final Set<int>? disabledDigits;
  final bool isPencilMode;

  const NumberPad({
    super.key,
    required this.onNumber,
    required this.onErase,
    required this.onTogglePencilMode,
    this.disabledDigits,
    this.isPencilMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Number buttons row with toggle
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...List.generate(
          9,
          (i) {
            final digit = i + 1;
            final isDisabled = disabledDigits?.contains(digit) ?? false;
            return _PadButton(
              label: '$digit',
              onTap: () => onNumber(digit),
              isDisabled: isDisabled,
            );
          },
        ),
        _PadButton(
          icon: Icons.backspace_outlined,
          onTap: onErase,
        ),
        _ToggleButton(
          isPencilMode: isPencilMode,
          onTap: onTogglePencilMode,
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isPencilMode;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.isPencilMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: isPencilMode
                ? const Color(0xFF1A237E)
                : const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              isPencilMode ? Icons.create : Icons.edit,
              size: 20,
              color: isPencilMode ? Colors.white : const Color(0xFF1A237E),
            ),
          ),
        ),
      ),
    );
  }
}

class _PadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDisabled;

  const _PadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: isDisabled
                ? const Color(0xFFE8EAF6).withValues(alpha: 0.4)
                : const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A237E),
                    ),
                  )
                : const Icon(
                    Icons.backspace_outlined,
                    color: Color(0xFF1A237E),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
