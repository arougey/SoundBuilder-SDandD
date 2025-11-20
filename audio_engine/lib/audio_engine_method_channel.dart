import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_engine_platform_interface.dart';

/// An implementation of [AudioEnginePlatform] that uses method channels.
class MethodChannelAudioEngine extends AudioEnginePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audio_engine');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
