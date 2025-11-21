import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AssetLoader {
  static Future<String> ensureLocalCopy(String assetPath) async {
    // e.g. 'assets/sound/rain.wav'
    final data = await rootBundle.load(assetPath);
    final dir = await getApplicationSupportDirectory();
    final out = File('${dir.path}/$assetPath'); // preserves subfolders
    if (!await out.exists() || (await out.length()) != data.lengthInBytes) {
      await out.parent.create(recursive: true);
      await out.writeAsBytes(data.buffer.asUint8List());
    }
    return out.path;
  }
}
