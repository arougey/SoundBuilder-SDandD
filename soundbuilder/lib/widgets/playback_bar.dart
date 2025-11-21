// lib/widgets/playback_bar.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundbuilder/providers/audio_providers.dart';
import 'package:soundbuilder/core/theme.dart';
import 'dense_slider_row.dart';

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
      color: AppTheme.nearblack,
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
                  if (svc.isPlaying)
                  IconButton(
                    key: const ValueKey('stop'),
                    icon: const Icon(Icons.stop),
                    onPressed: svc.stopAll),
                ],
              ),
            ),

            // 2) Collapsible control slab (animated)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: svc.volume,
                    builder: (_, value, __) => DenseSliderRow(
                      icon: Icons.volume_up,
                      value: value,
                      min: 0,
                      max: 3,
                      center: 1.0,
                      onChanged: svc.setVolume,
                    ),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: svc.speed,
                    builder: (_, value, __) => DenseSliderRow(
                      icon: Icons.speed,
                      value: value,
                      min: 0,
                      max: 3.0,
                      center: 1.0,
                      onChanged: svc.setSpeed,
                    ),
                  ),
                  /*
                  ValueListenableBuilder<double>(
                    valueListenable: svc.pitch,
                    builder: (_, value, __) => DenseSliderRow(
                      icon: Icons.graphic_eq,
                      value: value,
                      min: 0,
                      max: 2,
                      center: 1.0,
                      onChanged: svc.setPitch,
                    ),
                  ),
                  */
                  ValueListenableBuilder<double>(
                    valueListenable: svc.pan,
                    builder: (_, value, __) => DenseSliderRow(
                      icon: Icons.pan_tool,
                      value: value,
                      min: -1.0,
                      max: 1.0,
                      center: 0.0,
                      onChanged: svc.setPan,
                    ),
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