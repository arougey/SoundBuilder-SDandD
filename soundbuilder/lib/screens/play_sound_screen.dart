// lib/screens/play_sound_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soundbuilder/models/build_layer.dart';
import 'package:soundbuilder/models/preset.dart';
import 'package:soundbuilder/models/sound.dart';

import 'package:soundbuilder/providers/audio_providers.dart';
import 'package:soundbuilder/providers/sound_providers.dart';

import 'package:soundbuilder/screens/build_sound_screen.dart';
import 'package:soundbuilder/services/storage_service.dart';

import 'package:soundbuilder/widgets/preset_card.dart';
import 'package:soundbuilder/widgets/sound_card.dart';
import 'package:soundbuilder/widgets/horizontal_tile_selector.dart';


class PlaySoundsScreen extends ConsumerStatefulWidget {
  const PlaySoundsScreen({super.key});
  @override
  ConsumerState<PlaySoundsScreen> createState() => _PlaySoundsScreenState();
}

class _PlaySoundsScreenState extends ConsumerState<PlaySoundsScreen> {
  int _selectedTab = 0;

  // Presets from Hive
  List<Preset> presets = [];

  // Track what’s playing
  String? _playingPresetName;
  String? _playingSoundName;

  @override
  void initState() {
    super.initState();
    presets = StorageService.instance.getAllPresets();
    StorageService.instance.watch().listen((_) {
      if (!mounted) return;
      setState(() => presets = StorageService.instance.getAllPresets());
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(audioServiceProvider);
    final soundAsync = ref.watch(allSoundsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Play a Sound')),
      body: soundAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading sounds: $e')),
        data: (allSounds) {
          // Derive categories from data (unique + sorted)
          final dataCats = allSounds.map((s) => s.category).toSet().toList()
            ..sort();
          final tabs = ['My Builds', ...dataCats];

          // Keep selected tab in range
          if (_selectedTab >= tabs.length) _selectedTab = 0;

          final isPresetsTab = _selectedTab == 0;

          return Column(
            children: [
              // ─── Tabs ───
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tabs.length,
                  itemBuilder: (ctx, i) => HorizontalTileSelector(
                    label: tabs[i],
                    isSelected: _selectedTab == i,
                    onTap: () => setState(() => _selectedTab = i),
                  ),
                ),
              ),

              // ─── Content ───
              Expanded(
                child: isPresetsTab
                    ? _buildPresetsList(context, svc, allSounds)
                    : _buildSoundsBySubcategory(
                        context, svc, allSounds, tabs[_selectedTab]),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Helpers ----------

  Widget _buildPresetsList(
    BuildContext context,
    dynamic svc, // keep dynamic if your provider type isn’t exported
    List<Sound> allSounds,
  ) {
    if (presets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.library_music_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                "Go to the Builds tab to create your own build",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: presets.length,
      itemBuilder: (ctx, i) {
        final p = presets[i];
        final isPlaying = p.name == _playingPresetName;
        return PresetCard(
          preset: p,
          isPlaying: isPlaying,
          onPlay: () {
            svc.stopAll();
            final layers = p.items.map((item) {
              final sound =
                  allSounds.firstWhere((s) => s.name == item.soundName);
              return BuildLayer(
                sound: sound,
                volume: item.volume,
                speed: item.speed,
                pitch: item.pitch,
                offset: item.offset,
              );
            }).toList();
            svc.playMix(layers);
            setState(() {
              _playingPresetName = p.name;
              _playingSoundName = null;
            });
          },
          onStop: () {
            svc.stopAll();
            setState(() => _playingPresetName = null);
          },
          onShare: () {
            // TODO: share logic
          },
          onDelete: () async {
            await StorageService.instance.deletePreset(p.name);
            setState(() {
              presets.removeAt(i);
              if (_playingPresetName == p.name) {
                _playingPresetName = null;
                svc.stopAll();
              }
            });
          },
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuildSoundScreen(editPreset: p),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSoundsBySubcategory(
    BuildContext context,
    dynamic svc,
    List<Sound> allSounds,
    String category,
  ) {
    // Safer normalized comparison (in case of case/space differences)
    final filtered = allSounds
        .where((s) =>
            s.category.trim().toLowerCase() == category.trim().toLowerCase())
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No sounds in “$category”. Check your assets/sounds.json categories.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Group by non-nullable subcategory
    final Map<String, List<Sound>> grouped = <String, List<Sound>>{};
    for (final s in filtered) {
      grouped.putIfAbsent(s.subcategory, () => <Sound>[]).add(s);
    }

    // Sort groups and their items
    final List<String> groupKeys = grouped.keys.toList()..sort();
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
                isPlaying: s.name == _playingSoundName,
                onToggle: () {
                  svc.stopAll();
                  final isPlaying = s.name == _playingSoundName;
                  if (!isPlaying) {
                    svc.playSound(s.assetPath, title: s.name);
                    setState(() {
                      _playingSoundName = s.name;
                      _playingPresetName = null;
                    });
                  } else {
                    setState(() => _playingSoundName = null);
                  }
                },
                onDelete: null,
                onAdd: null,
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}