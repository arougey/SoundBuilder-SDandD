// lib/models/preset.dart
import 'package:hive/hive.dart';
import 'preset_item.dart';

part 'preset.g.dart';

@HiveType(typeId: 2)
class Preset {
  @HiveField(0)
  final String name;

  @HiveField(2)
  final List<PresetItem> items;

  Preset({required this.name, required this.items});
}
