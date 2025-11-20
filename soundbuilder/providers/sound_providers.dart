// lib/providers/sound_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sound.dart';

final allSoundsProvider = FutureProvider<List<Sound>>((ref) async {
  return await Sound.loadSounds();
});
