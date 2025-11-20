// wraps Hive: savePreset(), loadPresets(), deletePreset()

// lib/services/storage_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soundbuilder/models/preset.dart';
import 'package:soundbuilder/models/preset_item.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _boxName = 'presets';

  /// Call once at app startup.
  Future<void> init() async {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(PresetItemAdapter())
      ..registerAdapter(PresetAdapter());
    try {
      await Hive.openBox<Preset>(_boxName);
    } catch (e, st) {
      debugPrint('Hive openBox failed for "$_boxName": $e\n$st');
      if (kDebugMode) {
        debugPrint('Deleting "$_boxName" from disk in debug and retrying');
        await Hive.deleteBoxFromDisk(_boxName);
        await Hive.openBox<Preset>(_boxName);
      } else {
        rethrow;
      }
    }
  }

  Box<Preset> get _box => Hive.box<Preset>(_boxName);

  /// Returns all saved presets.
  List<Preset> getAllPresets() => _box.values.toList();

  /// Adds or updates a preset.
  Future<void> savePreset(Preset p) => _box.put(p.name, p);

  /// Deletes a preset by id.
  Future<void> deletePreset(String id) => _box.delete(id);

  /// Watch for live changes.
  Stream<BoxEvent> watch() => _box.watch();
}
