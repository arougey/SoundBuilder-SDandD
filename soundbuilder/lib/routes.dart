import 'package:flutter/material.dart'; // or widgets.dart if you prefer lighter import
import 'package:soundbuilder/screens/play_sound_screen.dart';
import 'package:soundbuilder/screens/build_sound_screen.dart';

class AppRoutes {
  static const play = '/play';
  static const build = '/build';

  static Map<String, WidgetBuilder> map = {
    play: (_) => const PlaySoundsScreen(),
    build: (_) => const BuildSoundScreen(),
  };
}
