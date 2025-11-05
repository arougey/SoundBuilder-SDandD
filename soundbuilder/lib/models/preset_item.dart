// lib/models/prest_item.dart
import 'package:hive/hive.dart';
part 'preset_item.g.dart';

// Immutable PresetItem
@HiveType(typeId: 1)
class PresetItem {
  @HiveField(0)
  final String soundName;
  @HiveField(1)
  final double volume;
  @HiveField(2)
  final double speed;
  @HiveField(3)
  final double pitch;
  @HiveField(4)
  final double pan;
  @HiveField(5)
  final int offsetMs;

  PresetItem({
    required this.soundName,
    this.volume = 1.0,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.pan = 0.0,
    Duration offset = Duration.zero,
  }) : offsetMs = offset.inMilliseconds;

  // helper for “mutating” volume/speed/etc
  PresetItem copyWith({
    String? soundName,
    double? volume,
    double? speed,
    double? pitch,
    double? pan,
    Duration? offset,
  }) {
    return PresetItem(
      soundName: soundName ?? this.soundName,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      pan: pan ?? this.pan,
      offset: offset ?? this.offset,
    );
  }

  Duration get offset => Duration(milliseconds: offsetMs);
}
