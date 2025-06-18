// Platform-aware factory for NativeAudioLib
import 'package:flutter/foundation.dart';

// Conditional imports based on platform
import 'native_audio_ffi_stub.dart'
    if (dart.library.io) 'native_audio_ffi.dart'
    if (dart.library.html) 'native_audio_ffi_web.dart';

// Export the NativeAudioLib class from the appropriate implementation
export 'native_audio_ffi_stub.dart'
    if (dart.library.io) 'native_audio_ffi.dart'
    if (dart.library.html) 'native_audio_ffi_web.dart';

// Factory function to create appropriate NativeAudioLib instance
NativeAudioLib createNativeAudioLib() {
  if (kIsWeb) {
    print('🌐 Creating NativeAudioLib web stub');
  } else {
    print('📱 Creating NativeAudioLib native implementation');
  }
  return NativeAudioLib();
}