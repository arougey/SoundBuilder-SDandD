//`class Sound { String id, name, assetPath }`
// lib/models/sound.dart
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

/// Represents a single sound option in SoundBuilder. Has no sound modifications as those will be done globally to it
class Sound {
  /// Human-readable name displayed in the UI.
  final String name;

  /// Asset path to the sound file (e.g., 'assets/sounds/rain.mp3').
  final String assetPath;

  /// Category that the sound will be found under
  final String category;

  /// Subcategory dropdown that the sound will be found under
  final String subcategory;

  const Sound({
    required this.name,
    required this.assetPath,
    required this.category,
    required this.subcategory,
  });

  factory Sound.fromJson(Map<String, dynamic> json) {
    return Sound(
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
    );
  }

  static Future<List<Sound>> loadSounds() async {
    final data = await rootBundle.loadString('assets/sounds.json');
    developer.log('Loaded sounds.json: $data');
    final List<dynamic> list = json.decode(data) as List<dynamic>;
    return list.map((e) => Sound.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  String toString() => 'Sound(name: $name)';
}
