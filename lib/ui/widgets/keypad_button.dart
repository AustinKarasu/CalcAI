import 'package:flutter/material.dart';

class KeypadButton extends StatelessWidget {
  const KeypadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isAccent = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: isAccent
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: isAccent
                ? null
                : theme.colorScheme.surface.withValues(alpha: 0.92),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isAccent ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
