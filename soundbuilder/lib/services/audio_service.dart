import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:soundbuilder/models/build_layer.dart';
import 'package:soundbuilder/services/asset_loader.dart';

/// AudioService backed by the native audio_engine plugin.
/// Global controls act as multipliers for gain/speed/pitch,
/// and GLOBAL PAN linearly pulls each track's base pan toward the pushed edge.
///   - global pan 0.0  => use base pan
///   - global pan +1.0 => force +1 (hard right)
///   - global pan -1.0 => force -1 (hard left)
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();
  final AudioEngine _engine = AudioEngine();

  // UI-facing state
  final ValueNotifier<String> nowPlaying = ValueNotifier<String>('Nothing Playing');
  final ValueNotifier<double> volume = ValueNotifier<double>(1.0); // global multiplier
  final ValueNotifier<double> speed  = ValueNotifier<double>(1.0); // global multiplier
  final ValueNotifier<double> pitch  = ValueNotifier<double>(1.0); // global multiplier (factor)
  final ValueNotifier<double> pan    = ValueNotifier<double>(0.0); // global direction (-1..1)

  Timer? _sleepTimer;

  /// Track ids for the current playback (single or mix), same order as layers.
  final List<int> _activeTrackIds = [];

  /// Per-track "base" params captured from the build (aligned to _activeTrackIds).
  final List<double> _baseGains   = [];
  final List<double> _baseSpeeds  = [];
  final List<double> _basePitches = [];
  final List<double> _basePans    = [];

  bool get isPlaying => _activeTrackIds.isNotEmpty;

  // ---- helpers ----
  double _cap(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

  double _panTowardBound(double base, double global) {
    // Linearly pull base toward the chosen bound, based on global magnitude.
    final g = _cap(global, -1.0, 1.0);
    final b = _cap(base,   -1.0, 1.0);

    if (g >= 0) {
      // Move linearly from base → +1 as g goes 0→1
      return _cap(b + (1.0 - b) * g, -1.0, 1.0);
    } else {
      // Move linearly from base → -1 as g goes 0→-1
      final t = -g; // 0..1
      return _cap(b + (-1.0 - b) * t, -1.0, 1.0);
    }
  }

  Future<void> _applyTrackEffective(int index) async {
    final id = _activeTrackIds[index];
    final effGain  = _baseGains[index]   * volume.value;
    final effSpeed = _baseSpeeds[index]  * speed.value;
    final effPitch = _basePitches[index] * pitch.value;
    final effPan   = _panTowardBound(_basePans[index], pan.value); // <-- fixed index

    await _engine.setGain(id,  effGain);
    await _engine.setSpeed(id, effSpeed);
    await _engine.setPitch(id, effPitch);
    await _engine.setPan(id,   effPan);
  }

  Future<void> _applyAllEffective() async {
    for (var i = 0; i < _activeTrackIds.length; i++) {
      await _applyTrackEffective(i);
    }
  }

  void _clearState() {
    _activeTrackIds.clear();
    _baseGains.clear();
    _baseSpeeds.clear();
    _basePitches.clear();
    _basePans.clear();
    nowPlaying.value = 'Nothing Playing';
  }

  // ---- lifecycle ----
  Future<void> stopAll() async {
    _sleepTimer?.cancel();
    if (_activeTrackIds.isNotEmpty) {
      await _engine.stopAll();
      for (final id in _activeTrackIds) {
        await _engine.disposeTrack(id);
      }
    }
    _clearState();
  }

  /// Play a single asset (treated like a one-layer mix with base=1/1/1 and base pan=0).
  Future<void> playSound(
    String assetPath, {
    required String title,
    Duration offset = Duration.zero,
  }) async {
    await stopAll();
    final filePath = await AssetLoader.ensureLocalCopy(assetPath);
    final id = await _engine.createTrack(uri: 'file://$filePath');
    _activeTrackIds.add(id);

    // base params for a single sound
    _baseGains.add(1.0);
    _baseSpeeds.add(1.0);
    _basePitches.add(1.0);
    _basePans.add(0.0);

    // apply effective with current globals
    await _applyTrackEffective(0);

    nowPlaying.value = title;
    await _engine.start(id, offset: offset);
  }

  /// Play multiple BuildLayers together (mix).
  /// Each layer contributes base params; globals multiply/add (pan blends toward edge) on top.
  Future<void> playMix(List<BuildLayer> layers, {String? title}) async {
    await stopAll();
    if (layers.isEmpty) return;

    final Map<int, Duration> offsets = {};
    for (final layer in layers) {
      final filePath = await AssetLoader.ensureLocalCopy(layer.sound.assetPath);
      final id = await _engine.createTrack(uri: 'file://$filePath');
      _activeTrackIds.add(id);

      // capture bases in the same order as tracks
      _baseGains.add(layer.volume);
      _baseSpeeds.add(layer.speed);
      _basePitches.add(layer.pitch);
      _basePans.add(layer.pan);

      offsets[id] = layer.offset;
    }

    // Apply effective values before starting
    await _applyAllEffective();

    nowPlaying.value = (title != null && title.trim().isNotEmpty) ? title : 'Mix';
    await _engine.startAll(offsets);
  }

  // ---- per-layer updates (during a playing mix) ----
  Future<void> updateMixVolume(int layerIndex, double v) async {
    if (layerIndex < 0 || layerIndex >= _activeTrackIds.length) return;
    _baseGains[layerIndex] = v;
    final id = _activeTrackIds[layerIndex];
    await _engine.setGain(id, v * volume.value);
  }

  Future<void> updateMixSpeed(int layerIndex, double v) async {
    if (layerIndex < 0 || layerIndex >= _activeTrackIds.length) return;
    _baseSpeeds[layerIndex] = v;
    final id = _activeTrackIds[layerIndex];
    await _engine.setSpeed(id, v * speed.value);
  }

  Future<void> updateMixPan(int layerIndex, double v) async {
    if (layerIndex < 0 || layerIndex >= _activeTrackIds.length) return; // <-- guard restored
    _basePans[layerIndex] = v;
    final id = _activeTrackIds[layerIndex];
    await _engine.setPan(id, _panTowardBound(v, pan.value));
  }

  // ---- global controls (Playback Bar) ----
  Future<void> setVolume(double v) async {
    volume.value = v;
    for (var i = 0; i < _activeTrackIds.length; i++) {
      final id = _activeTrackIds[i];
      await _engine.setGain(id, _baseGains[i] * v);
    }
  }

  Future<void> setSpeed(double v) async {
    speed.value = v;
    for (var i = 0; i < _activeTrackIds.length; i++) {
      final id = _activeTrackIds[i];
      await _engine.setSpeed(id, _baseSpeeds[i] * v);
    }
  }

  Future<void> setPitch(double v) async {
    pitch.value = v;
    for (var i = 0; i < _activeTrackIds.length; i++) {
      final id = _activeTrackIds[i];
      await _engine.setPitch(id, _basePitches[i] * v);
    }
  }

  Future<void> setPan(double v) async {
    pan.value = v;
    for (var i = 0; i < _activeTrackIds.length; i++) {
      final id = _activeTrackIds[i];
      await _engine.setPan(id, _panTowardBound(_basePans[i], v));
    }
  }

  /// Sleep timer: stop everything after [d]
  void setSleepTimer(Duration d) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(d, () { stopAll(); });
  }
}