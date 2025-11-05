import 'package:flutter/material.dart';
import 'package:soundbuilder/models/sound.dart';
import 'package:soundbuilder/core/theme.dart';

/// A card displaying a single sound with toggle, volume slider, and optional delete.
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
    return Card(
      color: AppTheme.surface.withAlpha(230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Sound icon or default icon
                Icon(Icons.audiotrack, size: 24, color: AppTheme.primary),

                const SizedBox(width: 12),
                // Sound name
                Expanded(
                  child: Text(
                    sound.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),

                // Toggle playback
                if (onToggle != null) ...[
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: AppTheme.secondary,
                    ),
                    onPressed: onToggle,
                  ),
                ],

                // Optional delete button if in build
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: AppTheme.onSurface,
                    onPressed: onDelete,
                  ),
                ],

                // Optional add button if in build
                if (onAdd != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: AppTheme.primaryVariant,
                    onPressed: onAdd,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
