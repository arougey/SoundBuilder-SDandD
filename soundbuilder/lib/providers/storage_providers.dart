import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Exposes your StorageService singleton.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});
