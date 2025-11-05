// lib/screens/build_sound_screen.dart
// Build Sound screen (responsive: stacks on phones, 2-pane on larger screens)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soundbuilder/core/theme.dart';

import 'package:soundbuilder/models/build_layer.dart';
import 'package:soundbuilder/models/preset.dart';
import 'package:soundbuilder/models/preset_item.dart';
import 'package:soundbuilder/models/sound.dart';

import 'package:soundbuilder/providers/audio_providers.dart';
import 'package:soundbuilder/providers/sound_providers.dart';

import 'package:soundbuilder/services/storage_service.dart';

import 'package:soundbuilder/widgets/horizontal_tile_selector.dart';
import 'package:soundbuilder/widgets/preset_item_card.dart';
import 'package:soundbuilder/widgets/sound_card.dart';

class BuildSoundScreen extends ConsumerStatefulWidget {
  final Preset? editPreset;
  const BuildSoundScreen({super.key, this.editPreset});

  @override
  ConsumerState<BuildSoundScreen> createState() => _BuildSoundScreenState();
}

class _BuildSoundScreenState extends ConsumerState<BuildSoundScreen> {
  String buildTitle = '';
  int _selectedCategory = 0;
  bool _isMixPlaying = false;

  // left-panel selected layers
  List<PresetItem> chosen = [];

