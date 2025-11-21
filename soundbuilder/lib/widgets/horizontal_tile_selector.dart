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
        height: 0,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.mutedred
              : AppTheme.calmgrey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.nearblack : AppTheme.nearwhite,
            fontWeight: FontWeight.w600,
          ),

        ),
      ),
    );
  }
}
