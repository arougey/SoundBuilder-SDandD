import 'package:flutter/services.dart';

class AudioEngine {
  static const MethodChannel _ch = MethodChannel('audio_engine');

  AudioEngine(); // instance style

  // Keeps the generated example/tests happy
  Future<String?> getPlatformVersion() =>
      _ch.invokeMethod<String>('getPlatformVersion');

  // ---- Track lifecycle ----
  Future<int> createTrack({required String uri}) async {
    final id = await _ch.invokeMethod<int>('createTrack', {'uri': uri});
    if (id == null) {
      throw PlatformException(code: 'null-id', message: 'createTrack returned null');
    }
    return id;
  }

  Future<void> disposeTrack(int id) =>
      _ch.invokeMethod<void>('disposeTrack', {'id': id});

  // ---- Parameters ----
  Future<void> setGain(int id, double v) =>
      _ch.invokeMethod<void>('setGain', {'id': id, 'v': v});

  Future<void> setSpeed(int id, double v) =>
      _ch.invokeMethod<void>('setSpeed', {'id': id, 'v': v});

  Future<void> setPitch(int id, double v) =>
      _ch.invokeMethod<void>('setPitch', {'id': id, 'v': v});

  Future<void> setPan(int id, double v) =>
      _ch.invokeMethod<void>('setPan', {'id': id, 'v': v});

  // ---- Transport ----
  Future<void> start(int id, {Duration offset = Duration.zero}) =>
      _ch.invokeMethod<void>('start', {'id': id, 'offsetMs': offset.inMilliseconds});

  Future<void> stop(int id) =>
      _ch.invokeMethod<void>('stop', {'id': id});

  Future<void> startAll(Map<int, Duration> offsets) =>
      _ch.invokeMethod<void>('startAll', {
        'offsets': offsets.map((k, v) => MapEntry(k.toString(), v.inMilliseconds)),
      });

  Future<void> stopAll() =>
      _ch.invokeMethod<void>('stopAll');
}