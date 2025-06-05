// Audio engine factory for platform-specific implementations
import 'package:flutter/foundation.dart';
import 'audio_engine.dart';
import 'audio_engine_web.dart';

AudioEngine createAudioEngine() {
  print('🏭 AudioEngine Factory: kIsWeb = $kIsWeb');
  if (kIsWeb) {
    print('🌐 Creating AudioEngineWeb for web platform');
    return AudioEngineWeb();
  } else {
    print('📱 Creating AudioEngine for native platform');
    return AudioEngine();
  }
}