  @override
  void initState() {
    super.initState();
    if (widget.editPreset != null) {
      buildTitle = widget.editPreset!.name;
      chosen = List.from(widget.editPreset!.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(audioServiceProvider);
    final soundAsync = ref.watch(allSoundsProvider);

    return soundAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Build a Sound')),
        body: Center(child: Text('Error loading sounds: $e')),
      ),
      data: (sounds) {
        // Derive categories dynamically from data (unique + sorted)
        final categories = sounds.map((s) => s.category).toSet().toList()
          ..sort();

        // Keep selected category index in range
        if (_selectedCategory >= categories.length && categories.isNotEmpty) {
          _selectedCategory = 0;
        }

        // Filter sounds by selected category (case-insensitive safety)
        final filteredSounds = (categories.isEmpty)
            ? <Sound>[]
            : sounds
                .where((s) =>
                    s.category.trim().toLowerCase() ==
                    categories[_selectedCategory].trim().toLowerCase())
                .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Build a Sound')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isPhone = constraints.maxWidth < 700;

              // build helpers once
              void playMix() {
                final layers = chosen.map((item) {
                  final s = sounds.firstWhere((s) => s.name == item.soundName);
                  return BuildLayer(
                    sound: s,
                    volume: item.volume,
                    speed: item.speed,
                    pitch: item.pitch,
                    offset: item.offset,
                  );
                }).toList();
                final titleForBar = buildTitle.isEmpty ? 'Mix' : buildTitle;
                svc.playMix(layers, title: titleForBar);
                setState(() => _isMixPlaying = true);
              }

              Future<void> saveBuild() async {
                final title = buildTitle.trim();
                if (title.isEmpty || chosen.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter a title and add at least one sound",
                      ),
                    ),
                  );
                  return;
                }
                if (StorageService.instance
                    .getAllPresets()
                    .any((p) => p.name == title)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("A build already exists with this name"),
                    ),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final newPreset = Preset(name: title, items: List.from(chosen));
                await StorageService.instance.savePreset(newPreset);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text("Saved Build: $title")),
                );
                setState(() {
                  buildTitle = '';
                  chosen.clear();
                });
              }

              final left = _BuildPanelLeft(
                buildTitle: buildTitle,
                onTitleChanged: (v) => setState(() => buildTitle = v),
                chosen: chosen,
                isMixPlaying: _isMixPlaying,
                onPlayMix: playMix,
                onSave: saveBuild,
                onUpdateVolume: (i, v) {
                  setState(() => chosen[i] = chosen[i].copyWith(volume: v));
                  if (_isMixPlaying) svc.updateMixVolume(i, v);
                },
                onUpdateSpeed: (i, v) {
                  setState(() => chosen[i] = chosen[i].copyWith(speed: v));
                  if (_isMixPlaying) svc.updateMixSpeed(i, v);
                },
                onUpdatePitch: (i, v) {
                  setState(() => chosen[i] = chosen[i].copyWith(pitch: v));
                  // add live per-track pitch when native supports it
                },
                onUpdatePan: (i, v) {
                  setState(() => chosen[i] = chosen[i].copyWith(pan: v));
                  if (_isMixPlaying) svc.updateMixPan(i, v);
                },
                onDelete: (i) => setState(() => chosen.removeAt(i)),
              );

              final right = _BuildPanelRight(
                categories: categories,
                selectedCategory: _selectedCategory,
                onSelectCategory: (idx) =>
                    setState(() => _selectedCategory = idx),
                filteredSounds: filteredSounds,
                onPreview: (s) {
                  svc.stopAll();
                  svc.playSound(s.assetPath, title: s.name);
                },
                onAdd: (s) =>
                    setState(() => chosen.add(PresetItem(soundName: s.name))),
              );

              if (isPhone) {
                // stack vertically on phones
                return Column(
                  children: [
                    Expanded(child: left),
                    const Divider(height: 1),
                    Expanded(child: right),
                  ],
                );
              }

              // two-pane on wider screens
              return Row(
                children: [
                  Flexible(flex: 2, child: left), // narrower left
                  Container(width: 1, color: AppTheme.onSurface.withAlpha(26)),
                  Flexible(flex: 3, child: right),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Left panel: title, actions, and chosen layers list
class _BuildPanelLeft extends StatelessWidget {
  const _BuildPanelLeft({
    required this.buildTitle,
    required this.onTitleChanged,
    required this.chosen,
    required this.isMixPlaying,
    required this.onPlayMix,
    required this.onSave,
    required this.onUpdateVolume,
    required this.onUpdateSpeed,
    required this.onUpdatePitch,
    required this.onUpdatePan,
    required this.onDelete,
  });

  final String buildTitle;
  final ValueChanged<String> onTitleChanged;
  final List<PresetItem> chosen;
  final bool isMixPlaying;
  final VoidCallback onPlayMix;
  final Future<void> Function() onSave;
  final void Function(int index, double v) onUpdateVolume;
  final void Function(int index, double v) onUpdateSpeed;
  final void Function(int index, double v) onUpdatePitch;
  final void Function(int index, double v) onUpdatePan;
  final void Function(int index) onDelete;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final smallBtn = ElevatedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: const TextStyle(fontSize: 14),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
            child: Row(   // wrap on small widths
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: buildTitle,
                    onChanged: onTitleChanged,
                    textInputAction: TextInputAction.done,
                    maxLines: 1,
                    maxLength: 30,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Title',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppTheme.secondary.withAlpha(128),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Play Mix button
                ElevatedButton.icon(
                  style: smallBtn,
                  icon: const Icon(Icons.playlist_play),
                  label: const Text('Play Mix'),
                  onPressed: onPlayMix,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: smallBtn,
                  onPressed: onSave,
                  child: const Text('Add Build'),
                ),
              ],
          ),
        ),
        Expanded(
          child: chosen.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Add sounds from the list to start building your mix',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: bottomInset + 8),
                  itemCount: chosen.length,
                  itemBuilder: (_, i) {
                    final layer = chosen[i];
                    return PresetItemCard(
                      presetitem: layer,
                      onVolumeChanged: (v) => onUpdateVolume(i, v),
                      onSpeedChanged: (v) => onUpdateSpeed(i, v),
                      onPitchChanged: (v) => onUpdatePitch(i, v),
                      onPanChanged: (v) => onUpdatePan(i, v),
                      onDelete: () => onDelete(i),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Right panel: categories row + available sounds list
class _BuildPanelRight extends StatelessWidget {
  const _BuildPanelRight({
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.filteredSounds,
    required this.onPreview,
    required this.onAdd,
  });

  final List<String> categories;
  final int selectedCategory;
  final ValueChanged<int> onSelectCategory;
  final List<Sound> filteredSounds;
  final void Function(Sound sound) onPreview;
  final void Function(Sound sound) onAdd;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (ctx, idx) => HorizontalTileSelector(
              label: categories[idx],
              isSelected: idx == selectedCategory,
              onTap: () => onSelectCategory(idx),
            ),
          ),
        ),
        Expanded(
          child: filteredSounds.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No sounds in this category',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(top: 8, bottom: bottomInset + 8),
                  itemCount: filteredSounds.length,
                  itemBuilder: (ctx, i) {
                    final s = filteredSounds[i];
                    return SoundCard(
                      sound: s,
                      isPlaying: false,
                      onDelete: null,
                      onAdd: () => onAdd(s),
                    );
                  },
                ),
        ),
      ],
    );
  }
}