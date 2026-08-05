import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:yjeek_driver/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureGoogleMapsAndroid();
  runApp(const MyApp());
}

/// TECNO / some Android devices show a blank white map with the default
/// Texture Layer Hybrid Composition path. Force a known-good renderer +
/// Hybrid Composition so the home map actually paints tiles.
Future<void> _configureGoogleMapsAndroid() async {
  if (kIsWeb) return;
  final impl = GoogleMapsFlutterPlatform.instance;
  if (impl is! GoogleMapsFlutterAndroid) return;

  try {
    await impl.initializeWithRenderer(AndroidMapRenderer.latest);
  } catch (_) {
    // Already initialized (hot restart) — ignore.
  }
  impl.useAndroidViewSurface = true;
}
