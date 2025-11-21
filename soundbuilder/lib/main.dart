import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundbuilder/services/iap_service.dart';
import 'core/theme.dart';
import 'screens/play_sound_screen.dart';
import 'screens/build_sound_screen.dart';
import 'screens/upgrade_screen.dart';
import 'services/storage_service.dart';
import 'widgets/playback_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await IapService.instance.init();
  runApp(const ProviderScope(child: SoundbuilderApp()));
}

class SoundbuilderApp extends StatelessWidget {
  const SoundbuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.theme, home: const MainShell());
  }
}

/// The “shell” that holds the BottomNavigationBar and swaps pages.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

const kPlaybackBarHeight = 196.0;

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // List your pages here in the same order as the tabs.
  static const List<Widget> _pages = <Widget>[
    PlaySoundsScreen(),
    BuildSoundScreen(),
    UpgradeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // preserves state when switching
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlaybackBar(),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.play_arrow),
                label: 'Play',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Build'),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
