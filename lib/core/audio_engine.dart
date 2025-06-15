// Professional Audio Engine Interface for Flutter
// Connects to native C++ synthesis engine

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synther_app/services/midi_mapping_service.dart'; // For MidiMappingService and MidiCcMessage
import 'package:synther_app/ui/widgets/holographic_assignable_knob.dart'; // For SynthParameterType

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

  /// Processes a polyphonic aftertouch message for a specific MIDI note.
  ///
  /// [midiNote]: The MIDI note number (0-127).
  /// [aftertouchValue]: The normalized aftertouch value (0.0 - 1.0).
  /// This method currently prints the received values and attempts to invoke a
  /// 'polyAftertouch' method on the native method channel.
  Future<void> polyAftertouch(int midiNote, double aftertouchValue) async {
    // Placeholder for actual native call
    debugPrint('AudioEngine: PolyAftertouch Note $midiNote, Value $aftertouchValue');
    try {
      await _channel.invokeMethod('polyAftertouch', {
        'note': midiNote,
        'value': aftertouchValue.clamp(0.0, 1.0), // Ensure value is 0.0-1.0
      });
    } catch (e) {
      print('AudioEngine: Failed to send polyAftertouch: $e');
    }
    // No notifyListeners() here as this doesn't usually change a global param directly,
    // but rather affects a specific voice/note in the synth engine.
  }

  /// Processes an incoming MIDI CC message and updates mapped parameters.
  ///
  /// It uses the [MidiMappingService] to find if the incoming [MidiCcMessage]
  /// (based on its CC number and channel) is mapped to any [SynthParameterType].
  /// If a mapping exists, it normalizes the MIDI CC value (0-127) to a
  /// double (0.0-1.0) and then calls the appropriate parameter setter method
  /// in the AudioEngine, applying further specific scaling if needed (e.g., for cutoff).
  Future<void> processIncomingMidiCc(MidiCcMessage message) async {
    final identifier = MidiCcIdentifier(ccNumber: message.ccNumber, channel: message.channel);
    // Also check for "any channel" mapping
    final anyChannelIdentifier = MidiCcIdentifier(ccNumber: message.ccNumber, channel: -1);

    SynthParameterType? paramType = MidiMappingService.instance.getParameterForCc(identifier);
    if (paramType == null && identifier.channel != -1) {
      paramType = MidiMappingService.instance.getParameterForCc(anyChannelIdentifier);
    }

    if (paramType != null) {
      // Normalize MIDI value (0-127) to a double (0.0-1.0)
      // Some parameters might need specific scaling beyond 0-1, handled by individual setters.
      double normalizedValue = message.value / 127.0;

      debugPrint("AudioEngine: Processing MIDI CC ${message.ccNumber} for $paramType, value: ${message.value}, normalized: $normalizedValue");

      // Map SynthParameterType to the corresponding setter method
      // This requires knowledge of how each parameter should scale from the normalized MIDI value.
      switch (paramType) {
        case SynthParameterType.filterCutoff:
          // Example: setCutoff expects 20.0-20000.0.
          // If UI knobs (and thus MIDI learn values) are normalized 0-1, then this is fine.
          // The actual scaling (e.g. value * 20000) is handled in setCutoff if it expects a 0-1 value,
          // or here if setCutoff expects the absolute value. Assuming setters take absolute values for now.
          await setCutoff(normalizedValue * 20000); // Max 20000Hz
          break;
        case SynthParameterType.filterResonance:
          await setResonance(normalizedValue); // Assumes 0-1 range
          break;
        case SynthParameterType.attackTime:
          await setAttackTime(normalizedValue * 5.0); // Max 5s
          break;
        case SynthParameterType.decayTime:
          await setDecayTime(normalizedValue * 5.0); // Max 5s
          break;
        case SynthParameterType.reverbMix:
          await setReverbMix(normalizedValue); // Assumes 0-1 range
          break;
        case SynthParameterType.masterVolume: // Assuming SynthParameterType has masterVolume
           await setMasterVolume(normalizedValue); // Assumes 0-1 range
           break;
        // --- Cases for parameters that might not be directly in AudioEngine yet ---
        case SynthParameterType.oscLfoRate:
          // TODO: Implement setOscLfoRate or similar in AudioEngine
          // For now, just log it.
          debugPrint("AudioEngine: MIDI mapping for $paramType not yet fully implemented for direct setting.");
          // Example: await setOscLfoRate(normalizedValue * 20.0); // Max 20Hz
          break;
        case SynthParameterType.oscPulseWidth:
          // TODO: Implement setOscPulseWidth or similar in AudioEngine
          debugPrint("AudioEngine: MIDI mapping for $paramType not yet fully implemented for direct setting.");
          // Example: await setOscPulseWidth(normalizedValue);
          break;
        case SynthParameterType.delayFeedback:
          // TODO: Implement setDelayFeedback or similar in AudioEngine
          debugPrint("AudioEngine: MIDI mapping for $paramType not yet fully implemented for direct setting.");
          // Example: await setDelayFeedback(normalizedValue);
          break;
        default:
          debugPrint("AudioEngine: No specific MIDI action defined for $paramType");
      }
      // Note: notifyListeners() is called by the individual setX methods.
    }
  }
  
  @override
  void dispose() {
    stopAllNotes();
    super.dispose();
  }
}