// Professional Audio Engine Interface for Flutter
// Connects to native C++ synthesis engine

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioEngine extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('synther/audio');
  
  // Audio parameters (protected for inheritance)
  @protected
  double cutoffValue = 1000.0;
  @protected
  double resonanceValue = 0.5;
  @protected
  double attackValue = 0.1;
  @protected
  double decayValue = 0.3;
  @protected
  double reverbValue = 0.2;
  @protected
  double volumeValue = 0.7;
  
  @protected
  bool initializedValue = false;
  @protected
  bool playingValue = false;
  
  // Getters
  double get cutoff => cutoffValue;
  double get resonance => resonanceValue;
  double get attack => attackValue;
  double get decay => decayValue;
  double get reverb => reverbValue;
  double get volume => volumeValue;
  bool get isInitialized => initializedValue;
  bool get isPlaying => playingValue;
  
  // Legacy getters for compatibility
  double get filterCutoff => cutoffValue;
  double get filterResonance => resonanceValue;
  double get attackTime => attackValue;
  double get decayTime => decayValue;
  double get reverbMix => reverbValue;
  double get masterVolume => volumeValue;
  
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      print('AudioEngine: Native engine initialized');
    } catch (e) {
      print('AudioEngine: Failed to initialize native engine: $e');
    }
  }
  
  Future<void> init() async {
    if (initializedValue) return;
    
    try {
      await _channel.invokeMethod('init');
      initializedValue = true;
      notifyListeners();
      print('AudioEngine: Initialized successfully');
    } catch (e) {
      print('AudioEngine: Initialization failed: $e');
    }
  }
  
  // Parameter setters with native engine communication
  Future<void> setCutoff(double value) async {
    cutoffValue = value.clamp(20.0, 20000.0);
    try {
      await _channel.invokeMethod('setParameter', {
        'parameter': 'cutoff',
        'value': cutoffValue,
      });
    } catch (e) {
      print('AudioEngine: Failed to set cutoff: $e');
    }
    notifyListeners();
  }
  
  Future<void> setResonance(double value) async {
    resonanceValue = value.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('setParameter', {
        'parameter': 'resonance',
        'value': resonanceValue,
      });
    } catch (e) {
      print('AudioEngine: Failed to set resonance: $e');
    }
    notifyListeners();
  }
  
  Future<void> setAttack(double value) async {
    attackValue = value.clamp(0.001, 5.0);
    try {
      await _channel.invokeMethod('setParameter', {
        'parameter': 'attack',
        'value': attackValue,
      });
    } catch (e) {
      print('AudioEngine: Failed to set attack: $e');
    }
    notifyListeners();
  }
  
  Future<void> setDecay(double value) async {
    decayValue = value.clamp(0.001, 5.0);
    try {
      await _channel.invokeMethod('setParameter', {
        'parameter': 'decay',
        'value': decayValue,
      });
    } catch (e) {
      print('AudioEngine: Failed to set decay: $e');
    }
    notifyListeners();
  }
  
  Future<void> setReverb(double value) async {
    reverbValue = value.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('setParameter', {
        'parameter': 'reverb',
        'value': reverbValue,
      });
    } catch (e) {
      print('AudioEngine: Failed to set reverb: $e');
    }
    notifyListeners();
  }
  
  Future<void> setVolume(double value) async {
    volumeValue = value.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('setParameter', {
        'parameter': 'volume',
        'value': volumeValue,
      });
    } catch (e) {
      print('AudioEngine: Failed to set volume: $e');
    }
    notifyListeners();
  }
  
  // Legacy method names for compatibility
  Future<void> setFilterCutoff(double value) => setCutoff(value);
  Future<void> setFilterResonance(double value) => setResonance(value);
  Future<void> setAttackTime(double value) => setAttack(value);
  Future<void> setDecayTime(double value) => setDecay(value);
  Future<void> setReverbMix(double value) => setReverb(value);
  Future<void> setMasterVolume(double value) => setVolume(value);
  
  // Note control
  Future<void> playNote(int midiNote, double velocity) async {
    try {
      await _channel.invokeMethod('playNote', {
        'note': midiNote,
        'velocity': velocity,
      });
      playingValue = true;
      notifyListeners();
    } catch (e) {
      print('AudioEngine: Failed to play note: $e');
    }
  }
  
  Future<void> stopNote(int midiNote) async {
    try {
      await _channel.invokeMethod('stopNote', {
        'note': midiNote,
      });
    } catch (e) {
      print('AudioEngine: Failed to stop note: $e');
    }
  }
  
  Future<void> stopAllNotes() async {
    try {
      await _channel.invokeMethod('stopAllNotes');
      playingValue = false;
      notifyListeners();
    } catch (e) {
      print('AudioEngine: Failed to stop all notes: $e');
    }
  }
  
  // Legacy note methods for compatibility
  Future<void> noteOn(int midiNote, double velocity) => playNote(midiNote, velocity);
  Future<void> noteOff(int midiNote) => stopNote(midiNote);
  
  // Preset management
  Future<void> loadPreset(Map<String, dynamic> preset) async {
    try {
      await _channel.invokeMethod('loadPreset', preset);
      // Update local parameters
      cutoffValue = preset['cutoff']?.toDouble() ?? cutoffValue;
      resonanceValue = preset['resonance']?.toDouble() ?? resonanceValue;
      attackValue = preset['attack']?.toDouble() ?? attackValue;
      decayValue = preset['decay']?.toDouble() ?? decayValue;
      reverbValue = preset['reverb']?.toDouble() ?? reverbValue;
      volumeValue = preset['volume']?.toDouble() ?? volumeValue;
      notifyListeners();
    } catch (e) {
      print('AudioEngine: Failed to load preset: $e');
    }
  }
  
  Map<String, dynamic> getCurrentPreset() {
    return {
      'cutoff': cutoffValue,
      'resonance': resonanceValue,
      'attack': attackValue,
      'decay': decayValue,
      'reverb': reverbValue,
      'volume': volumeValue,
    };
  }
  
  // Audio analysis for visualizer
  Future<Map<String, dynamic>?> getAudioAnalysis() async {
    try {
      final result = await _channel.invokeMethod('getAudioAnalysis');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('AudioEngine: Failed to get audio analysis: $e');
      return null;
    }
  }
  
  // Legacy visualizer method for compatibility
  Map<String, dynamic> getVisualizerData() {
    return {
      'cutoff': cutoffValue,
      'resonance': resonanceValue,
      'attack': attackValue,
      'decay': decayValue,
      'reverb': reverbValue,
      'volume': volumeValue,
      'isPlaying': playingValue,
    };
  }
  
  // Instance initialize method for compatibility
  Future<bool> initializeInstance() async {
    await init();
    return initializedValue;
  }
  
  @override
  void dispose() {
    stopAllNotes();
    super.dispose();
  }
}