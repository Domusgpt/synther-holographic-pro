// Web stub for NativeAudioLib - provides no-op implementations for web platform
// This avoids FFI import issues on web builds while maintaining API compatibility

class NativeAudioLib {
  static final NativeAudioLib _instance = NativeAudioLib._internal();
  factory NativeAudioLib() => _instance;

  NativeAudioLib._internal() {
    // No initialization needed for web stub
  }

  // Polyphonic Aftertouch - no-op for web
  void sendPolyAftertouch(int noteNumber, int pressure) {
    // Web stub - no implementation
    print('Web stub: sendPolyAftertouch($noteNumber, $pressure)');
  }

  // Pitch Bend - no-op for web
  void sendPitchBend(int value) {
    // Web stub - no implementation
    print('Web stub: sendPitchBend($value)');
  }

  // Control Change - no-op for web
  void sendControlChange(int controller, int value) {
    // Web stub - no implementation
    print('Web stub: sendControlChange($controller, $value)');
  }

  // Cleanup - no-op for web
  void disposeCallables() {
    // Web stub - no implementation
  }
}