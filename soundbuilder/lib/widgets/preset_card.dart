// lib/widgets/build_card.dart

import 'package:flutter/material.dart';
import 'package:soundbuilder/core/theme.dart';
import 'package:soundbuilder/models/preset.dart';

/// A card displaying a saved preset/build with controls for play, stop, share, and delete.
/// This card will show in the first column on playsounds page
class PresetCard extends StatelessWidget {
  /// The preset data (name, id, list of layers).
  final Preset preset;

  /// Whether this preset is currently playing
  final bool isPlaying;

  final VoidCallback onPlay;
  final VoidCallback onStop;
  final VoidCallback onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PresetCard({
    super.key,
    required this.preset,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
    required this.onShare,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withAlpha(230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            // Headphone icon for the build
            const Icon(Icons.headset, size: 28, color: AppTheme.primary),
            const SizedBox(width: 12),
            // Build name
            Expanded(
              child: Text(
                preset.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            // Play / Stop
            IconButton(
              icon: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
                color: AppTheme.secondary,
              ),
              onPressed: isPlaying ? onStop : onPlay,
            ),

            // Share button
            IconButton(
              icon: const Icon(Icons.share),
              color: AppTheme.onSurface,
              onPressed: onShare,
            ),

            // Optional edit
            if (onEdit != null) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                color: AppTheme.onSurface,
                onPressed: onEdit,
              ),
            ],

            // Optional delete
            if (onDelete != null) ...[
              IconButton(
                icon: const Icon(Icons.delete),
                color: AppTheme.onSurface,
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
