// Platform-specific audio backend implementation
import 'audio_backend.dart';
import 'audio_engine_factory.dart';
import 'audio_engine.dart';

// Create the appropriate audio backend for the current platform
AudioBackend createAudioBackend() {
  return AudioEngineBackend();
}

// AudioBackend implementation that wraps the existing AudioEngine
class AudioEngineBackend implements AudioBackend {
  late final AudioEngine _engine;
  bool _initialized = false;
  
  AudioEngineBackend() {
    _engine = createAudioEngine();
  }
  
  @override
  bool get isInitialized => _initialized;
  
  @override
  Future<void> initialize() async {
    try {
      await _engine.init();
      _initialized = true;
      print('AudioEngineBackend: Initialized successfully');
    } catch (e) {
      print('AudioEngineBackend: Initialization failed: $e');
      _initialized = false;
    }
  }
  
  @override
  Future<void> dispose() async {
    _engine.dispose();
    _initialized = false;
  }
  
  @override
  void setParameter(String parameterId, double value) {
    if (!_initialized) return;
    
    // Map parameter IDs to AudioEngine methods
    switch (parameterId) {
      case 'master_volume':
        _engine.setVolume(value);
        break;
      case 'filter_cutoff':
        _engine.setCutoff(value);
        break;
      case 'filter_resonance':
        _engine.setResonance(value);
        break;
      case 'attack_time':
        _engine.setAttack(value);
        break;
      case 'decay_time':
        _engine.setDecay(value);
        break;
      case 'sustain_level':
        // AudioEngine doesn't have sustain, map to decay for now
        _engine.setDecay(value);
        break;
      case 'release_time':
        // AudioEngine doesn't have release, map to decay for now
        _engine.setDecay(value);
        break;
      case 'reverb_mix':
        _engine.setReverb(value);
        break;
      default:
        print('AudioEngineBackend: Unknown parameter: $parameterId');
    }
  }
  
  @override
  void noteOn(int midiNote, double velocity) {
    if (!_initialized) return;
    _engine.playNote(midiNote, velocity);
  }
  
  @override
  void noteOff(int midiNote) {
    if (!_initialized) return;
    _engine.stopNote(midiNote);
  }
  
  @override
  void allNotesOff() {
    if (!_initialized) return;
    _engine.stopAllNotes();
  }
  
  @override
  void start() {
    // AudioEngine doesn't have explicit start/stop methods
    print('AudioEngineBackend: Start requested');
  }
  
  @override
  void stop() {
    // AudioEngine doesn't have explicit start/stop methods
    print('AudioEngineBackend: Stop requested');
  }
}