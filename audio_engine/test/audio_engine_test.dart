import 'package:flutter_test/flutter_test.dart';
import 'package:audio_engine/audio_engine.dart';
import 'package:audio_engine/audio_engine_platform_interface.dart';
import 'package:audio_engine/audio_engine_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioEnginePlatform
    with MockPlatformInterfaceMixin
    implements AudioEnginePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AudioEnginePlatform initialPlatform = AudioEnginePlatform.instance;

  test('$MethodChannelAudioEngine is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioEngine>());
  });

  test('getPlatformVersion', () async {
    AudioEngine audioEnginePlugin = AudioEngine();
    MockAudioEnginePlatform fakePlatform = MockAudioEnginePlatform();
    AudioEnginePlatform.instance = fakePlatform;

    expect(await audioEnginePlugin.getPlatformVersion(), '42');
  });
}
