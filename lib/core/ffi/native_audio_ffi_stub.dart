// Stub for NativeAudioLib - fallback implementation when neither web nor native is available

class NativeAudioLib {
  static final NativeAudioLib _instance = NativeAudioLib._internal();
  factory NativeAudioLib() => _instance;

  NativeAudioLib._internal() {
    throw UnsupportedError('NativeAudioLib is not supported on this platform');
  }

  void sendPolyAftertouch(int noteNumber, int pressure) {
    throw UnsupportedError('Platform not supported');
  }

  void sendPitchBend(int value) {
    throw UnsupportedError('Platform not supported');
  }

  void sendControlChange(int controller, int value) {
    throw UnsupportedError('Platform not supported');
  }

  void disposeCallables() {
    throw UnsupportedError('Platform not supported');
  }
}