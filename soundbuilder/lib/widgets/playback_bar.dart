// lib/widgets/playback_bar.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundbuilder/providers/audio_providers.dart';
import 'package:soundbuilder/core/theme.dart';

class PlaybackBar extends ConsumerStatefulWidget {
  const PlaybackBar({super.key});

  @override
  ConsumerState<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends ConsumerState<PlaybackBar> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(audioServiceProvider);

    return Material(
      elevation: 4,
      color: AppTheme.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiny arrow toggle at the very top
            Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                tooltip: _expanded ? 'Hide controls' : 'Show controls',
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ),

            // 1) Now playing label + stop button
            ValueListenableBuilder<String>(
              valueListenable: svc.nowPlaying,
              builder: (_, title, __) => Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.timer),
                    label: const Text('Sleep Timer'),
                    onPressed: () async {
                      final minutes = await showDialog<int>(
                        context: context,
                        builder: (_) => _SleepTimerDialog(),
                      );
                      if (minutes != null) {
                        svc.setSleepTimer(Duration(minutes: minutes));
                      }
                    },
                  ),
                  IconButton(icon: const Icon(Icons.stop), onPressed: svc.stopAll),
                ],
              ),
            ),

            // 2) Collapsible control slab (animated)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  _DenseSliderRow(
                    icon: Icons.volume_up,
                    label: 'Volume',
                    valueListenable: svc.volume,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    onChanged: svc.setVolume,
                  ),
                  _DenseSliderRow(
                    icon: Icons.speed,
                    label: 'Speed',
                    valueListenable: svc.speed,
                    min: .5,
                    max: 2.0,
                    divisions: 100,
                    onChanged: svc.setSpeed,
                  ),
                  _DenseSliderRow(
                    icon: Icons.music_note,
                    label: 'Pitch',
                    valueListenable: svc.pitch,
                    min: .5,
                    max: 2.0,
                    divisions: 100,
                    onChanged: svc.setPitch,
                  ),
                  _DenseSliderRow(
                    icon: Icons.pan_tool,
                    label: 'Pan',
                    valueListenable: svc.pan,
                    min: -1.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: svc.setPan,
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _DenseSliderRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final ValueListenable<double> valueListenable;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _DenseSliderRow({
    required this.icon,
    this.label,
    required this.valueListenable,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 2,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    );

    return ValueListenableBuilder<double>(
      valueListenable: valueListenable,
      builder: (_, v, __) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .7),
                      ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: sliderTheme,
              child: Slider(
                min: min,
                max: max,
                divisions: divisions,
                value: v,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepTimerDialog extends StatefulWidget {
  @override
  State<_SleepTimerDialog> createState() => __SleepTimerDialogState();
}

class __SleepTimerDialogState extends State<_SleepTimerDialog> {
  int _mins = 10;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Sleep Timer'),
      content: Row(
        children: [
          Expanded(
            child: Slider(
              min: 1,
              max: 60,
              divisions: 59,
              label: '$_mins min',
              value: _mins.toDouble(),
              onChanged: (v) => setState(() => _mins = v.round()),
            ),
          ),
          Text('$_mins'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _mins),
          child: const Text('OK'),
        ),
      ],
    );
  }
}