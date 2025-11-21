import 'package:flutter/material.dart';
import 'package:soundbuilder/models/sound.dart';
import 'package:soundbuilder/core/theme.dart';

class SoundCard extends StatelessWidget {
  final Sound sound;
  final bool isPlaying;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onAdd;

  const SoundCard({
    super.key,
    required this.sound,
    this.isPlaying = false,
    this.onToggle,
    this.onDelete,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // Choose a text style with small line-height so it doesn't add extra top/bottom space
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontSize: 16, height: 1.1);

    Widget compactIconBtn(IconData icon, VoidCallback? onPressed, {Color? color}) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        padding: EdgeInsets.zero,                                   // no extra padding
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // < 48
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        splashRadius: 18,
      );
    }

    return Card(
      color: AppTheme.calmgrey.withAlpha(230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), // no vertical margin
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12), // no vertical padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // center children vertically
          children: [
            Icon(Icons.audiotrack, size: 20, color: AppTheme.nearblack),
            const SizedBox(width: 8),

            // Name
            Expanded(
              child: Text(
                sound.name,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Actions (all compact)
            if (onToggle != null)
              compactIconBtn(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                onToggle,
                color: AppTheme.nearblack,
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              compactIconBtn(Icons.delete, onDelete, color: AppTheme.nearblack),
            ],
            if (onAdd != null) ...[
              const SizedBox(width: 4),
              compactIconBtn(Icons.add_circle, onAdd, color: AppTheme.nearblack),
            ],
          ],
        ),
      ),
    );
  }
}