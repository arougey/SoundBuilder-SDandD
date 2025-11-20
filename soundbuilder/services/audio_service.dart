import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:soundbuilder/models/build_layer.dart';
import 'package:soundbuilder/services/asset_loader.dart';

/// AudioService backed by the native audio_engine plugin.
/// Supports single-sound playback and layered mixes with per-track pitch/speed/pan/offset.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();
  final AudioEngine _engine = AudioEngine();

  // UI-facing state (kept from your original API so PlaybackBar keeps working)
  final ValueNotifier<String> nowPlaying = ValueNotifier<String>(
    'Nothing Playing',
  );
  final ValueNotifier<double> volume = ValueNotifier<double>(1.0); // 0..1
  final ValueNotifier<double> speed = ValueNotifier<double>(
    1.0,
  ); // 0.5..2.0 (engine allows wider)
  final ValueNotifier<double> pitch = ValueNotifier<double>(
    1.0,
  ); // 0.5..2.0 (factor)
  final ValueNotifier<double> pan = ValueNotifier<double>(0.0); // -1..+1

  Timer? _sleepTimer;

  /// Track ids for the *current* playback (single or mix).
  /// For a mix, this list aligns with the order of the `layers` you passed.
  final List<int> _activeTrackIds = [];

  bool get isPlaying => _activeTrackIds.isNotEmpty;

  /// Stops all playback and clears state. Disposes native tracks.
  Future<void> stopAll() async {
    _sleepTimer?.cancel();
    if (_activeTrackIds.isEmpty) return;
    await _engine.stopAll();
    // dispose the tracks natively to free players
    for (final id in _activeTrackIds) {
      await _engine.disposeTrack(id);
    }
    _activeTrackIds.clear();
    nowPlaying.value = 'Nothing Playing';
  }

  /// Play a single asset (looping handled by native layer later if you want).
  Future<void> playSound(
    String assetPath, {
    required String title,
    Duration offset = Duration.zero,
  }) async {
    await stopAll();

    // Copy asset to a real file and create a track
    final filePath = await AssetLoader.ensureLocalCopy(assetPath);
    final id = await _engine.createTrack(uri: 'file://$filePath');
    _activeTrackIds.add(id);

    // Apply current global controls
    await _engine.setGain(id, volume.value);
    await _engine.setSpeed(id, speed.value);
    await _engine.setPitch(id, pitch.value);
    await _engine.setPan(id, pan.value);

    nowPlaying.value = title;
    await _engine.start(id, offset: offset);
  }

  /// Play multiple BuildLayers together (mix). Each layer maps to one track id.
  Future<void> playMix(List<BuildLayer> layers, {String? title}) async {
    await stopAll();
    if (layers.isEmpty) return;

    // Create tracks and set per-layer params
    final Map<int, Duration> offsets = {};
    for (final layer in layers) {
      final assetPath = layer.sound.assetPath; // e.g. 'assets/sound/rain.wav'
      final filePath = await AssetLoader.ensureLocalCopy(assetPath);
      final id = await _engine.createTrack(uri: 'file://$filePath');
      _activeTrackIds.add(id);

      await _engine.setGain(id, layer.volume);
      await _engine.setSpeed(id, layer.speed);
      await _engine.setPitch(
        id,
        layer.pitch,
      ); // ensure BuildLayer.pitch is a factor (0.5..2.0)
      await _engine.setPan(
        id,
        layer.pan,
      ); // default 0 if your model didn’t have it

      offsets[id] = layer.offset;
    }

    // Initialize global sliders to the first layer’s values so UI reflects the mix
    final first = layers.first;
    volume.value = first.volume;
    speed.value = first.speed;
    pitch.value = first.pitch;
    pan.value = first.pan;

    nowPlaying.value = (title != null && title.trim().isNotEmpty)
        ? title
        : 'Mix';
    await _engine.startAll(offsets);
  }

  /// Per-layer adjustments by index (matches playMix order)
  Future<void> updateMixVolume(int layerIndex, double v) async {
    if (layerIndex < 0 || layerIndex >= _activeTrackIds.length) return;
    await _engine.setGain(_activeTrackIds[layerIndex], v);
  }

  Future<void> updateMixSpeed(int layerIndex, double v) async {
    if (layerIndex < 0 || layerIndex >= _activeTrackIds.length) return;
    await _engine.setSpeed(_activeTrackIds[layerIndex], v);
  }

  Future<void> updateMixPan(int layerIndex, double v) async {
    if (layerIndex < 0 || layerIndex >= _activeTrackIds.length) return;
    await _engine.setPan(_activeTrackIds[layerIndex], v);
  }

  /// Global controls (apply to all active tracks)
  Future<void> setVolume(double v) async {
    volume.value = v;
    for (final id in _activeTrackIds) {
      await _engine.setGain(id, v);
    }
  }

  Future<void> setSpeed(double v) async {
    speed.value = v;
    for (final id in _activeTrackIds) {
      await _engine.setSpeed(id, v);
    }
  }

  Future<void> setPitch(double v) async {
    pitch.value = v;
    for (final id in _activeTrackIds) {
      await _engine.setPitch(id, v);
    }
  }

  Future<void> setPan(double v) async {
    pan.value = v;
    for (final id in _activeTrackIds) {
      await _engine.setPan(id, v);
    }
  }

  /// Sleep timer: stop everything after [d]
  void setSleepTimer(Duration d) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(d, () {
      stopAll();
    });
  }
}
