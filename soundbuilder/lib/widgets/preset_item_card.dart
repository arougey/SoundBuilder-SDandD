//lib/widgets/preset_item_card.dart
/*
This file represents the card of each preset item in the left column of the build sound screen
*/
import 'package:flutter/material.dart';
import 'package:soundbuilder/core/theme.dart';
import 'package:soundbuilder/models/preset_item.dart';
import 'package:soundbuilder/widgets/dense_slider_row.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.nearblack.withAlpha(230),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.audiotrack, size: 24, color: AppTheme.nearblack),
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
            DenseSliderRow( 
              icon: Icons.volume_up,
              value: presetitem.volume,
              min: 0.0,
              max: 3.0,
              center: 1.0,
              onChanged: (v) => onVolumeChanged(v.clamp(0.0, 3.0)),
            ),

            // Speed Slider
            DenseSliderRow( 
              icon: Icons.speed,
              value: presetitem.speed,
              min: 0.0,
              max: 3.0,
              center: 1.0,
              onChanged: (v) => onSpeedChanged(v.clamp(0.0, 3.0)),
            ),

            // Pitch Slider
            DenseSliderRow( 
              icon: Icons.graphic_eq,
              value: presetitem.pitch,
              min: 0.0,
              max: 2.0,
              center: 1.0,
              onChanged: (v) => onPitchChanged(v.clamp(0.0, 2.0)),
            ),

            // Pan Slider
            DenseSliderRow( 
              icon: Icons.pan_tool,
              value: presetitem.pan,
              min: -1.0,
              max: 1.0,
              center: 0.0,
              onChanged: (v) => onPanChanged(v.clamp(-1.0, 1.0)),
            ),

          ],
        ),
      ),
    );
  }
}
