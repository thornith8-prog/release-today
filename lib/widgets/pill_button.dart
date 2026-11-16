import 'package:flutter/material.dart';

import '../core/theme.dart';

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed, this.filled = false});

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 16);
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: padding,
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.line),
        padding: padding,
      ),
      child: Text(label),
    );
  }
}
