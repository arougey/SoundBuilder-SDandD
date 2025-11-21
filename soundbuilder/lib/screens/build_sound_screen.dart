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

  bool get isEditing => widget.editPreset != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
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
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final media = MediaQuery.of(context);
                final isLandscape = media.orientation == Orientation.landscape;
                final isTwoPane = isLandscape || constraints.maxWidth >= 600;
                final isEditing = this.isEditing;

                // build helpers once
                void playMix() {
                  if (svc.isPlaying) {
                    svc.stopAll();
                    setState(() => _isMixPlaying = false);
                    return;
                  }
                  if (chosen.isEmpty) {
                    return ;
                  }

                  // Nothing playing → build and play the mix
                  final layers = chosen.map((item) {
                    final s = sounds.firstWhere((s) => s.name == item.soundName);
                    return BuildLayer(
                      sound: s,
                      volume: item.volume,
                      speed: item.speed,
                      pitch: item.pitch,
                      pan: item.pan,
                      offset: item.offset,
                    );
                  }).toList();

                  final titleForBar = buildTitle.isEmpty ? 'Mix' : buildTitle;
                  svc.playMix(layers, title: titleForBar);
                  setState(() => _isMixPlaying = true);
                }

                Future<void> saveBuild() async {
                  // Use context *here* before any awaits
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  final title = buildTitle.trim();
                  if (title.isEmpty || chosen.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter a title and add at least one sound",
                        ),
                      ),
                    );
                    return;
                  }

                  final allPresets = StorageService.instance.getAllPresets();

                  if (!isEditing) {
                    // ─── Create new build ───
                    final alreadyExists = allPresets.any((p) => p.name == title);
                    if (alreadyExists) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("A build already exists with this name"),
                        ),
                      );
                      return;
                    }

                    final newPreset = Preset(name: title, items: List.from(chosen));
                    await StorageService.instance.savePreset(newPreset);

                    if (!mounted) return; // guard the State after async work

                    messenger.showSnackBar(
                      SnackBar(content: Text("Saved Build: $title")),
                    );
                    setState(() {
                      buildTitle = '';
                      chosen.clear();
                    });
                  } else {
                    // ─── Edit existing build ───
                    final originalName = widget.editPreset!.name;

                    // Only block if you're trying to rename to some other existing preset
                    final conflictingName = allPresets.any(
                      (p) => p.name == title && p.name != originalName,
                    );
                    if (conflictingName) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Another build already exists with that name"),
                        ),
                      );
                      return;
                    }

                    final updatedPreset = Preset(name: title, items: List.from(chosen));

                    if (title != originalName) {
                      await StorageService.instance.deletePreset(originalName);
                    }
                    await StorageService.instance.savePreset(updatedPreset);

                    if (!mounted) return;

                    messenger.showSnackBar(
                      SnackBar(content: Text("Updated Build: $title")),
                    );

                    // Close the edit screen and go back to the presets list
                    navigator.pop();
                  }
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
                  isEditing: isEditing,
                  showBack: isEditing,
                  onBack: () => Navigator.of(context).maybePop(),
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

                if (!isTwoPane) {
                  // stack vertically on phones
                  return Column(
                    children: [
                      Expanded(flex: 5, child: left),
                      const Divider(height: 1),
                      Expanded(flex: 3, child: right),
                    ],
                  );
                }

                // two-pane on wider screens
                return Row(
                  children: [
                    Expanded(flex: 2, child: left),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 1, child: right),
                  ],
                );
              },
            ),
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
    required this.isEditing,
    this.showBack = false,
    this.onBack,
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
  final bool isEditing;
  final bool showBack;
  final VoidCallback? onBack;

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
            child: Row(
              children: [
                if (showBack)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
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
                      fillColor: AppTheme.nearblack.withAlpha(128),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Play Mix button
                ElevatedButton.icon(
                  style: smallBtn,
                  icon: Icon(isMixPlaying ? Icons.stop : Icons.playlist_play),
                  label: Text(isMixPlaying ? 'Stop Mix' : 'Preview Mix'),
                  onPressed: onPlayMix,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: smallBtn,
                  onPressed: onSave,
                  child: Text(isEditing ? 'Save Build' : 'Add Build'),
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
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    padding: const EdgeInsets.all(0),
                    child: Text(
                      'No sounds in this category',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : _GroupedSoundsList(
                  sounds: filteredSounds,
                  onPreview: onPreview,
                  onAdd: onAdd,
                ),
        ),
      ],
    );
  }
}

class _GroupedSoundsList extends StatelessWidget {
  const _GroupedSoundsList({
    required this.sounds,
    required this.onPreview,
    required this.onAdd,
  });

  final List<Sound> sounds;
  final void Function(Sound) onPreview;
  final void Function(Sound) onAdd;

  @override
  Widget build(BuildContext context) {
    // Group by subcategory, then sort groups and items
    final Map<String, List<Sound>> grouped = <String, List<Sound>>{};
    for (final s in sounds) {
      grouped.putIfAbsent(s.subcategory, () => <Sound>[]).add(s);
    }
    final groupKeys = grouped.keys.toList()..sort();
    for (final k in groupKeys) {
      grouped[k]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupKeys.length,
      itemBuilder: (ctx, gIdx) {
        final groupKey = groupKeys[gIdx];
        final soundsInGroup = grouped[groupKey]!;

        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            groupKey.isEmpty ? 'Misc' : groupKey,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          children: [
            for (final s in soundsInGroup)
              SoundCard(
                sound: s,
                isPlaying: false,              // (Optional) wire up if you track preview state
                onToggle: () => onPreview(s),  // play/preview
                onDelete: null,
                onAdd: () => onAdd(s),         // add to build
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}