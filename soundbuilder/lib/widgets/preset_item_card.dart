//lib/widgets/preset_item_card.dart
/*
This file represents the card of each preset item in the left column of the build sound screen
*/

import 'package:flutter/material.dart';
import 'package:soundbuilder/core/theme.dart';
import 'package:soundbuilder/models/preset_item.dart'; // the class above

class PresetItemCard extends StatelessWidget {
  final PresetItem presetitem;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onPitchChanged;
  final ValueChanged<double> onPanChanged;
  final VoidCallback onDelete;

  const PresetItemCard({
    super.key,
    required this.presetitem,
    required this.onVolumeChanged,
    required this.onSpeedChanged,
    required this.onPitchChanged,
    required this.onPanChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Define the dense slider theme
    final denseSliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 2,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    );

    // Define the label
    Text label(String s) => Text(
      s,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .75),
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.surface.withAlpha(230),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.audiotrack, size: 24, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    presetitem.soundName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 8),

            // Volume Slider
            Row(
              children: [
                label('Volume'),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: denseSliderTheme,
                    child: Slider(
                      min: 0.0,
                      max: 1.0,
                      value: presetitem.volume.clamp(0.0, 1.0),
                      onChanged: (v) => onVolumeChanged(v.clamp(0.0, 1.0)),
                    ),
                  ),
                ),
              ],
            ),

            // Speed Slider
            Row(
              children: [
                label('Speed'),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: denseSliderTheme,
                    child: Slider(
                      min: .5,
                      max: 2.0,
                      divisions: 100,
                      value: presetitem.speed.clamp(.5, 2.0),
                      onChanged: (v) => onSpeedChanged(v.clamp(.5, 2.0)),
                    ),
                  ),
                ),
              ],
            ),

            // Pitch Slider
            Row(
              children: [
                label('Pitch'),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: denseSliderTheme,
                    child: Slider(
                      min: .5,
                      max: 2.0,
                      divisions: 100,
                      value: presetitem.pitch.clamp(.5, 2.0),
                      onChanged: (v) => onPitchChanged(v.clamp(.5, 2.0)),
                    ),
                  ),
                ),
              ],
            ),

            // Pan Slider
            Row(
              children: [
                label('Pan'),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: denseSliderTheme,
                    child: Slider(
                      min: -1.0,
                      max: 1.0,
                      value: presetitem.pan,
                      onChanged: (v) => onPanChanged(v.clamp(-1.0, 1.0)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
