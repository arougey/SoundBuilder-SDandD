// lib/models/build_layer.dart

import 'package:soundbuilder/models/sound.dart';

/// A single layer in a “build” (preset), pairing a loaded [Sound]
/// with per-layer adjustments.
class BuildLayer {
  /// The actual sound object (so we know its assetPath, name, etc.).
  final Sound sound;

  /// Per-layer volume (0.0–1.0).
  double volume;

  /// Playback speed multiplier (e.g. 0.5–2.0).
  double speed;

  /// Pitch shift (if/when you add pitch control).
  double pitch;

  /// Pan shift (left vs right ear)
  double pan;

  /// How far into the clip to start.
  Duration offset;

  BuildLayer({
    required this.sound,
    this.volume = 1.0,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.pan = 0.0,
    this.offset = Duration.zero,
  });
}
