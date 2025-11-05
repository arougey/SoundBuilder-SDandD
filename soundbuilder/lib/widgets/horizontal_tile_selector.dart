import 'package:flutter/material.dart';
import 'package:soundbuilder/core/theme.dart';

class HorizontalTileSelector extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const HorizontalTileSelector({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.secondary.withAlpha(30),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.onPrimary : AppTheme.onSecondary,
            fontWeight: FontWeight.w600,
          ),

        ),
      ),
    );
  }
}
