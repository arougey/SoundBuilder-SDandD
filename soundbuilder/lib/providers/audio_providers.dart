//lib/providers/audio_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundbuilder/services/audio_service.dart';

/// Exposes your AudioService singleton.
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});
